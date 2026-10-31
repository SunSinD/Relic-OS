// Call RelicHTTPTest with the Windows VMware adapter HTTP fixture address.
U0 RelicHTTPCase(U8 *base,U8 *path,Bool expected,U8 *name,U8 *body=NULL)
{
  U8 url[512],*data;
  I64 size;
  StrPrint(url,"%s%s",base,path);
  data=RelicHTTPGet(url,&size);
  Bool ok=(data!=NULL)==expected;
  if (ok && data && body) ok=!StrCmp(data,body);
  RelicCheck(ok,name);
  if (!ok) CatPrint(relic_test_report,"DETAIL %s\n",RelicNetError);
  Free(data);
}
U0 RelicHTTPTest(U8 *base)
{
  U8 probe_url[512],*probe; I64 probe_size;
  StrPrint(probe_url,"%s/ok",base);
  probe=RelicHTTPGet(probe_url,&probe_size);
  if (!probe) { "HTTP fixtures unreachable: %s\n",RelicNetError; return; }
  Free(probe);
  RelicHTTPCase(base,"/ok",TRUE,"HTTP content length");
  RelicHTTPCase(base,"/chunked",TRUE,"HTTP chunked transfer","Wikipedia");
  RelicHTTPCase(base,"/redirect",TRUE,"HTTP relative redirect");
  RelicHTTPCase(base,"/truncated",FALSE,"reject truncated HTTP content length");
  RelicHTTPCase(base,"/badchunk",FALSE,"reject malformed HTTP chunk");
  RelicHTTPCase(base,"/compressed",FALSE,"reject compressed HTTP response");
  RelicHTTPCase(base,"/stall",FALSE,"reject stalled HTTP without content length");
  CatPrint(relic_test_report,"HTTP RESULT %d passed, %d failed\n",relic_test_pass,relic_test_fail);
  U8 report_path[64];
  StrPrint(report_path,"%c:/SELFTEST.TXT",relic_dev_drv);
  if (relic_dev_drv) FileWrite(report_path,relic_test_report,StrLen(relic_test_report));
  "%s",relic_test_report;
}
