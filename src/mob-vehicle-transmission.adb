with Ada.Numerics.Elementary_Functions;
with Hal;
with Pace.Log;
-- with Pace.Server.Peek_Factory;

separate (Mob.Vehicle)
package body Transmission is

   function Id is new Pace.Log.Unit_Id;
   function Name return String renames Pace.Log.Name;

   use Ada.Numerics;
   use Ada.Numerics.Elementary_Functions;

   -------- Position variables

   Current_North, Current_East, Previous_North, Previous_East, Odo_Data : Float := 0.0;

--   function Peek_Current_North return String is
--   begin
--      return Current_North'Img;
--   end Peek_Current_North;
--   package Current_North_Img is new Pace.Server.Peek_Factory (Peek_Current_North);

--   function Peek_Current_East return String is
--   begin
--      return Current_East'Img;
--   end Peek_Current_East;
--   package Current_East_Img is new Pace.Server.Peek_Factory (Peek_Current_East);

--   function Peek_Heading return String is
--   begin
--      return Float'Image (Heading);
--   end Peek_Heading;
--   package Heading_Img is new Pace.Server.Peek_Factory (Peek_Heading);

--   function Peek_Speed return String is
--   begin
--      return Float'Image (Speed);
--   end Peek_Speed;
--   package Speed_Img is new Pace.Server.Peek_Factory (Peek_Speed);


   -- Odo_Data is in Km

   -------- Internal functions

   function Get_Distance (Cur_North, Cur_East, Prev_North, Prev_East : Float) return Float is

      North_Factor, East_Factor : Float;
   begin
      -- Pace.Log.Put_Line ("Cur North : " & Float'Image (Cur_North));
      -- Pace.Log.Put_Line ("Cur East : " & Float'Image (Cur_East));
      -- Pace.Log.Put_Line ("Prev North : " & Float'Image (Prev_North));
      -- Pace.Log.Put_Line ("Prev East : " & Float'Image (Prev_East));
      North_Factor := (Prev_North - Cur_North) ** 2;
      East_Factor := (Prev_East - Cur_East) ** 2;
      return Sqrt (North_Factor + East_Factor);
   end Get_Distance;

   --- Gearing
   Current_Gear : Gears;

   for Current_Gear'Size use 32; -- for p4

   type Gear_Data_Type is array (Gears) of Float;

   Gear_Acc : Gear_Data_Type := (Neutral => 0.0,
                                 Pivot => 0.0,
                                 Rev => Tran.Rev_Acc_Factor,
                                 Gear_1 => Tran.Gear_1_Acc_Factor,
                                 Gear_2 => Tran.Gear_2_Acc_Factor,
                                 Gear_3 => Tran.Gear_3_Acc_Factor);

   -- the percentage of the corresponding Gear_Up percent for Gear_Down
   Down_Percentage : constant Float := 0.75;

   Gear_Down : Gear_Data_Type := (Neutral => 0.0,
                                  Pivot => 0.0,
                                  Rev => 0.0,
                                  Gear_1 => 0.0,
                                  Gear_2 => Phys.Max_Velocity * Tran.Gear_1_Velocity_Percent * Down_Percentage,
                                  Gear_3 => Phys.Max_Velocity * Tran.Gear_2_Velocity_Percent * Down_Percentage);
   Gear_Up : Gear_Data_Type := (Neutral => 0.0,
                                Pivot => 0.0,
                                Rev => Phys.Max_Reverse_Velocity,
                                Gear_1 => Phys.Max_Velocity * Tran.Gear_1_Velocity_Percent,
                                Gear_2 => Phys.Max_Velocity * Tran.Gear_2_Velocity_Percent,
                                Gear_3 => Phys.Max_Velocity);
   Gear_Ratios : Gear_Data_Type :=
     (Neutral => 0.0, -- neutral isn't used here
      Pivot => 0.0018,
      Rev => -0.001825,
      Gear_1 => Gear_Up (Gear_1) / Eng.Max_Rpm,
      Gear_2 => Gear_Up (Gear_2) / Eng.Max_Rpm,
      Gear_3 => Gear_Up (Gear_3) / Eng.Max_Rpm);


   --- Drive Modes

   subtype Mode_Type is Drive_Mode_Type range Forward .. Pivot;

   Current_Mode : Mode_Type;
   Current_Gear_Select : Gear_Mode_Type;

   type Mode_Dir_Type is array (Mode_Type) of Float;

   Mode_Dir : Mode_Dir_Type :=
     (Forward => 1.0, Rev => -1.0, Neutral => 1.0, Park => 0.0, Pivot => 0.0);

   type Tran_Type is array (Mode_Type) of Gears;
   Tran_Select : Tran_Type := (Forward => Gear_1,
                               Rev => Rev,
                               Neutral => Neutral,
                               Park => Neutral,
                               Pivot => Pivot);

   ---------- Various Input Rates and Modes

   Steering_Rate : Float := 0.0;  -- -1.0 = full left +1.0 = full right.
   Damp_Rate : Float := 0.0;

   Braking_Rate : Float := 0.0;  -- 0.0 = no braking 1.0 = full braking.

   Throttle_Percent : Float := 0.0;  -- 0.0 no throttle
   -- 1.0 = full throttle

   My_Brake_Set : Boolean := True;

   Transmission_Engaged : Boolean := False;

   procedure Check_Shift_Gears is
   begin
      -- check shifting up
      if Current_Gear = Gear_1 or Current_Gear = Gear_2 then
         if abs (Speed) > Gear_Up (Current_Gear) then
            Current_Gear := Gears'Succ (Current_Gear);
            Pace.Log.Put_Line ("Up shifting to gear " & Gears'Image (Current_Gear)); -- removed pragma debug
         end if;
      end if;
      -- check shifting down
      if abs (Speed) < Gear_Down (Current_Gear) then
         Current_Gear := Gears'Pred (Current_Gear);
         Pace.Log.Put_Line ("Down shifting to gear " & Gears'Image (Current_Gear)); -- removed pragma debug
      end if;
   end Check_Shift_Gears;

   function Uphill_Factor return Float is
   begin
      -- only adjust for pitch if we are going uphill
      -- uphill could be negative pitch and going in reverse
      if (Pitch > 0.0 and Current_Gear >= Gear_1) or
        (Pitch < 0.0 and Current_Gear = Rev) then
         return Change_Due_To_Pitch (Pitch, Phys.Max_Velocity);
      else
         return 1.0;
      end if;
   end Uphill_Factor;

   function Ebrake_Factor return Float is
   begin
      if My_Brake_Set then
         return Phys.Ebrake_Decel;
      else
         return 0.0;
      end if;
   end Ebrake_Factor;

   function Calculate_Speed return Float is
      Speed_Result : Float;
      Pitch_Adjustment : Float := Uphill_Factor;
      Soil_Adjust : Float;
   begin
      if Viscosity >= 0.0 and Viscosity <= 1.0 then
         Soil_Adjust := 1.0 - Viscosity;
      else
         Soil_Adjust := 1.0;
      end if;

      Speed_Result := (Speed +
                       Tran.Dt * Mode_Dir (Current_Mode) *
                       (Throttle_Percent * Pitch_Adjustment *
                        Gear_Acc (Current_Gear) -
                        Phys.Drag * Speed - Phys.Inertial_Drag -
                        (Braking_Rate * Phys.Max_Brake_Decel) -
                        Ebrake_Factor));
      -- check that speed_result doesn't go over max
      if Current_Mode = Forward then
         if Speed_Result > Phys.Max_Velocity * Pitch_Adjustment * Soil_Adjust then
            Speed_Result := Phys.Max_Velocity * Pitch_Adjustment * Soil_Adjust;
         end if;
      elsif Current_Mode = Rev then
         if Speed_Result < Phys.Max_Reverse_Velocity * Pitch_Adjustment * Soil_Adjust  then
            Speed_Result := Phys.Max_Reverse_Velocity * Pitch_Adjustment * Soil_Adjust;
         end if;
      end if;
      -- check that speed_result doesn't go under 0
      if Current_Gear /= Rev then
         if Speed_Result < 0.0 then
            Speed_Result := 0.0;
         end if;
      else
         if Speed_Result > 0.0 then
            Speed_Result := 0.0;
         end if;
      end if;

      return Speed_Result;
   end Calculate_Speed;

   function Calculate_Heading return Float is
      H : Float := Heading;
   begin
      if Current_Gear /= Pivot then
         H := Damp_Rate * Phys.Max_Turn_Rate * Tran.Dt * abs (Speed) + H;
      else
         H := Damp_Rate * Phys.Max_Pivot_Rate * Tran.Dt * Throttle_Percent + H;
      end if;

      if H > Pi then
         H := -2.0 * Pi + H;
      elsif H < -Pi then
         H := 2.0 * Pi + H;
      end if;
      return H;
   end Calculate_Heading;

   task Agent is pragma Task_Name (Name);
--      entry Engage_Transmission;
   end Agent;

   type Counter_Type is mod 8;

   task body Agent is
      P : Hal.Position := (0.0, 0.0, 0.0);       -- Position coords.
      R : Hal.Orientation := (0.0, 0.0, 0.0);    -- Rotation coords.
      Current_Time : Duration;
      Counter : Counter_Type := 0;

      procedure Update_Vehicle is
         Msg : Update_Six_Dof;
      begin
         Msg.Ack := False;
         Msg.North := North;
         Msg.East := East;
         Msg.Altitude := Altitude;
         Msg.Heading := Heading;
         Msg.Pitch := Pitch;
         Msg.Roll := Roll;
         Pace.Dispatching.Input (Msg);
      end;

   begin
      Pace.Log.Agent_Id (Id);

      Set_Drive_Mode (Neutral);

      Current_North := North;
      Current_East := -East;
      Previous_North := North;
      Previous_East := -East;
      Update_Vehicle;
      loop
         Speed := 0.0;
         Rpms := 0.0;
         --accept Engage_Transmission do
         Transmission_Engaged := True;
         Current_Time := Pace.Now;
         --end Engage_Transmission;
      Inner_Loop:
         loop
            Counter := Counter + 1;
            declare
               -- locking over heading, north, and east to allow the action request
               -- to modify these fields as well
               L : Pace.Semaphore.Lock (Location_Mutex'Access);
            begin
               ---------- Calculate new forward angle given the steer rate and speed.

               Damp_Rate := Steering_Rate * Steering_Rate;
               if Steering_Rate < 0.0 then
                  Damp_Rate := -Damp_Rate;
               end if;

               Speed := Calculate_Speed;

               Heading := Calculate_Heading;

               ---------- Shift gears if necessary.
               Check_Shift_Gears;

               ---------- Calculate new North and East coords using velocity vector.
               North := (North + Speed * Cos (Heading) * Tran.Dt);       -- GPS Coords.

               East := (East + Speed * Sin (Heading) * Tran.Dt);       -- GPS Coords.


               ---------- Calculate engine rpm.
               -- when in neutral rpms are determined from the throttle..
               -- otherwise rpms are determined from the speed
               if Current_Gear = Neutral or Current_Gear = Pivot then
                  Rpms := Throttle_Percent * Eng.Max_Rpm;
               else
                  Rpms := Speed / Gear_Ratios (Current_Gear);
               end if;

               if Rpms < Eng.Min_Rpm then
                  Rpms := Eng.Min_Rpm;
               end if;

               -- unnecessary to calculate odometer each dt
--               if Counter = 0 then

                  -- Calculate Odometer data
                  Previous_North := Current_North;
                  Previous_East := Current_East;
                  Current_North := North;
                  Current_East := -East;

                  Odo_Data := Odo_Data + Get_Distance (Current_North, Current_East,
                                                       Previous_North, Previous_East) /
                    1000.0;  -- km
--               end if;

               exit Inner_Loop when not Transmission_Engaged;
            end;

            Update_Vehicle;
            
            Pace.Log.Wait_Until (Current_Time + Duration (Tran.Dt));
            Current_Time := Pace.Now;

         end loop Inner_Loop;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Steering (Steer_Rate : Float) is
   begin
      -- do it here
      if Current_Gear = Rev then
         Steering_Rate := -Steer_Rate;
      else
         Steering_Rate := Steer_Rate;
      end if;
   end Steering;

   procedure Brake (Brake_Rate : Float) is
   begin
      Braking_Rate := Brake_Rate;
   end Brake;

   procedure Accelerator (Position : Float) is
   begin
      Throttle_Percent := Position;
   end Accelerator;

   procedure Status (Gear : out Gears;
                     Drive_Mode : out Drive_Mode_Type;
                     Steer_Rate : out Float;
                     Brake_Rate : out Float;
                     Accelerator_Position : out Float;
                     Brake_Set : out Boolean;
                     Velocity : out Float;
                     Odometer : out Float) is
   begin
      Steer_Rate := Steering_Rate;
      Brake_Rate := Braking_Rate;
      Accelerator_Position := Throttle_Percent;
      Brake_Set := My_Brake_Set;
      Velocity := Speed;
      Odometer := Odo_Data;
      Drive_Mode := Current_Mode;
      Gear := Current_Gear;
   end Status;

   function Get_Drive_Mode return Drive_Mode_Type is
   begin
      return Current_Mode;
   end Get_Drive_Mode;

   function Get_Gear_Mode return Gear_Mode_Type is
   begin
      return Current_Gear_Select;
   end Get_Gear_Mode;

   function Is_Brake_Set return Boolean is
   begin
      return My_Brake_Set;
   end Is_Brake_Set;

   -- MODSIM ADDITIONS ------------------

   procedure Set_Drive_Mode (Mode : Drive_Mode_Type) is
   begin
      Current_Mode := Mode;
      Current_Gear := Tran_Select (Current_Mode);
   end Set_Drive_Mode;

   procedure Set_Gear_Mode (Gear : Gear_Mode_Type) is
   begin
      Current_Gear_Select := Gear;
   end Set_Gear_Mode;

   procedure Set_Park_Brake (Brake_Set : Boolean) is
   begin
      My_Brake_Set := Brake_Set;
   end Set_Park_Brake;

   procedure Engage_Transmission is
   begin
      null; -- Agent.Engage_Transmission;
   end Engage_Transmission;

   procedure Disengage_Transmission is
   begin
      Transmission_Engaged := False;
   end Disengage_Transmission;

end Transmission;
