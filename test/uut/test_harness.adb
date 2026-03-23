
with Aunit.Test_Runner;

with Wmi;
with Pace.Log;
-- with Gnu.Env;

-- Suite for this level of tests:
with Common_Suite;

procedure Test_Harness is

   -- pragma Time_Slice (0.0);

   procedure Run is new Aunit.Test_Runner (Common_Suite);

begin
   Wmi.Create (10, 50_000);
   Pace.Log.Agent_Id;
   Run;
   Pace.Log.Os_Exit(0);
exception
   when E: others =>
      Pace.Log.Ex (E);
end Test_Harness;


