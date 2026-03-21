with Pace;
with Pace.Semaphore;
with Gkb;
with Pace.Notify;
with Str;

generic
   -- lots of parameters within the following record types...
   -- use defaults to simplify instantiation
   Phys : in Physical_Properties;
   Tran : in Transmission_Properties;
   Eng : in Engine_Properties;
   Fuel : in Fuel_Properties;
   -- provide a function that returns a percent change in speed when going uphill
   with function Change_Due_To_Pitch (Pitch : Float; Max_Velocity : Float) return Float is <>;

   -- the following are in out variables, and can be accessed directly
   North, East, Altitude : in out Float;  -- meters
   Pitch, Roll, Heading : in out Float;  -- radians
   Zone : in out Integer;
   --Latitude, Longitude : in out Long_Float;  -- meters
   Viscosity, Load_Weight : in out Float;
   -- Heading (0 degrees is north with positive being clockwise)
   -- Pitch (Positive is facing uphill)
   -- Roll (A positive roll has the right side of vehicle lower than left)
   with package Kb is new Gkb (<>);
   -- at runtime, kb must have matches for the following:
   -- driving_throttle (Id)
   -- driving_steering (Id)
package Mob.Vehicle is

   pragma Elaborate_Body;

   -- Coordinate and control Automotive functions

   -- provided as a mutex for north, east, and heading
   Location_Mutex : aliased Pace.Semaphore.Mutex;

   type Fuel_Cell_Data is array (1 .. 3) of Float;  -- range on this!

   type Select_Tactical_Idle is new Pace.Msg with null record;
   procedure Input (Obj : in Select_Tactical_Idle);

   type Get_Battery_Status is new Pace.Msg with
      record
         Battery_Charge : Float;
      end record;
   procedure Output (Obj : out Get_Battery_Status);

   type Get_Engine_Status is new Pace.Msg with
      record
         Engine_Coolant_Level : Float;
         Engine_Coolant_Temperature : Float;
         Engine_Rpm : Float;
         Engine_Oil_Level : Float;
         Engine_Oil_Temperature : Float;
         Engine_Running : Boolean;
      end record;
   procedure Output (Obj : out Get_Engine_Status);

   type Get_Fuel_Status is new Pace.Msg with
      record
         Current_Fuel_Cell : Integer;
         Fuel_Cell_Fuel_Levels : Fuel_Cell_Data;    -- percentage
         Fuel_Cell_Water_Levels : Fuel_Cell_Data;
         Fuel_Cell_Temperatures : Fuel_Cell_Data;
      end record;
   procedure Output (Obj : out Get_Fuel_Status);

   type Gears is (Neutral, Pivot, Rev, Gear_1, Gear_2, Gear_3);
   type Camera_View is (Look_Forward, Look_Backward, Look_Left, Look_Right);

   type Get_Trans_Status is new Pace.Msg with
      record
         Current_Gear : Gears;
         Drive_Mode : Drive_Mode_Type;
         Gear_Mode : Gear_Mode_Type;
         Steer_Rate : Float;
         Brake_Rate : Float;
         Accelerator_Position : Float;
         Park_Brake_Set : Boolean;
         Speed : Float;
         Odometer : Float;
         Tripmeter : Float;
         Current_View : Camera_View;
      end record;
   procedure Output (Obj : out Get_Trans_Status);

   type Reset_Trip is new Pace.Msg with null record;
   procedure Input (Obj : Reset_Trip);

   type Steering_Control is new Pace.Msg with
      record
         Rate : Steering_Range;
      end record;
   procedure Input (Obj : in Steering_Control);

   type Set_Limited_Mobility is new Pace.Msg with null record;
   procedure Input (Obj : in Set_Limited_Mobility);

   type Unset_Limited_Mobility is new Pace.Msg with null record;
   procedure Input (Obj : in Unset_Limited_Mobility);

   function Is_Limited_Mobility return Boolean;
   function Get_Brake_Level return Float;

   type Braking_Control is new Pace.Msg with
      record
         Rate : Braking_Range;
      end record;
   procedure Input (Obj : in Braking_Control);

   type Throttle_Control is new Pace.Msg with
      record
         Rate : Throttle_Range;
      end record;
   procedure Input (Obj : in Throttle_Control);

   type Accelerator_Control is new Pace.Msg with
      record
         Rate : Acceleration_Range;
      end record;
   procedure Input (Obj : in Accelerator_Control);

   type Park_Brake_Control is new Pace.Msg with
      record
         Brake_Control : Boolean;
      end record;
   procedure Input (Obj : in Park_Brake_Control);

   type Set_Selected_Gear is new Pace.Msg with
      record
         Selected_Gear : Gear_Mode_Type;
      end record;
   procedure Input (Obj : in Set_Selected_Gear);

   type Start_Engine is new Pace.Msg with null record;
   procedure Input (Obj : in Start_Engine);

   type Stop_Engine is new Pace.Msg with null record;
   procedure Input (Obj : in Stop_Engine);

   type Turn_Fan_Off is new Pace.Msg with null record;
   procedure Input (Obj : in Turn_Fan_Off);

   type Transmission_Control is new Pace.Msg with
      record
         Mode : Drive_Mode_Type;
      end record;
   procedure Input (Obj : in Transmission_Control);

   type Transmission_Mode is new Transmission_Control with null record;
   procedure Output (Obj : out Transmission_Mode); -- waits on update

   -- each time this is called the fresh_drinking_water is reset, such that
   -- fresh_drinking_water represents the amount of water generated since
   -- the last time this method has been called
   type Get_Water_Generated is new Pace.Msg with
      record
         Fresh_Drinking_Water : Float;  -- as percentage of max
      end record;
   procedure Output (Obj : out Get_Water_Generated);

   -- tells the internal joystick task to begin looking for data from joy_id
   procedure Joystick_On (Joy_Id : Integer);
   -- turns off internal joystick task
   procedure Joystick_Off;
   -- use this to switch modes
   procedure Set_Joystick_Unique_Id (Id : Integer);
   function Get_Joystick_Unique_Id return Integer;

   type Horn is new Pace.Notify.Subscription with
      record
         Kind : Str.Bstr.Bounded_String;
      end record;

   type Update_Six_Dof is new Pace.Notify.Subscription with
      record
         North : Float;
         East : Float;
         Altitude : Float;
         Heading : Float;
         Pitch : Float;
         Roll : Float;
      end record;

   -- Level is percent: 0.0 = empty 1.0 = full.
   procedure Set_Fuel_Level (Cell : Integer; Level : Float);

   function Get_Drive_Mode return Drive_Mode_Type;
   function Get_Gear_Mode return Gear_Mode_Type;
   function Is_Brake_Set return Boolean;

   type Emplace is new Pace.Msg with null record;
   procedure Input (Obj : in Emplace);

   type Emplacement_Status is new Pace.Msg with
      record
         Is_Emplaced : Boolean;
      end record;
   procedure Output (Obj : out Emplacement_Status);

