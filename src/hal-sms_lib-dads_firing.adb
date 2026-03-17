with Hal.Sms;
with Pace.Log;

package body Hal.Sms_Lib.Dads_Firing is

   use Hal;

   function Id is new Pace.Log.Unit_Id;

   task Agent is pragma Task_Name (Pace.Log.Name); end Agent;

   task body Agent is

   begin
      Pace.Log.Agent_Id (Id);

      Pace.Log.Wait (4.0);

      declare
         Msg : Rotate_Gun;
      begin
         Msg.Start := Orientation'(0.0, 0.0, Rads (0.0));
         Msg.Final := Orientation'(0.0, 0.0, Rads (30.0));
         Input (Msg);
      end;

      Pace.Log.Wait (2.0);
      Hal.Sms.Set ("Recoil", "Fire", 0.0);

      Pace.Log.Wait (4.0);
      declare
         Msg : Rotate_Gun;
      begin
         Msg.Start := Orientation'(0.0, 0.0, Rads (30.0));
         Msg.Final := Orientation'(0.0, 0.0, Rads (15.0));
         Input (Msg);
      end;

      Pace.Log.Wait (4.5);
      Hal.Sms.Set ("Recoil", "Fire", 0.0);

      Pace.Log.Wait (4.0);
      declare
         Msg : Rotate_Gun;
      begin
         Msg.Start := Orientation'(0.0, 0.0, Rads (15.0));
         Msg.Final := Orientation'(0.0, 0.0, Rads (-30.0));
         Input (Msg);
      end;

      Pace.Log.Wait (2.0);
      Hal.Sms.Set ("Recoil", "Fire", 0.0);

      Pace.Log.Wait (4.0);
      declare
         Msg : Rotate_Gun;
      begin
         Msg.Start := Orientation'(0.0, 0.0, Rads (-30.0));
         Msg.Final := Orientation'(0.0, 0.0, Rads (-15.0));
         Input (Msg);
      end;

      Pace.Log.Wait (2.0);
      Hal.Sms.Set ("Recoil", "Fire", 0.0);

      declare
         Msg : Rotate_Gun;
      begin
         Msg.Start := Orientation'(0.0, 0.0, Rads (-15.0));
         Msg.Final := Orientation'(0.0, 0.0, Rads (0.0));
         Input (Msg);
      end;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : Rotate_Gun) is
      Dummy : Boolean;
      End_Ori : Orientation := Obj.Final;
   begin
      Hal.Sms.Rotation ("gun_axis", Obj.Start, End_Ori, 1.0, Dummy);
   end Input;

end Hal.Sms_Lib.Dads_Firing;
