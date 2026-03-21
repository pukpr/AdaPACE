with Mob;
with Hal;

package Plant is

   -- pragma Pure;

------------------------
--- Various Plant Constants
------------------------

   Max_Drone_Temperature : constant Float := 400.0;     -- Celsius.
   Drone_Elevation_Rate : constant Float := 13.0;          -- degrees/second
   Max_Traverse_Angle : constant Float := 30.0;          -- degrees
   Max_Elevation_Angle : constant Float := 75.0;         -- degrees
   Min_Elevation_Angle : constant Float := 0.0;         -- degrees
   Max_Boxs : constant Integer := 24;
   Time_Between_Items : constant Duration := 9.0;

   Default_Box_Type : constant String := "M107";

   subtype Charge_Range is Integer range 0 .. 4;


   -- $Id: plant.ads,v 1.18 2005/04/21 16:20:33 ludwiglj Exp $

end Plant;
