with Mob;
with Mob.Vehicle;
with Vkb;

package Acu is
   --pragma Elaborate_Body;

   -- using defaults...
   Phys : Mob.Physical_Properties;
   Tran : Mob.Transmission_Properties;
   Eng : Mob.Engine_Properties;
   Fuel : Mob.Fuel_Properties;

   function Change_Due_To_Pitch (Pitch : Float; Max_Velocity : Float) return Float;

   North : Float := 0.0;
   East : Float := 0.0;
   Altitude : Float := 0.0;

   -- Pitch (Positive is facing uphill)
   Pitch : Float := 0.0;  -- radians
   -- Roll (A positive roll has the right side of vehicle lower than left)
   Roll : Float := 0.0;  -- radians
   -- Heading (0 degrees is north with positive being clockwise)
   Heading : Float := 0.0; -- radians

   Zone : Integer := 0;
   Viscosity : Float := 0.0;
   Load_Weight : Float := 0.0;

   package Vehicle is new Mob.Vehicle (Phys, Tran, Eng, Fuel, Change_Due_To_Pitch,
                                       North,
                                       East,
                                       Altitude,
                                       Pitch,
                                       Roll,
                                       Heading,
                                       Zone,
                                       Viscosity,
                                       Load_Weight,
                                       Vkb);
   -- $Id: acu.ads,v 1.7 2005/04/08 15:44:14 ludwiglj Exp $

end Acu;

