with Gkb;
with Pace;

--  Weather Knowledge Base (WKB)
--
--  Generic GKB instantiation for NWS weather observation data.
--  The Prolog file is located at $PACE/kbase/weather.pro and is found
--  at run-time via Pace.Config.Find_File using the PACE environment
--  variable (e.g. PACE=../.. when run from examples/weather/).
--
--  Override the file path at run-time with: WKB_FILE=/path/to/weather.pro
package Wkb is new Gkb
  (Task_Stack_Size  => 50_000,
   Prolog_File      => Pace.Getenv ("WKB_FILE", "/kbase/weather.pro"),
   Allocation_Data  => (Clause   => 1500,
                        Hash     => 507,
                        In_Toks  => 500,
                        Out_Toks => 1000,
                        Frames   => 4000,
                        Goals    => 6000,
                        Subgoals => 320,
                        Trail    => 5000,
                        Control  => 700));
