with Pace;
with Pace.Log;
with Hal.Sms;

package body Aho.Box_Shuttle_Grippers is


   procedure Input (Obj : in Open_Box_Shuttle_Grippers) is
   begin
      Hal.Sms.Set ("BoxShuttleGrippers", "open", 0.3);
      Pace.Log.Trace (Obj);
   end Input;


   procedure Input (Obj : in Close_Box_Shuttle_Grippers) is
   begin
      Hal.Sms.Set ("BoxShuttleGrippers", "close", 0.3);
      Pace.Log.Trace (Obj);
   end Input;


end Aho.Box_Shuttle_Grippers;
