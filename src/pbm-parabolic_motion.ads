with Ada.Numerics;
with Hal;

package Pbm.Parabolic_Motion is

   -- Use this function to find the vertical and horizontal position of a point on a
   -- parabolic curve at a given time, as well as the tangent angle to the curve at that point
   procedure Calculate_Location (Theta : in Float; -- theta in rads..
                                 Initial_Velocity : in Float;  -- velocity in m/s
                                 Time : in Duration;  -- seconds from initial starting
                                 Delta_Vertical : out Float;  -- change in vertical from start (meters)
                                 Delta_Horizontal : out Float;  -- change in horizontal from start (meters)
                                 Tangent_Angle : out Float); -- tangent angle at Time in radians

   -- Assumes two-dimensional (flat) world
   -- Given Theta, Source location and destination location, return the
   -- initial velocity that a parabolic curve would need for an object to hit
   -- the destination
   procedure Calculate_Velocity (Theta : in Float;
                                 Source_X : in Float;
                                 Source_Y : in Float;
                                 Destination_Radius : in Float;
                                 Destination_Phi : in Float;
                                 Initial_Velocity : out Float);

   Gravity : constant Float := Pbm.Gravity;  -- m/s

   -- Raised when elevation angle isn't high enough to reach target, which usually
   -- means there was a sqrt of a negative number
   Bad_Elevation_Angle : exception;

   -- This function calculates the time that an object in parabolic motion has already been airborne
   -- given the horizontal distance (m) traveled, initial angle (radians),
   -- and initial velocity (m/s).
   function Time_In_Air
     (Distance : in Float; Angle : in Float; Velocity : in Float)
      return Float;

   -- This function returns the total time an object in parabolic motion will be in the air, considering
   -- the difference in elevation between the source and the destination.
   -- Input angle (radians) and velocity (m/s) and vertical_distance (m)
   -- Vertical_Distance should be the difference in elevation between source and destination,
   -- so if destination is higher than source the value should be negative.
   function Total_Time_In_Air (Angle : in Float;
                               Velocity : in Float;
                               Vertical_Distance : in Float) return Float;

   -- This function returns the horizontal distance an object in parabolic motion has
   -- traveled given the initial angle (radians), Velocity (m/s), and time (s).
   function Distance_Traveled
              (Angle : in Float; Velocity : in Float; Time : in Float)
              return Float;

   -- Returns the initial velocity of an object in parabolic motion
   -- given angle (radians) of launch and total distance (m) to travel
   -- Note: Assumes source and destination are at same elevation
   function Initial_Velocity
              (Angle : in Float; Distance : in Float) return Float;

   -- Returns the initial velocity of an object in parabolic motion
   -- given angle (radians) of launch, horizontal_distance travelled,
   -- and the vertical_distance at which the object lands.
   -- i.e. if destination is 350 meters below in elevation from the source then
   -- vertical_distance should be -350
   function Initial_Velocity (Angle : in Float;
                              Horizontal_Distance : in Float;
                              Vertical_Distance : in Float) return Float;

   -- Returns the elevation to launch the object at in radians, given
   -- the initial velocity, the horizontal_distance travelled,
   -- and the vertical_distance at which the object lands.
   -- The elevation given will be less than Pi/4.  Can find the complementary
   -- elevation, which will land at same spot by going Pi/2 - Elevation.
   -- i.e. if destination is 350 meters below in elevation from the source then
   -- vertical_distance should be -350
   -- Success will be false if the velocity isn't high enough to reach the destination
   procedure Elevation_Calculation (Initial_Velocity : in Float;
                                    Horizontal_Distance : in Float;
                                    Vertical_Distance : in Float;
                                    Success : out Boolean;
                                    Elevation : out Float;
                                    Low_El : in Float := 0.0;
                                    High_El : in Float := Ada.Numerics.Pi / 2.0;
                                    Accuracy_Eps : in Float := 0.1; -- precision on theta radians
                                    Vertical_Tolerance : in Float := 10.0;
                                    High_Quadrant : in Boolean := True);
   function Get_Horizontal_Distance (Target_Easting, Target_Northing, Source_Easting, Source_Northing : Float) return Float;


end Pbm.Parabolic_Motion;
