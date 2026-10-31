// Resolve bounded HTTP or file references; servers/FS resolve dot segments.
Bool RelicURLResolve(U8 *base,U8 *ref,U8 *out,I64 cap)
{
  U8 clean[512],result[1024],*p,*last;
  I64 start;
  if (StrLen(base)>=sizeof(clean) || StrLen(ref)>=512) return FALSE;
  if (StrMatch(":",ref)) {
    if (StrLen(ref)>=cap) return FALSE;
    StrCpy(out,ref); return TRUE;
  }
  StrCpy(clean,base);
  p=StrFirstOcc(clean,"#"); if (p) *p=0;
  if (ref[0]=='#') StrPrint(result,"%s%s",clean,ref);
  else {
    p=StrFirstOcc(clean,"?"); if (p) *p=0;
    if (ref[0]=='?') StrPrint(result,"%s%s",clean,ref);
    else {
      start=0;
      if (!StrNCmp(clean,"http://",7)) start=7;
      else if (!StrNCmp(clean,"file:",5)) start=5;
      else return FALSE;
      if (ref[0]=='/' && ref[1]=='/' && start==7)
        StrPrint(result,"http:%s",ref);
      else if (ref[0]=='/') {
        p=StrFirstOcc(clean+start,"/"); if (p) *p=0;
        StrPrint(result,"%s%s",clean,ref);
      } else {
        last=StrLastOcc(clean+start,"/");
        if (last) { last[1]=0; StrPrint(result,"%s%s",clean,ref); }
        else StrPrint(result,"%s/%s",clean,ref);
      }
    }
  }
  if (StrLen(result)>=cap) return FALSE;
  StrCpy(out,result); return TRUE;
}
