#define RELIC_HTTP_CAP 294912
#define RELIC_HTTP_BODY_CAP 262144
U8 relic_net_error[128]="";

U8 *RelicNetError() { return relic_net_error; }

Bool RelicHTTPDecodeChunked(U8 *body,I64 len,I64 *out_len)
{
  I64 pos=0,dst=0,n,digits,ch;
  while (pos<len) {
    n=0; digits=0;
    while (pos<len && body[pos]!='\r') {
      ch=body[pos++];
      if (ch==';') {
        while (pos<len && body[pos]!='\r') pos++;
        break;
      }
      if (ch>='0' && ch<='9') ch-='0';
      else if (ch>='a' && ch<='f') ch=ch-'a'+10;
      else if (ch>='A' && ch<='F') ch=ch-'A'+10;
      else return FALSE;
      if (++digits>8 || n>RELIC_HTTP_BODY_CAP/16) return FALSE;
      n=n*16+ch;
    }
    if (!digits || pos+2>len || body[pos]!='\r' || body[pos+1]!='\n') return FALSE;
    pos+=2;
    if (!n) { body[dst]=0; *out_len=dst; return TRUE; }
    if (n>len-pos || dst+n>RELIC_HTTP_BODY_CAP) return FALSE;
    MemCpy(body+dst,body+pos,n); dst+=n; pos+=n;
    if (pos+2>len || body[pos]!='\r' || body[pos+1]!='\n') return FALSE;
    pos+=2;
  }
  return FALSE;
}

U8 *RelicHTTPOnce(U8 *url,I64 *size,U8 *redirect)
{
  U8 host[256],path[512],request[1024],*raw,*body,*p,*line,*next,*value;
  I64 i,n=0,port=80,got,total=0,header_len,status,content_len=-1;
  Bool chunked=FALSE,ok=FALSE,clean_eof=FALSE,compressed=FALSE;
  CTCPSock *sock=NULL;
  F64 deadline;
  *size=0; redirect[0]=0; StrCpy(relic_net_error,"Invalid host, port or HTTP address.");
  if (StrNCmp(url,"http://",7) || StrLen(url)>=512) {
    StrCpy(relic_net_error,"Only HTTP addresses under 512 characters are supported."); return NULL;
  }
  for (i=0;url[i];i++) if (url[i]<33 || url[i]>126) {
    StrCpy(relic_net_error,"Address contains spaces or control characters."); return NULL;
  }
  p=url+7;
  while (*p && *p!='/' && *p!=':' && *p!='?' && *p!='#' && n<255) host[n++]=*p++;
  host[n]=0;
  if (!n || n==255) return NULL;
  for (i=0;host[i];i++)
    if (!((host[i]>='a' && host[i]<='z') || (host[i]>='A' && host[i]<='Z') ||
          (host[i]>='0' && host[i]<='9') || host[i]=='.' || host[i]=='-')) return NULL;
  if (*p==':') {
    p++; port=0; n=0;
    while (*p>='0' && *p<='9' && n++<5) port=port*10+*p++-'0';
    if (!n || port<1 || port>65535) return NULL;
  }
  if (*p && *p!='/' && *p!='?' && *p!='#') return NULL;
  StrCpy(path,"/");
  if (*p=='/') StrCpy(path,p);
  else if (*p=='?') StrPrint(path,"/%s",p);
  p=StrFirstOcc(path,"#"); if (p) *p=0;
  if (!ipv4_globals.local_ip) { StrCpy(relic_net_error,"No IP address. Network configuration failed."); return NULL; }
  sock=TCPConnectionCreate(host,port);
  if (!sock) { StrCpy(relic_net_error,"DNS lookup or connection failed."); return NULL; }
  sock->timeout=3000;
  if (port==80) StrPrint(request,"GET %s HTTP/1.0\r\nHost: %s\r\nUser-Agent: RelicOS/0.5\r\nAccept: text/html,text/plain\r\nConnection: close\r\n\r\n",path,host);
  else StrPrint(request,"GET %s HTTP/1.0\r\nHost: %s:%d\r\nUser-Agent: RelicOS/0.5\r\nConnection: close\r\n\r\n",path,host,port);
  raw=CAlloc(RELIC_HTTP_CAP+1);
  if (TCPSockSendStr(sock,request)==StrLen(request)) {
    deadline=tS+15;
    while (total<RELIC_HTTP_CAP && tS<deadline) {
      got=TCPSockRx(sock,raw+total,MinI64(4096,RELIC_HTTP_CAP-total));
      if (!got) { clean_eof=TRUE; break; }
      if (got<0) break;
      total+=got;
    }
    raw[total]=0;
    body=StrMatch("\r\n\r\n",raw);
    if (body && body-raw<=32768 && total<RELIC_HTTP_CAP &&
        (!StrNCmp(raw,"HTTP/1.0 ",9) || !StrNCmp(raw,"HTTP/1.1 ",9))) {
      status=Str2I64(raw+9); header_len=body-raw+4;
      *body=0; body+=4;
      line=StrMatch("\r\n",raw);
      while (line && *line) {
        line+=2; next=StrMatch("\r\n",line);
        if (next) *next=0;
        if (!StrNICmp(line,"Transfer-Encoding:",18)) {
          if (StrIMatch("chunked",line+18)) chunked=TRUE;
        }
        if (!StrNICmp(line,"Content-Length:",15)) content_len=Str2I64(line+15);
        if (!StrNICmp(line,"Content-Encoding:",17) && !StrIMatch("identity",line+17)) compressed=TRUE;
        if (!StrNICmp(line,"Location:",9)) {
          value=line+9; while (*value==' ') value++;
          if (StrLen(value)<512) StrCpy(redirect,value);
        }
        if (next) { *next='\r'; line=next; } else line=NULL;
      }
      if (status>=200 && status<300 && !compressed) {
        n=total-header_len;
        if (chunked) ok=RelicHTTPDecodeChunked(body,n,&n);
        else ok=n<=RELIC_HTTP_BODY_CAP && ((content_len<0 && clean_eof) || content_len==n);
        if (ok) { MemCpy(raw,body,n); raw[n]=0; *size=n; }
      } else if (status<300 || status>=400) redirect[0]=0;
    }
  }
  sock->timeout=300; TCPSockClose(sock);
  if (ok) { relic_net_error[0]=0; return raw; }
  Free(raw);
  StrCpy(relic_net_error,"Response incomplete, compressed, too large, or HTTP error.");
  return NULL;
}

U8 *RelicHTTPGet(U8 *url,I64 *size)
{
  U8 current[512],redirect[512],base[512],*data;
  I64 i;
  if (StrLen(url)>=512) { StrCpy(relic_net_error,"Address exceeds 511 characters."); return NULL; }
  StrCpy(current,url);
  for (i=0;i<5;i++) {
    data=RelicHTTPOnce(current,size,redirect);
    if (data) return data;
    if (!redirect[0]) return NULL;
    if (!RelicURLResolve(current,redirect,base,sizeof(base))) {
      StrCpy(relic_net_error,"Redirect address is too long or invalid."); return NULL;
    }
    if (StrNCmp(base,"http://",7)) {
      StrCpy(relic_net_error,"Redirect needs an unsupported protocol (such as HTTPS)."); return NULL;
    }
    StrCpy(current,base);
  }
  StrCpy(relic_net_error,"Too many redirects."); return NULL;
}
