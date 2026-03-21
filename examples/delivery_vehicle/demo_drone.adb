with Pace.Command_Line;
with Pace.Log;
with Aho.Delivery_Handling_Coordinator;
with Eng.Test;
with Wmi;

with Uio.State_Manager;

procedure Demo_Drone is
   -- pragma Time_Slice (0.0); -- defeats DES (ddiscrete event simuulation
begin
   Wmi.Create (10, 500_000);
   Pace.Log.Agent_Id;

   --Pace.Log.Wait (4.0);

   Wmi.Call (Query => "eng.test.trigger_delivery_mission", Params => Pace.Command_Line.Argument ("-id", "1"));

exception
   when E: others =>
      Pace.Log.Ex (E);
end Demo_Drone;
