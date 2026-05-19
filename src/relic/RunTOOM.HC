// Mount and Run TOOM automatically
U0 RunTOOM() {
  "\n$FG,CYAN$Mounting TOOM...$FG$\n";
  In("m\nm\n::/Home/RelicOS/TOOM.ISO.C\n\n\n");
  Mount;
  Cd("M:/");
  #include "Load.HC";
}
RunTOOM;
