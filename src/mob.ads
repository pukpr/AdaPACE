with Ada.Numerics;

package Mob is
   -- MOB :: Mobility

   pragma Pure;

   type Drive_Mode_Type is (Forward, Rev, Neutral, Park, Pivot, Lowlock);
   type Gear_Mode_Type is (Low, High, Unknown);

   subtype Steering_Range is Float range -1.0 .. 1.0;
   subtype Braking_Range is Float range 0.0 .. 1.0;
   subtype Throttle_Range is Float range 0.0 .. 1.0;
   subtype Acceleration_Range is Float range -1.0 .. 1.0; -- negative if brake

   -- the physical properties that define how a vehicle moves
   type Physical_Properties is
      record
         Max_Velocity : Float := 20.0;                    -- Meters / Second
         Max_Velocity_In_Limited_Mobility : Float := 2.77777; -- Meters / Second
         Max_Reverse_Velocity : Float := -25.0 / 3.0;     -- Meters / Second
         Max_Turn_Rate : Float := Ada.Numerics.Pi / 5.0;  -- Radians / Meter
         Max_Pivot_Rate : Float := Ada.Numerics.Pi / 2.0; -- Radians / Second
         Max_Brake_Decel : Float := 10.0;                 -- Meters / Second
         Ebrake_Decel : Float := 2.5;                     -- meters / second
         Drag : Float := 0.05;                            -- Friction, et.al., that slows vehicle
         Inertial_Drag : Float := 0.2;                    -- Inertial Friction on startup
         -- length and width are needed by ctdb query for pitch/roll
         -- length of vehicle at points that touch the ground (wheels, tracks, etc)
         Base_Length : Float := 3.63855;                      -- meters
         -- width of vehicle at points that touch the ground (wheels, tracks, etc)
         Base_Width : Float := 2.2606;                          -- meters
      end record;

   -- the properties that define a transmission
   type Transmission_Properties is
      record
         -- Percentage of max_velocity at which the transmission shifts from 1st gear to 2nd gear
         Gear_1_Velocity_Percent : Float := 0.2;
         -- Percentage of max_velocity at which the transmission shifts from 2nd gear to 3rd gear
         Gear_2_Velocity_Percent : Float := 0.65;
         -- the followin g acceleration factors are defined as the change in velocity in meters
         -- per Dt when the throttle is at 100% for the specified gear
         Gear_1_Acc_Factor : Float := 3.0;                -- Meters / Dt (Seconds)
         Gear_2_Acc_Factor : Float := 2.5;                -- Meters / Dt (Seconds)
         Gear_3_Acc_Factor : Float := 2.0;                -- Meters / Dt (Seconds)
         Rev_Acc_Factor : Float := 1.0;                   -- Meters / Dt (Seconds)
         Dt : Float := 1.0;                               -- Delta Update Time
      end record;

   -- the properties that define an engine
   type Engine_Properties is
      record
         Change_In_Temp_Per_Second : Float := 0.55 / 600.0;
         Coolant_Plateau_Temp : Float := 0.65;
         Oil_Plateau_Temp : Float := 0.65;
         Coolant_Non_Operating_Temp : Float := 0.1;
         Oil_Non_Operating_Temp : Float := 0.1;
         Max_Water_Level : Float := 41.0;             -- Liters
         -- as 1 unit of fuel is consumed, this many units of water are generated
         Water_Generation_Rate : Float := 0.6;        -- Liters
         Max_Engine_Oil_Capacity : Float := 20.0;     -- Liters.
         Max_Engine_Coolant_Capacity : Float := 40.0; -- Liters.
         Max_Engine_Oil_Temp : Float := 100.0;        -- Celsius.
         Max_Engine_Coolant_Temp : Float := 150.0;    -- Celsius.
         Max_Rpm : Float := 4000.0;            -- RPM.
         Min_Rpm : Float := 600.0;             -- RPM.
      end record;

   -- properties related to fuel
   type Fuel_Properties is
      record
         Num_Cells : Integer := 3;                             -- number of fuel tanks
         Max_Fuel_Cell_Capacity : Float := 233.0;    -- Liters.
         Max_Fuel_Temperature : Float := 40.0;        -- Celsius.
         Fuel_Resupply_Rate : Float := 65.0;          -- liters/minute
         Max_Battery_Charge : Float := 40.0;          -- Volts?
      end record;
   -- $Id

end Mob;
