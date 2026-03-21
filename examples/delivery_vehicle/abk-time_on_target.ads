with Gis;
with Pace;

package Abk.Time_On_Target is

   pragma Elaborate_Body;

   -- a time on target solution for a single item
   type Tot_Solution is
      record
         Velocity : Float;  -- m/s
         Theta : Float;  --radians
         Time_Of_Flight : Duration; -- s
      end record;

   type Float_Arr is array (Integer range <>) of Float;
   type Coord_Arr is array (Integer range <>) of Gis.Utm_Coordinate;
   type Sol_Arr is array (Integer range <>) of Tot_Solution;

   -- Finds a Time On Target solution given the input and returns the solution
   -- including the velocity, elevation, and time of flight for each item.
   -- When there are multiple solutions will return the one which minimizes
   -- time of flight... ie. the speediest solution
   -- Constraints to solution are a min and max elevation angle, and
   -- a Delta_Time_Constraint which is the amount of time that must be between
   -- each item in the solution.
   type Find_Tot_Solution (Num_Items : Positive; Num_Velocities : Positive) is new Pace.Msg with
      record
         -- inputs
         -- the altitudes for each location will be determined from ctdb or queried from the ve
         Target_Locations : Coord_Arr (1 .. Num_Items);
         Possible_Velocities : Float_Arr (1 .. Num_Velocities);  -- m/s
         -- this is the amount of time that must be between each item in the solution
         Delta_Time_Constraint : Duration; -- seconds
         -- the minimum elevation angle
         Min_Theta_Constraint : Float;  -- radians
         -- the maximum elevation angle
         Max_Theta_Constraint : Float;  -- radians

         -- outputs
         -- true if there is a solution that satisfies the constraints, otherwise false
         Success : Boolean;
         Solution : Sol_Arr (1 .. Num_Items);
      end record;
   procedure Inout (Obj : in out Find_Tot_Solution);

end Abk.Time_On_Target;
