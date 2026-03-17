with Pace.Ports;
with Pace.Tcp.Http;
with Pace.Log;
with Hal.Joystick.Dispatcher;
with Gkb.Database;
with Hal.Sms;
with Ada.Numerics;
with Pace.Strings;

separate (Mob.Vehicle)
package body Joystick is

   function Id is new Pace.Log.Unit_Id;
   function Name return String renames Pace.Log.Name;

   This_Node : constant Pace.Node_Slot := Pace.Getenv ("PACE_NODE", 0);

   type Str is access String;

   Is_On : Boolean := False;
   Unique_Id : Integer := 0;

   X_View_Offset : Float;
   Y_View_Offset : Float;
   Z_View_Offset : Float;

   package Db is new Kb.Database;

   -- these are configurable via the kbase
   Steering_Axis : Integer := 0;
   Throttle_Axis : Integer := 1;

   Inactive_Button : constant := -1;

   -- initialized to inactive... kbase will override if the button is active
   Reverse_button : Integer := Inactive_Button;
   Neutral_button : Integer := Inactive_Button;
   Forward_button : Integer := Inactive_Button;
   Pivot_Button : Integer := Inactive_Button;

   -- Bump switch 4 quadrants
   Look_Forward_button : Integer := Inactive_Button;
   Look_Backward_button : Integer := Inactive_Button;
   Look_Left_button : Integer := Inactive_Button;
   Look_Right_Button : Integer := Inactive_Button;

   Parking_Brake_Button : Integer := Inactive_Button;
   Parking_Brake : Boolean := False;

   type Aux_Button is
      record
         Number : Integer := Inactive_Button;
         Name : Str;
      end record;
   Aux_Buttons : array (1..8) of Aux_Button;

   Min_Throttle : constant := 0.1;

   procedure Act (Data : Hal.Joystick.Joy_Data) is
      Steer_Value : Float;
      Throttle_Value : Float;

      function Is_Button_On (Button : Integer) return Boolean is
      begin
         return Button /= Inactive_Button and then Data.Buttons (Button);
      end Is_Button_On;

      function Is_Button_Pos (Button : Integer) return Boolean is
      begin
         return Button /= Inactive_Button and then Data.Axes (Button) > 0.01;  -- Not zero in case of noise
      end Is_Button_Pos;

      function Is_Button_Neg (Button : Integer) return Boolean is
      begin
         return Button /= Inactive_Button and then Data.Axes (Button) < -0.01;  -- Not zero in case of noise
      end Is_Button_Neg;

      procedure Change_View (Rotation : in Float) is
         Rot : Hal.Orientation;
         Pos : Hal.Position;
      begin
         Rot := (0.0, Rotation, 0.0);
         Pos := (X_View_Offset, Y_View_Offset, Z_View_Offset);
         Hal.Sms.Set ("secondary_azimuth", Pos, Rot);
      end Change_View;

      procedure Command (Cmd : String) is
      begin
         Pace.Log.Put_Line ( "Joystick triggered " & Cmd &
          Pace.Tcp.Http.Get
             (Host => "localhost",
              Port =>  Pace.Ports.Unique_Port (Pace.Ports.Web, This_Node),
              Item => Cmd)
         );
      end Command;

   begin

      -- gear changing
      declare
         Msg : Transmission_Control;
         Change_Gear : Boolean := True;
      begin
         if Is_Button_On (Reverse_Button) then
            Pace.Log.Put_Line ("Joystick Reverse Gear");
            Msg.Mode := Rev;
         elsif Is_Button_On (Neutral_Button) then
            Pace.Log.Put_Line ("Joystick Neutral Gear");
            Msg.Mode := Neutral;
         elsif Is_Button_On (Forward_Button) then
            Pace.Log.Put_Line ("Joystick Forward Gear");
            Msg.Mode := Forward;
         elsif Is_Button_On (Pivot_Button) then
            Pace.Log.Put_Line ("Joystick Pivot Gear");
            Msg.Mode := Pivot;
         else
            Change_Gear := False;
         end if;
         if Change_Gear then
            Pace.Dispatching.Input (Msg);
         end if;
      end;

      -- mode switching, etc for auxiliary commands
      for I in Aux_Buttons'Range loop
         if Is_Button_On (Aux_Buttons(I).Number) then
            Command (Aux_Buttons(I).Name.all);
         end if;
      end loop;

      -- steer
      Steer_Value := Data.Axes (Steering_Axis);
      declare
         Msg : Steering_Control;
      begin
         if Steer_Value in Mob.Steering_Range then
            Msg.Rate := Steer_Value;
            Pace.Dispatching.Input (Msg);
         else
            Pace.Log.Put_Line ("Joystick steering out of range " & Float'Image (Steer_Value));
         end if;
      end;

      -- throttle
      Throttle_Value := Data.Axes (Throttle_Axis);
      if abs (Throttle_Value) > Min_Throttle then
         declare
            Msg : Accelerator_Control;
         begin
            if Throttle_Value in Mob.Acceleration_Range then
               Msg.Rate := -Throttle_Value;
               Pace.Dispatching.Input (Msg);
            else
               Pace.Log.Put_Line ("Joystick acceleration out of range " & Float'Image (-Throttle_Value));
            end if;
         end;
      end if;

      -- OTW view perspective changing
      if Is_Button_On (Look_Forward_Button) then
         Current_View := Look_Forward;
         Pace.Log.Put_Line ("Joystick Look Forward");
         Change_View (0.0);
      elsif Is_Button_On (Look_Backward_Button) then
         Current_View := Look_Backward;
         Pace.Log.Put_Line ("Joystick Look Backward");
         Change_View (Ada.Numerics.Pi);
      elsif Is_Button_On (Look_Left_Button) then
         Current_View := Look_Left;
         Pace.Log.Put_Line ("Joystick Look Left");
         Change_View (Ada.Numerics.Pi/2.0);
      elsif Is_Button_On (Look_Right_Button) then
         Current_View := Look_Right;
         Pace.Log.Put_Line ("Joystick Look Right");
         Change_View (-Ada.Numerics.Pi/2.0);
      end if;

      if Is_Button_On (Parking_Brake_Button) then
         declare
            Msg : Park_Brake_Control;
         begin
            Parking_Brake := not Parking_Brake;
            Pace.Log.Put_Line ("Joystick Parking Brake set to " & Boolean'Image(Parking_Brake));
            Msg.Brake_Control := Parking_Brake;
            Pace.Dispatching.Input (Msg);
         end;
      end if;

   end Act;

   task Agent is pragma Task_Name (Name);
      entry Go;
   end Agent;

   task body Agent is

   begin
      Pace.Log.Agent_Id (Id);

      loop
         accept Go;

         while Is_On loop
            declare
               Msg : Hal.Joystick.Dispatcher.Data_Update;
            begin
               Pace.Dispatching.Inout (Msg);
               if Msg.Joy_Id = Unique_Id then
                  Act (Msg.Data);
               end if;
            end;
         end loop;

      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure On (Joy_Id : Integer) is
   begin
      Is_On := True;
      Unique_Id := Joy_Id;
      Agent.Go;
   end On;

   procedure Off is
   begin
      Is_On := False;
      -- clear out the notify above so it can stop
      declare
         Msg : Hal.Joystick.Dispatcher.Data_Update;
      begin
         Msg.Joy_Id := -1;  -- -1 so nothing will act on it
         Msg.Ack := False;
         Pace.Dispatching.Input (Msg);
      end;
   end Off;

   procedure Set_Unique_Id (Id : Integer) is
   begin
      Unique_Id := Id;
   end Set_Unique_Id;

   function Get_Unique_Id return Integer is
   begin
      return Unique_Id;
   end Get_Unique_Id;

begin
   Steering_Axis := Db.Get ("driving_steering");
   Throttle_Axis := Db.Get ("driving_throttle");
   Look_Forward_button := Db.Get ("driving_view_forward");
   Look_Backward_button := Db.Get ("driving_view_backward");
   Look_Left_button := Db.Get ("driving_view_left");
   Look_Right_Button := Db.Get ("driving_view_right");
   -- this errors out if not found
   Reverse_Button := Db.Get ("driving_reverse");
   Neutral_Button := Db.Get ("driving_neutral");
   Forward_Button := Db.Get ("driving_forward");
   Pivot_Button := Db.Get ("driving_pivot");
   Parking_Brake_Button := Db.Get ("driving_parking_brake");
   X_View_Offset := Db.Get ("x_view_offset");
   Y_View_Offset := Db.Get ("y_view_offset");
   Z_View_Offset := Db.Get ("z_view_offset");

   for I in Aux_Buttons'Range loop
      Aux_Buttons(I).Number := Db.Get ("aux_" & Pace.Strings.Trim(I));
      Aux_Buttons(I).Name := new String'(Db.Get ("aux_" & Pace.Strings.Trim(I), "name"));
   end loop;

exception
   when E : Kb.Rules.No_Match =>
      null;
   when E : others =>
      Pace.Log.Ex (E);
end Joystick;
