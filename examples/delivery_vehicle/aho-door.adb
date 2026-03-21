with Pace;
with Pace.Log;
with Pace.Surrogates;
with Hal;
with Hal.Sms;
with Ada.Numerics;
with Pace.Surrogates;

package body Aho.Door is

   Current_Orn : Hal.Orientation := (0.0, 0.0, 0.0);
   Spin_Rate : constant Float := Hal.Rads (300.0);

   type Rotate_Door_Timed is new Pace.Msg with
      record
         Wait_Time : Duration;
      end record;
   procedure Input (Obj : Rotate_Door_Timed);
   procedure Input (Obj : Rotate_Door_Timed) is
   begin
      Pace.Log.Wait (Obj.Wait_Time);
      Pace.Log.Trace (Obj);
   end Input;

   type Swing_Door is new Pace.Msg with
      record
         Wait_Time : Duration;
      end record;
   procedure Input (Obj : Swing_Door);
   procedure Input (Obj : Swing_Door) is
   begin
      Pace.Log.Wait (Obj.Wait_Time);
      Pace.Log.Trace (Obj);
   end Input;

   type Chamber_Air_Spray is new Pace.Msg with null record;
   procedure Input (Obj : Chamber_Air_Spray);
   procedure Input (Obj : Chamber_Air_Spray) is
   begin
      Pace.Log.Wait (0.7);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Open_Door_Door) is
   begin
--  declare
--    Msg : Rotate_Door;
--  begin
--    Msg.Axis := 'X';
--    Msg.Speed := Spin_Rate;
--    Msg.Final := (-240.0, 0.0, 0.0);
--    Pace.Dispatching.Input (Msg);
--  end;
      Hal.Sms.Set ("door_door_axis", "open", -0.7);
      declare
         Msg : Rotate_Door_Timed;
      begin
         Msg.Wait_Time := 0.2;
         Input (Msg);
      end;
          declare
            Msg : Chamber_Air_Spray;
          begin
            Pace.Surrogates.Input (Msg);
          end;
      declare
         Msg : Rotate_Done;
      begin
         -- don't block!
         Msg.Ack := False;
         Input (Msg);
      end;
      declare
         Msg : Swing_Door;
      begin
         Msg.Wait_Time := 0.5;
         Input (Msg);
      end;
   end Input;

   procedure Input (Obj : in Close_Door_Door) is
   begin
--  declare
--    Msg : Rotate_Door;
--  begin
--    Msg.Axis := 'X';
--    Msg.Speed := Spin_Rate;
--    Msg.Final := (0.0, 0.0, 0.0);
--    Pace.Dispatching.Input (Msg);
--  end;
      Hal.Sms.Set ("door_door_axis", "close", -0.9);
      declare
         Msg : Swing_Door;
      begin
         Msg.Wait_Time := 0.7;
         Input (Msg);
      end;
      declare
         Msg : Rotate_Door_Timed;
      begin
         Msg.Wait_Time := 0.2;
         Input (Msg);
      end;
   end Input;

   procedure Input (Obj : in Rotate_Door) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation;
      Rate : Hal.Rate;
   begin
      if Obj.Axis = 'X' or else Obj.Axis = 'x' then
         End_Orn := (Hal.Rads (Obj.Final.A), 0.0, 0.0);
         Rate.Units := Obj.Speed;
         Hal.Sms.Rotation ("door_axis_top",
                           (Hal.Rads (Current_Orn.A), 0.0, 0.0), End_Orn, Rate,
                           Stopped, 0.0, 0.0);
         Current_Orn.A := Obj.Final.A;
      end if;
      Pace.Log.Trace (Obj);
   end Input;

end Aho.Door;
