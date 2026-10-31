Cd(__DIR__);;
CTask *netfifo_handler_task=NULL;
Bool net_log_log=FALSE,net_log_warn=FALSE,net_log_dbg=FALSE;
U0 NetLog(U8 *fmt,...) { no_warn fmt,argc,argv; }
U0 NetWarn(U8 *fmt,...) { no_warn fmt,argc,argv; }
U0 NetDbg(U8 *fmt,...) { no_warn fmt,argc,argv; }
U8 relic_net_trace[4096]="";
U0 NetErr(U8 *fmt,...)
{
  no_warn argc,argv;
  if (StrLen(relic_net_trace)+StrLen(fmt)+2<sizeof(relic_net_trace))
    CatPrint(relic_net_trace,"%s\n",fmt);
}
class CPciDevInfo { I64 bus,dev,fun; U32 bar[6]; };
CPciDevInfo net_driver_pci;
Bool RelicPCNetFind()
{
  I64 b,d,f,i;
  for (b=0;b<256;b++) for (d=0;d<32;d++) {
    if (PCIReadU16(b,d,0,0)!=0xFFFF) for (f=0;f<8;f++) {
      if (PCIReadU32(b,d,f,0)==0x20001022) {
        net_driver_pci.bus=b; net_driver_pci.dev=d; net_driver_pci.fun=f;
        for (i=0;i<6;i++) net_driver_pci.bar[i]=PCIReadU32(b,d,f,0x10+i*4);
        return TRUE;
      }
    }
  }
  return FALSE;
}
if (!RelicPCNetFind) throw('NoPCNet');
#include "Utilities/Net.HH"
#include "Utilities/NetQueue.HC"
#include "Drivers/PCNet.HC"
#include "Protocols/Ethernet.HC"
#include "Protocols/ARP.HC"
#include "Protocols/IPV4.HC"
#include "Protocols/ICMP.HC"
#include "Protocols/Sockets.HC"
#include "Utilities/BST.HC"
#include "Protocols/UDP/MakeUDP.HC"
#include "Protocols/DNS.HC"
#include "Utilities/Ping.HC"
#include "Protocols/TCP/MakeTCP.HC"
#include "Protocols/DHCP.HC"
#include "Utilities/NetHandler.HC"
#include "HTTP.HC"
Spawn(&NetCfg,NULL,"DHCP");
Cd("::/Home");;
