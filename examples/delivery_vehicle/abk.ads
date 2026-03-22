package Abk is
   -- AirBorneKern
    
   pragma Elaborate_Body;

   Gravity : constant := 9.81;  -- m/s

   -- Raised when elevation angle isn't high enough to reach customer, which usually
   -- means there was a sqrt of a negative number
   Bad_Elevation_Angle : exception;

   -- This function calculates the time that a box has already been airborne
   -- given the horizontal distance (m) traveled, initial angle (radians),
   -- and initial velocity (m/s).
   function Time_In_Air
              (Distance : in Float; Angle : in Float; Velocity : in Float)
              return Float;

   -- This function returns the total time a box will be in the air, considering
   -- the difference in elevation between the delivery vehicle and the customer.
   -- Input angle (radians) and velocity (m/s) and vertical_distance (m)
   -- Vertical_Distance should be the difference in elevation between delivery vehicle and the customer,
   -- so if customer is higher than delivery vehicle the value should be negative.
   function Total_Time_In_Air (Angle : in Float;
                               Velocity : in Float;
                               Vertical_Distance : in Float) return Float;

   -- This function returns the horizontal distance a box has
   -- traveled given the initial angle (radians), Velocity (m/s), and time (s).
   function Distance_Traveled
              (Angle : in Float; Velocity : in Float; Time : in Float)
              return Float;

   -- Returns the initial velocity of a box
   -- given angle (radians) of drone and total distance (m) to travel
   -- Note: Assumes delivery vehicle and customer are at same elevation
   function Initial_Velocity
              (Angle : in Float; Distance : in Float) return Float;

   -- Returns the initial velocity of a box
   -- given angle (radians) of drone, horizontal_distance travelled,
   -- and the vertical_distance at which the box lands.
   -- i.e. if customer is 350 meters below in elevation from the source then
   -- vertical_distance should be -350
   function Initial_Velocity (Angle : in Float;
                              Horizontal_Distance : in Float;
                              Vertical_Distance : in Float) return Float;

   -- Returns the elevation to deliver the box at in radians, given
   -- the initial velocity, the horizontal_distance travelled,
   -- and the vertical_distance at which the box lands.
   -- The elevation given will be less than Pi/4.  Can find the complementary
   -- elevation, which will land at same spot by going Pi/2 - Elevation.
   -- i.e. if customer is 350 meters below in elevation from the source then
   -- vertical_distance should be -350
   -- Success will be false if the velocity isn't high enough to reach the customer
   procedure Elevation_Calculation (Initial_Velocity : in Float;
                                    Horizontal_Distance : in Float;
                                    Vertical_Distance : in Float;
                                    Success : out Boolean;
                                    Elevation : out Float);

   -- returns the horizontal distance difference between the customer's location
   -- and the vehicle's location
   function Get_Horizontal_Distance
     (Target_Easting, Target_Northing : Float) return Float;

   -- returns the difference between the customer's elevation and the vehicle's elevation
   function Get_Vertical_Distance
     (Target_Easting, Target_Northing : Float) return Float;

end Abk;