private

   Emplaced_State : Boolean := False;

   Current_Fuel_Cell : Integer := 1;
   Rpms : Float := 0.0;                  -- engine revolutions per minute;
   Speed : Float;                        -- meters/second

   type Fuel_Cell_Type is
      record
         Fuel_Level : Float := 1.0;         -- 0.0 = empty 1.0 = full.
         Fuel_Temperature : Float := 20.0;  -- Degrees Celsius.
         Water_Level : Float := 0.0;        -- Percentage of the fuel
      end record;

   Fuel_Cells : array (1 .. Fuel.Num_Cells) of Fuel_Cell_Type;

   type Tran_Drive is new Pace.Msg with null record;
   procedure Input (Obj : in Tran_Drive);

   type Tran_Reverse is new Pace.Msg with null record;
   procedure Input (Obj : in Tran_Reverse);

   type Tran_Pivot is new Pace.Msg with null record;
   procedure Input (Obj : in Tran_Pivot);

   type Tran_Neutral is new Pace.Msg with null record;
   procedure Input (Obj : in Tran_Neutral);

   type Tran_Park is new Pace.Msg with null record;
   procedure Input (Obj : in Tran_Park);

   type Tran_Lowlock is new Pace.Msg with null record;
   procedure Input (Obj : in Tran_Lowlock);


   pragma Inline (Input);

end Mob.Vehicle;
