with Pace.Log;
with Pace.Server.Dispatch;
with Hal.Sms;

package body Hal.Sms_Lib.Timer is

   function Id is new Pace.Log.Unit_Id;

   task Agent is pragma Task_Name (Pace.Log.Name);
   end Agent;

   Counter : Integer := 1;
   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      Hal.Sms.Set ("clock_plate", "reset", 0.0);
      loop

         Pace.Log.Wait (1.0);
         Hal.Sms.Set ("sec-1", "turn_sec1", 0.0);

         if Counter mod 10 = 0 then
            Hal.Sms.Set ("sec-2", "turn_sec2", 0.0);
         end if;

         if Counter mod 60 = 0 then
            Hal.Sms.Set ("min-1", "turn_min1", 0.0);
         end if;

         if Counter mod 600 = 0 then
            Hal.Sms.Set ("min-2", "turn_min2", 0.0);
         end if;

         if Counter mod 3600 = 0 then
            Hal.Sms.Set ("hr-1", "turn_hr1", 0.0);
         end if;

         if Counter mod 36000 = 0 then
            Hal.Sms.Set ("hr-2", "turn_hr2", 0.0);
         end if;

         Counter := Counter + 1;


      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;


   use Pace.Server.Dispatch;
   type Reset is new Action with null record;
   procedure Inout (Obj : in out Reset);
   procedure Inout (Obj : in out Reset) is
   begin
      Counter := 0;
      Hal.Sms.Set ("clock_plate", "reset", 0.0);
   end Inout;

begin
   Save_Action (Reset'(Pace.Msg with Set => Default));
end Hal.Sms_Lib.Timer;
