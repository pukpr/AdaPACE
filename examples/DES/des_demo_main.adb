-- Demonstration of the Des generic procedure.
--
-- Des reads a simple simulation script from standard input and drives
-- one or more concurrent Rt task runners.  Each line of the script is
-- either a built-in timing / channel command or a user-defined key/value
-- pair that is dispatched to the Callback below.
--
-- Build:
--   gprbuild -P des_demo.gpr
--
-- Run (real-time, hangs after completion until Ctrl-C):
--   obj/des_demo_main < des_demo.run
--
-- Run (discrete-event simulation, exits cleanly with exact timestamps):
--   env PACE_SIM=1 PACE_NODE=0 obj/des_demo_main < des_demo.run
--
-- The benign "PACE-ERROR: FF_blank" startup message means no optional
-- PACE config file was found; it can be ignored for this example.
--
with Text_IO;
with Pace.Log;
with Des;

procedure Des_Demo_Main is

   -- Called for any key that Des does not recognise internally.
   -- Key  : first whitespace-separated token on the input line
   -- Value: second whitespace-separated token on the input line
   procedure My_Callback (Key, Value : in String) is
   begin
      Text_IO.Put_Line
        ("[callback] key='" & Key & "'  value='" & Value & "'");
   end My_Callback;

   procedure Run is new Des (My_Callback);

begin
   Run;
end Des_Demo_Main;
