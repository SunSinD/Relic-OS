// Requires successful Net/Load.HC and a completed RelicSelfTest.HC run.
U0 RelicNetTest()
{
  U8 chunk[64];
  U8 bad[64];
  U8 dns_cycle[2];
  U8 valid[6];
  U8 *p;
  I64 n=0,left;
  U32 ip;
  Bool decoded;
  CDNSDomainName name;
  StrCpy(chunk,"4\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\n");
  StrCpy(bad,"FFFFFFFFF\r\nx\r\n");
  dns_cycle[0]=0xC0; dns_cycle[1]=0;
  valid[0]=4; StrCpy(valid+1,"test");
  decoded=RelicHTTPDecodeChunked(chunk,StrLen(chunk),&n);
  RelicCheck(decoded && n==9 && !StrCmp(chunk,"Wikipedia"),"HTTP chunk decoding");
  RelicCheck(!RelicHTTPDecodeChunked(bad,StrLen(bad),&n),"reject oversized HTTP chunk");
  RelicCheck(IPV4AddrPrs("192.168.1.2",&ip) && ip==0xC0A80102,"IPv4 address parse");
  RelicCheck(!IPV4AddrPrs("1.2.3",&ip) && !IPV4AddrPrs("256.1.2.3",&ip) &&
    !IPV4AddrPrs("1.2.3.4.",&ip),"reject malformed IPv4");
  p=dns_cycle; left=2;
  RelicCheck(DNSDomainNamePrs(dns_cycle,2,&p,&left,&name)<0,"reject cyclic DNS pointer");
  p=valid; left=6;
  RelicCheck(!DNSDomainNamePrs(valid,6,&p,&left,&name) && left==0 &&
    name.num_labels==1 && !StrCmp(name.labels[0],"test"),"DNS label parse");
  if (name.labels) { Free(name.labels[0]); Free(name.labels); }
  CatPrint(relic_test_report,"NETWORK RESULT %d passed, %d failed\n",relic_test_pass,relic_test_fail);
  U8 report_path[64];
  StrPrint(report_path,"%c:/SELFTEST.TXT",relic_dev_drv);
  if (relic_dev_drv) FileWrite(report_path,relic_test_report,StrLen(relic_test_report));
  "%s",relic_test_report;
}
RelicNetTest;
