// HelloRelicOS.HC
// ================
// This is the first Relic OS source file.
// It proves that Relic OS exists as a separate fork by printing a greeting
// that is NOT the default TempleOS startup text.
//
// HOW TO RUN THIS INSIDE YOUR VM:
//   1. Boot your TempleOS VM.
//   2. At the shell prompt, type exactly:
//        #include "D:/HelloRelicOS.HC";
//      (adjust the drive letter to wherever you put this file)
//   3. You should see the Relic OS greeting printed.
//
// This file does NOT modify TempleOS. It is a standalone script.
// Once you have host-side tooling, you can include this in StartOS.HC.Z
// to make it run on every boot.

U0 HelloRelicOS()
{
  // Print a visible separator
  "========================================\n";

  // Print the Relic OS greeting in bold (use $FG,CYAN$...$FG$ for color)
  "$FG,CYAN$";
  "  Welcome to Relic OS\n";
  "$FG$";

  // Print version info
  "  Built from TempleOS V5.03 baseline\n";
  "  This is not TempleOS. This is Relic OS.\n";

  // Print a blank line then separator
  "\n";
  "========================================\n";
}

// Call the function immediately when this file is included
HelloRelicOS;
