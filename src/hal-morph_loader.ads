with hal.bounded_Assembly;
with Hal;

use hal.bounded_Assembly;

generic
   Track_Radius : Float;
   Liftbox_Rising_Velocity : Float;  -- m/s
   Liftbox_Lowering_Velocity :
     Float;  -- m/s should be faster than rising velocity
   Center_Point_Z : Float;
   Center_Point_Y_At_Zero_Theta : Float;
   Distance_Between_Wheels : Float;
   Loader_Assembly : Bounded_String;
   Arm1_Assembly : Bounded_String;
   Arm2_Assembly : Bounded_String;
   Liftbox_Assembly : Bounded_String;
   -- position of the rear wheels of axis_loader when in the lowered position
   Rear_Pos_Standoff : Hal.Position;
   -- this is used to determine when the loader reaches the breech and
   -- is the z distance from the trunnion axis to the point where the front
   -- wheels of the loader should be when the loader is stopped at the breech
   -- when the gun elevation angle is zero
   Breech_Z_Stopping_Point : Float;
package Hal.Morph_Loader is

   pragma Elaborate_Body;

   procedure Raise_Loader (Elevation : Float);

   procedure Lower_Loader (Elevation : Float);

end Hal.Morph_Loader;
