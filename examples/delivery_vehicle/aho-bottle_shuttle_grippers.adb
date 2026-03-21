with Pace;
with Pace.Log;
with Hal.Sms;

package body Aho.Bottle_Shuttle_Grippers is


   procedure Input (Obj : in Open_Bottle_Shuttle_Grippers) is
   begin
      Hal.Sms.Set ("BottleShuttleGrippers", "open", 0.3);
      Pace.Log.Trace (Obj);
   end Input;


   procedure Input (Obj : in Close_Bottle_Shuttle_Grippers) is
   begin
      Hal.Sms.Set ("BottleShuttleGrippers", "close", 0.3);
      Pace.Log.Trace (Obj);
   end Input;

-- $id: aho-bottle_shuttle_grippers.adb,v 1.2 12/22/2003 14:17:53 ludwiglj Exp $
end Aho.Bottle_Shuttle_Grippers;
