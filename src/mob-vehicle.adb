with Pace;
with Pace.Log;
with Pace.Signals;
with Ada.Numerics;

package body Mob.Vehicle is

   Current_View : Camera_View := Look_Forward;

   package Joystick is
      -- waits on incoming joystick data and send it on when appropriate

      -- tells the internal task to begin looking for data from joy_id
      procedure On (Joy_Id : Integer);
      -- turns off internal task
      procedure Off;
      procedure Set_Unique_Id (Id : Integer);
      function Get_Unique_Id return Integer;
   end Joystick;
   package body Joystick is separate;

   -----------------------------------------------------------------------------
   package Transmission is
      -- Monitor, control, status, and report transmission conditions.
      -- Vehicle transmission.  Provides steering and braking for the vehicle.
      --  Acceleration inputs are monitored to ensure transmission is in proper
      --  gear.

      -- Currently assuming that it can provide steering when engine is running
      -- or not.
      procedure Steering (Steer_Rate : Float);

      procedure Brake (Brake_Rate : Float);

      procedure Accelerator (Position : Float);

      procedure Status (Gear : out Gears;
                        Drive_Mode : out Drive_Mode_Type;
                        Steer_Rate : out Float;
                        Brake_Rate : out Float;
                        Accelerator_Position : out Float;
                        Brake_Set : out Boolean;
                        Velocity : out Float;
                        Odometer : out Float);

      procedure Set_Drive_Mode (Mode : Drive_Mode_Type);
      procedure Set_Gear_Mode (Gear : Gear_Mode_Type);
      procedure Set_Park_Brake (Brake_Set : Boolean);
      function Get_Drive_Mode return Drive_Mode_Type;
      function Get_Gear_Mode return Gear_Mode_Type;
      function Is_Brake_Set return Boolean;

      procedure Engage_Transmission;

      procedure Disengage_Transmission;
   end Transmission;
   package body Transmission is separate;


   ---------------------------------------------------------------------------
   package Engine is

      -- Engine operations sequencing, control, statusing, maintanence, and pro
      -- gnostics.

      procedure Engine_Start;

      procedure Engine_Stop;

      procedure Engine_Status (Engine_Coolant_Level : out Float;
                               Engine_Coolant_Temperature : out Float;
                               Engine_Rpm : out Float;
                               Engine_Oil_Level : out Float;
                               Engine_Oil_Temperature : out Float;
                               Engine_Running : out Boolean);

      procedure Stop_Engine_Fans;

      function Get_Fresh_Drinking_Water return Float;

      procedure Set_Fuel_Level (Cell : Integer; Level : Float);

   end Engine;
   package body Engine is separate;

   procedure Set_Fuel_Level (Cell : Integer; Level : Float) is
   begin
      Engine.Set_Fuel_Level (Cell, Level);
   end Set_Fuel_Level;

   --------------------------------------------------------------------------

   package Fuel_Sensors is

      procedure Initialize;

   end Fuel_Sensors;
   package body Fuel_Sensors is separate;
   --------------------------------------------------------------------------

   Overdrive : Float := 1.0;
   Throttle_Value : Float := 0.0;
   Limited_Mobility : Boolean := False;
   Brake_Value : Braking_Range := 0.0;

   Battery_Charge : Float := 0.8;  -- percentage of max

   Reset_Tripmeter : Float := 0.0;

   procedure Input (Obj : in Select_Tactical_Idle) is
   begin
      Pace.Log.Trace (Obj);
   end Input;

   procedure Output (Obj : out Get_Battery_Status) is
   begin
      Obj.Battery_Charge := Battery_Charge;
   end Output;

   procedure Output (Obj : out Get_Engine_Status) is
   begin
      Engine.Engine_Status (Obj.Engine_Coolant_Level,
                            Obj.Engine_Coolant_Temperature,
                            Obj.Engine_Rpm,
                            Obj.Engine_Oil_Level,
                            Obj.Engine_Oil_Temperature,
                            Obj.Engine_Running);
   end Output;

   procedure Output (Obj : out Get_Water_Generated) is
   begin
      Obj.Fresh_Drinking_Water := Engine.Get_Fresh_Drinking_Water;
   end Output;

   procedure Output (Obj : out Get_Fuel_Status) is
      Data : Fuel_Cell_Type;
   begin
      Obj.Current_Fuel_Cell := Current_Fuel_Cell;
      for I in 1 .. 3 loop
         Data := Fuel_Cells (I);
         Obj.Fuel_Cell_Fuel_Levels (I) := Data.Fuel_Level;
         Obj.Fuel_Cell_Water_Levels (I) := Data.Water_Level;
         Obj.Fuel_Cell_Temperatures (I) := Data.Fuel_Temperature;
      end loop;
   end Output;

   procedure Input (Obj : in Set_Limited_Mobility) is
   begin
      Limited_Mobility := True;
   end Input;

   procedure Input (Obj : in Unset_Limited_Mobility) is
   begin
      Limited_Mobility := False;
   end Input;

   procedure Input (Obj : in Reset_Trip) is
      Dummy_Gear : Gears;
      Drive_Mode : Drive_Mode_Type;
      A, B, C, D : Float;
      Odometer : Float;
      Brake_Set : Boolean;
   begin
      Transmission.Status (Dummy_Gear, Drive_Mode, A, B, C, Brake_Set, D, Odometer);
      Reset_Tripmeter := Odometer;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Output (Obj : out Get_Trans_Status) is

   begin

      Transmission.Status (Obj.Current_Gear,
                           Obj.Drive_Mode,
                           Obj.Steer_Rate,
                           Obj.Brake_Rate,
                           Obj.Accelerator_Position,
                           Obj.Park_Brake_Set,
                           Obj.Speed,
                           Obj.Odometer);
      Obj.Tripmeter := Obj.Odometer - Reset_Tripmeter;
      Obj.Current_View := Current_View;
   end Output;

   -- Drive-by-wire steering control, 10% effectiveness at max speed
   Max_Speed_Breakpoint : constant Float := Phys.Max_Velocity * 1.1;

   procedure Input (Obj : in Steering_Control) is
      Steer_Rate : Float;
   begin
      if Speed > Max_Speed_Breakpoint then
         Steer_Rate := 0.0;
      else
         -- The faster the vehicle goes, the less effect the steering
         Steer_Rate := Obj.Rate * (1.0 - abs (Speed / Max_Speed_Breakpoint));
      end if;
      Transmission.Steering (Steer_Rate);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Braking_Control) is
   begin
      Brake_Value := Obj.Rate;
      Transmission.Brake (Brake_Value);
      Pace.Log.Trace (Obj);
   end Input;

   function Get_Brake_Level return Float is
   begin
      return Brake_Value;
   end Get_Brake_Level;

   procedure Input (Obj : in Throttle_Control) is
   begin
      Throttle_Value := Overdrive * Obj.Rate;
      if Limited_Mobility then
         Throttle_Value := Throttle_Value * Phys.Max_Velocity_In_Limited_Mobility / Phys.Max_Velocity;
      end if;
      Transmission.Accelerator (Throttle_Value);
      Pace.Log.Trace (Obj);
   end Input;

   function Is_Limited_Mobility return Boolean is
   begin
      return Limited_Mobility;
   end Is_Limited_Mobility;

   procedure Input (Obj : in Accelerator_Control) is
   begin
      if Obj.Rate < 0.0 then  -- Want to brake
         if Throttle_Value > 0.0 then
            declare
               Msg : Throttle_Control;
            begin
               Msg.Rate := 0.0;
               Pace.Dispatching.Input (Msg);
            end;
         end if;
         declare
            Msg : Braking_Control;
         begin
            Msg.Rate := -Obj.Rate;
            Pace.Dispatching.Input (Msg);
         end;
      else -- want to throttle
         if Brake_Value > 0.0 then
         declare
            Msg : Braking_Control;
         begin
            Msg.Rate := 0.0;
            Pace.Dispatching.Input (Msg);
         end;
         end if;
         declare
            Msg : Throttle_Control;
         begin
            Msg.Rate := Obj.Rate;
            Pace.Dispatching.Input (Msg);
         end;
      end if;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Park_Brake_Control) is
   begin
      Transmission.Set_Park_Brake (Obj.Brake_Control);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Start_Engine) is
   begin
      Engine.Engine_Start;
      Transmission.Engage_Transmission;
      Fuel_Sensors.Initialize;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Stop_Engine) is
   begin
      Engine.Engine_Stop;
      Transmission.Disengage_Transmission;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Tran_Drive) is
   begin
      Overdrive := 1.0;
      Transmission.Set_Drive_Mode (Forward);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Tran_Reverse) is
   begin
      Transmission.Set_Drive_Mode (Rev);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Tran_Pivot) is
   begin
      Transmission.Set_Drive_Mode (Pivot);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Tran_Neutral) is
   begin
      Transmission.Set_Drive_Mode (Neutral);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Tran_Park) is
   begin
      Transmission.Set_Drive_Mode (Park);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Tran_Lowlock) is
   begin
      Overdrive := 0.25;
      Transmission.Set_Drive_Mode (Forward);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Set_Selected_Gear) is
   begin
      Overdrive := 1.0;
      Transmission.Set_Gear_Mode (Obj.Selected_Gear);
      Pace.Log.Trace (Obj);
   end Input;

   package E is new Pace.Signals.Multiple (Drive_Mode_Type);

   procedure Input (Obj : in Transmission_Control) is
   begin
      if Obj.Mode /= Neutral and Speed > 1.0 then
         Pace.Log.Put_Line ("UNABLE TO SHIFT GEARS.. SPEED IS GREATER THAN 1.0");
      else
         case Obj.Mode is
            when Forward =>
               Pace.Dispatching.Input (Tran_Drive'(Pace.Msg with null record));
            when Rev =>
               Pace.Dispatching.Input (Tran_Reverse'(Pace.Msg with null record));
            when Neutral =>
               Pace.Dispatching.Input (Tran_Neutral'(Pace.Msg with null record));
            when Park =>
               Pace.Dispatching.Input (Tran_Park'(Pace.Msg with null record));
            when Pivot =>
               Pace.Dispatching.Input (Tran_Pivot'(Pace.Msg with null record));
            when Lowlock =>
               Pace.Dispatching.Input (Tran_Lowlock'(Pace.Msg with null record));
         end case;
         E.Signal (Obj.Mode);
      end if;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Output (Obj : out Transmission_Mode) is
   begin
      E.Await_Any (Obj.Mode);
      E.Reset;
      Pace.Log.Trace (Obj);
   end Output;

   procedure Input (Obj : in Turn_Fan_Off) is
   begin
      Engine.Stop_Engine_Fans;
      Pace.Log.Trace (Obj);
   end Input;

   function Get_Drive_Mode return Drive_Mode_Type is
   begin
      return Transmission.Get_Drive_Mode;
   end Get_Drive_Mode;

   function Get_Gear_Mode return Gear_Mode_Type is
   begin
      return Transmission.Get_Gear_Mode;
   end Get_Gear_Mode;

   function Is_Brake_Set return Boolean is
   begin
      return Transmission.Is_Brake_Set;
   end Is_Brake_Set;

   procedure Joystick_On (Joy_Id : Integer) is
   begin
      Joystick.On (Joy_Id);
   end Joystick_On;

   procedure Joystick_Off is
   begin
      Joystick.Off;
   end Joystick_Off;

   procedure Set_Joystick_Unique_Id (Id : Integer) is
   begin
      Joystick.Set_Unique_Id (Id);
   end Set_Joystick_Unique_Id;

   function Get_Joystick_Unique_Id return Integer is
   begin
      return Joystick.Get_Unique_Id;
   end Get_Joystick_Unique_Id;

   procedure Input (Obj : in Emplace) is
   begin
      Emplaced_State := True;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Output (Obj : out Emplacement_Status) is
   begin
      Obj.Is_Emplaced := Emplaced_State;
   end Output;

end Mob.Vehicle;
