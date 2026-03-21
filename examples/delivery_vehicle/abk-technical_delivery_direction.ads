with Pace;
with Ahd;

package Abk.Technical_Delivery_Direction is

   type Calculate_Flight_Solution is new Pace.Msg with null record;
   procedure Input (Obj : in Calculate_Flight_Solution);

   -- also calls calculate_vel_and_az internally!
   type Perform_Technical_Delivery_Direction is new Pace.Msg with
      record
         Mission : Ahd.Mission_Record;
      end record;
   procedure Inout (Obj : in out Perform_Technical_Delivery_Direction);

   -- used to recalculate the vel and az before delivering
   procedure Calculate_Vel_And_Az (Mission : in out Ahd.Mission_Record);

   -- returns correct azimuth for drone (in radians) to hit target in a 2D-world
   -- azimuth will be positive for rotating drone counter-clockwise and negative for rotating
   -- clockwise
   function Get_Azimuth (Target_Easting, Target_Northing : Float) return Float;

end Abk.Technical_Delivery_Direction;
