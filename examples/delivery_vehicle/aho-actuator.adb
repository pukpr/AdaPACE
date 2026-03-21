with Pace;
with Pace.Log;
with Pace.Surrogates;
with Hal;
with Hal.Sms;
with Hal.Audio.Mixer;
with Ada.Numerics;
with Ada.Strings.Unbounded;

with Pace.Server.dispatch;

package body Aho.Actuator is

   Actuator_Standoff : Hal.Orientation := (0.0, 0.0, 0.0);
   Actuator_Standoff_Pos : Hal.Position := (0.0, 0.0, 0.0);

   Actuator_Pos : Hal.Position := Actuator_Standoff_Pos;
   Bottle_Pos : Hal.Position := (0.0, 0.0, 0.0);
   Box_Pos : Hal.Position := (0.0, 0.0, 0.0);
   Actuator_Orn : Hal.Orientation := Actuator_Standoff;
   Spin_Rate : constant Float := Hal.Rads (300.0);


   type Rotate_Actuator is new Pace.Msg with
      record
         Final : Hal.Orientation;
         Actuator_Flag : Boolean;
         Assembly : Ada.Strings.Unbounded.Unbounded_String;
         Speed : Float;
      end record;
   procedure Input (Obj : in Rotate_Actuator);

   type Translate_Actuator is new Pace.Msg with
      record
         Final : Hal.Position;
         Assembly : Ada.Strings.Unbounded.Unbounded_String;
         Total_Time : Duration;
         Ramp_Up : Duration;
         Ramp_Down : Duration;
      end record;
   procedure Input (Obj : in Translate_Actuator);

   type Load_Inventory is new Pace.Msg with
      record
         Final : Hal.Position;
         Assembly : Ada.Strings.Unbounded.Unbounded_String;
         Total_Time : Duration;
         Ramp_Up : Duration;
         Ramp_Down : Duration;
      end record;
   procedure Input (Obj : in Load_Inventory);

   procedure Input (Obj : in Place_Box) is
      Audio_Msg : Hal.Audio.Mixer.Play_Mix := Make_Audio ("actuator");
   begin
      declare
         Msg : Load_Inventory;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := (0.0, 0.0, 1.8);
         Msg.Assembly := Ada.Strings.Unbounded.To_Unbounded_String
                           ("LoadArmBox");
         Msg.Ramp_Up := 0.4259;
         Msg.Ramp_Down := 0.1118;
         Pace.Surrogates.Input (Msg);
      end;
      declare
         Msg : Translate_Actuator;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := (0.0, 0.0, 1.8);
         Msg.Assembly :=
           Ada.Strings.Unbounded.To_Unbounded_String ("axis_pawl");
         Msg.Ramp_Up := 0.4259;
         Msg.Ramp_Down := 0.1118;

         -- starting sound
         Pace.Dispatching.Inout (Audio_Msg);

         Pace.Dispatching.Input (Msg);

         -- stopping sound
         Pace.Dispatching.Inout (Audio_Msg);
      end;

      Pace.Log.Trace (Obj);
   end Input;

   type Extend_Bottle_Retainer is new Pace.Msg with null record;
   procedure Input (Obj : Extend_Bottle_Retainer);
   procedure Input (Obj : Extend_Bottle_Retainer) is
   begin
      Pace.Log.Wait (0.25);  -- replace with actual movement..
      Pace.Log.Trace (Obj);
   end Input;

   type Wait_And_Extend_Bottle_Retainer is new Pace.Msg with null record;
   procedure Input (Obj : Wait_And_Extend_Bottle_Retainer);
   procedure Input (Obj : Wait_And_Extend_Bottle_Retainer) is
   begin
      Pace.Log.Wait (0.25);
      declare
         Msg : Extend_Bottle_Retainer;
      begin
         Input (Msg);
      end;
   end Input;

   procedure Input (Obj : in Retract_Bottle_Retainer) is
   begin
      Pace.Log.Wait (0.1);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Place_Bottle) is
      Audio_Msg : Hal.Audio.Mixer.Play_Mix := Make_Audio ("actuator");
   begin


      declare
         Msg : Translate_Actuator;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := (0.0, 0.0, 0.32);
         Msg.Assembly :=
           Ada.Strings.Unbounded.To_Unbounded_String ("axis_pawl");
         Msg.Ramp_Up := 0.4259;
         Msg.Ramp_Down := 0.0;
         -- starting sound
         Pace.Dispatching.Inout (Audio_Msg);

         Pace.Dispatching.Input (Msg);

         -- stopping sound
         Pace.Dispatching.Inout (Audio_Msg);
      end;

      Hal.Sms.Set ("RamBottle", "on", 0.0);
      Hal.Sms.Set ("LoadArmBottle", "off", 0.0);
      Hal.Sms.Set ("LoadArmBottle", "resetBottle", 0.0);


      declare
         Msg : Load_Inventory;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := (0.0, 0.0, 1.4);
--          Msg.Assembly := Ada.Strings.Unbounded.To_Unbounded_String
--                            ("LoadArmBottle");
         Msg.Assembly := Ada.Strings.Unbounded.To_Unbounded_String
                           ("RamBottle");
         Msg.Ramp_Up := 0.4259;
         Msg.Ramp_Down := 0.1118;
         Pace.Surrogates.Input (Msg);
      end;

      declare
         Msg : Wait_And_Extend_Bottle_Retainer;
      begin
         Pace.Surrogates.Input (Msg);
      end;

      declare
         Msg : Translate_Actuator;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := (0.0, 0.0, 1.4);
         Msg.Assembly :=
           Ada.Strings.Unbounded.To_Unbounded_String ("axis_pawl");
         Msg.Ramp_Up := 0.4259;
         Msg.Ramp_Down := 0.1118;

         -- starting sound
         Pace.Dispatching.Inout (Audio_Msg);

         Pace.Dispatching.Input (Msg);

         -- stopping sound
         Pace.Dispatching.Inout (Audio_Msg);
      end;

      Pace.Log.Trace (Obj);
   end Input;

   procedure Reset_Bottle is
   begin
      -- Visual Call to reset Bottle
--       Hal.Sms.Set ("LoadArmBottle", "off", 0.0);
--       Hal.Sms.Set ("LoadArmBottle", "resetBottle", 0.0);
       Hal.Sms.Set ("RamBottle", "off", 0.0);
       Hal.Sms.Set ("RamBottle", "resetBottle", 0.0);
   end Reset_Bottle;

   procedure Reset_Box is
   begin
      Hal.Sms.Set ("LoadArmBox", "off", 0.0);
      Hal.Sms.Set ("LoadArmBox", "resetBox", 0.0);
   end Reset_Box;



   type Check_Retract is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Check_Retract);
   procedure Inout (Obj : in out Check_Retract) is
      Msg : Retract_Actuator;
   begin
      Msg.Unloaded := True;
      Pace.Dispatching.Input (Msg);
   end;

   procedure Input (Obj : Retract_Actuator) is
      Audio_Msg : Hal.Audio.Mixer.Play_Mix := Make_Audio ("actuator_retract");
   begin
      declare
         Msg : Translate_Actuator;
      begin
         if Obj.Unloaded then
            Msg.Total_Time := 0.5;
         else
            Msg.Total_Time := 0.7;
         end if;
         Msg.Final := Actuator_Standoff_Pos;
         Msg.Assembly :=
           Ada.Strings.Unbounded.To_Unbounded_String ("axis_pawl");
         Msg.Ramp_Up := 0.1166;
         Msg.Ramp_Down := 0.1166;

         -- starting sound
         Pace.Dispatching.Inout (Audio_Msg);

         Input (Msg);

         -- stopping sound
         Pace.Dispatching.Inout (Audio_Msg);

      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Rotate_Actuator) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation;
      Rate : Hal.Rate;
   begin
      End_Orn := (Hal.Rads (Obj.Final.A), 0.0, Hal.Rads (Obj.Final.C));
      Rate.Units := Obj.Speed;
      if Obj.Actuator_Flag then
         Hal.Sms.Rotation (Ada.Strings.Unbounded.To_String (Obj.Assembly),
                           (Hal.Rads (Actuator_Orn.A), 0.0, 0.0),
                           End_Orn, Rate, Stopped, 0.0, 0.0);

         Actuator_Orn.A := Obj.Final.A;
      end if;
   end Input;

   procedure Input (Obj : in Translate_Actuator) is
      Stopped : Boolean;
      End_Pos : Hal.Position;
   begin
      End_Pos := (0.0, 0.0, Obj.Final.Z);
      Hal.Sms.Translation (Ada.Strings.Unbounded.To_String (Obj.Assembly),
                           (0.0, 0.0, Actuator_Pos.Z), End_Pos, Obj.Total_Time,
                           Stopped, Obj.Ramp_Up, Obj.Ramp_Down);
      Actuator_Pos.Z := End_Pos.Z;
   end Input;

   procedure Input (Obj : in Load_Inventory) is
      Stopped : Boolean;
      End_Pos : Hal.Position := Obj.Final;
   begin
      if Ada.Strings.Unbounded.To_String (Obj.Assembly) = "LoadArmBottle" then
         Hal.Sms.Translation (Ada.Strings.Unbounded.To_String (Obj.Assembly),
                              Bottle_Pos, End_Pos, Obj.Total_Time,
                              Stopped, Obj.Ramp_Up, Obj.Ramp_Down);
      else
         Hal.Sms.Translation (Ada.Strings.Unbounded.To_String (Obj.Assembly),
                              Box_Pos, End_Pos, Obj.Total_Time,
                              Stopped, Obj.Ramp_Up, Obj.Ramp_Down);
      end if;
   end Input;


   use Pace.Server.Dispatch;
begin
   Save_Action (Check_Retract'(Pace.Msg with Set => Default));
end Aho.Actuator;
