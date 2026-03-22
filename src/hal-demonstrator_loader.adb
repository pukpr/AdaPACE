with Pace;
with Pace.Log;
with Hal.Geometry_And_Trig;
with Hal.Sms;
with Hal.Sms_Lib.Morph;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Hal.Demonstrator_Loader is

   use Ada.Numerics.Elementary_Functions;
   use Hal;

   -- there are three different locations that a wheel can be at
   -- Straight_Vert : the initial 90 degree straight portion
   -- Curved : on the curved portion
   -- Straight_Elev : the straight portion at same angle as the elevation arm
   type Where_At is (Straight_Vert, Curved, Straight_Elev);


   -- the following parameters come in through the generic type .. see spec
   --    Track_Radius : Float;
   --    Liftbox_Velocity : Float;
   --    Center_Point_Z : Float;
   --    Center_Point_Y_At_Zero_Theta : Float;
   --    Distance_Between_Wheels : Float;
   --    Loader_Assembly : Bounded_String;
   --    Arm1_Assembly : Bounded_String;
   --    Arm2_Assembly : Bounded_String;
   --    Liftbox_Assembly : Bounded_String;
   --    Rear_Pos_Standoff : Hal.Position;
   --    Endpoint_Constant_N : Float;
   --    Endpoint_Constant_M : Float;


   --------------------------- constants ------------------------------
   -- change in time each iteration of loop
   Delta_T : constant Float := 0.05;
   -- change in distance each iteration of loop
   Delta_D : constant Float := Liftbox_Velocity * Delta_T;
   Front_Pos_Standoff : constant Hal.Position :=
     (0.0, Rear_Pos_Standoff.Y + Distance_Between_Wheels, Rear_Pos_Standoff.Z);
   -- the boundary values at which the loader can rise to or lower from
   Max_Theta : constant Float := Hal.Rads (75.0);
   -- 0.0 degrees has problems..
   Min_Theta : constant Float := Hal.Rads (0.001);
   -- arm lengths
   Arm1_Length : constant Float := 0.375;
   Arm2_Length : constant Float := 0.440053;
   Lift_Box_Standoff : constant Hal.Position := (0.0, -1.4579, 0.3612);
   -- this is used in the calculation to determine the line that must be
   -- followed by the loader when in the Str_Elev position (on the raised
   -- elevation portion of track).. note it is equivalent to the y value of
   -- tangent point 2 when theta is zero, which works down to being...
   Dist_Trunnion_To_Str_Elev_Line : constant Float :=
     abs (Track_Radius - Center_Point_Y_At_Zero_Theta);



   -------------------------- variables --------------------------------
   Theta : Float; -- elevation angle in radians
   -- the lower tangent point
   Tangent_Point_One : Position;
   -- the upper tangent point
   Tangent_Point_Two : Position;

   -- the point at which the rear wheel is at when the front wheel is
   -- at Tangent_Point_One
   Tangent_Point_One_Rear : Position;
   -- the point at which the rear wheel is at when the front wheel is
   -- at Tangent_Point_Two
   Tangent_Point_Two_Rear : Position;

   -- the stopping point.. or where the endpoint is at
   Endpoint_Point : Position;

   -- it is the x-axis that rotates and it starts in the vertical lowered
   -- position at 0 degrees... which means when the elevation is at a
   -- 0 degree angle, the loader has an orientation of 90 degrees
   Current_Orn : Hal.Orientation := (0.0, 0.0, 0.0);
   Rear_Pos : Hal.Position := Rear_Pos_Standoff;
   Front_Pos : Hal.Position := Front_Pos_Standoff;
   Lift_Box_Pos : Hal.Position := Lift_Box_Standoff;
   Arm1_Alpha : Float := 20.0;
   Arm2_Alpha : Float := -40.5725;
   Arms_Intersection_Pos : Hal.Position := (0.0, 0.0, 0.0);


   procedure Print_Pos (Pos : Hal.Position) is
   begin
      Pace.Log.Put_Line ("->(" & Float'Image (Pos.X) &
                         ", " & Float'Image (Pos.Y) &
                         ", " & Float'Image (Pos.Z) & ")", 8);
   end Print_Pos;

   procedure Distance_Calc is
      D : Float := Hal.Geometry_And_Trig.Distance_Between_Points
                     (Front_Pos, Rear_Pos);
   begin
      Pace.Log.Put_Line ("the distance between wheels is " & Float'Image (D));
   end Distance_Calc;


   -- depends on Front_Pos and Rear_Pos
   function Calculate_Orientation return Float is
   begin
      if Front_Pos.Y <= Rear_Pos.Y then
         return 0.0;
      else
         return Arctan ((Front_Pos.Z - Rear_Pos.Z) /
                        (Front_Pos.Y - Rear_Pos.Y));
      end if;
   end Calculate_Orientation;


   procedure Set_Endpoint_Point is
   begin
      Endpoint_Point.X := 0.0;
      Endpoint_Point.Y := -Dist_Trunnion_To_Str_Elev_Line * Cos (Theta) +
                          Endpoint_Z_Stopping_Point * Sin (Theta);
      Endpoint_Point.Z := Dist_Trunnion_To_Str_Elev_Line * Sin (Theta) +
                          Endpoint_Z_Stopping_Point * Cos (Theta);
      Pace.Log.Put_Line ("endpoint:", 8);
      Print_Pos (Endpoint_Point); -- removed pragma debug
   end Set_Endpoint_Point;

   procedure Set_Tangent_Points is
      -- these constants are derived from the model
      W : constant Float := 0.1021;
   begin
      Tangent_Point_One.X := 0.0;
      Tangent_Point_One.Y := Center_Point_Z * Tan (Theta) -
                               Center_Point_Y_At_Zero_Theta / (Cos (Theta));
      Tangent_Point_One.Z := W;

      Tangent_Point_One_Rear.X := Tangent_Point_One.X;
      Tangent_Point_One_Rear.Y := Tangent_Point_One.Y - Distance_Between_Wheels;
      Tangent_Point_One_Rear.Z := Tangent_Point_One.Z;

      Tangent_Point_Two.X := 0.0;
      Tangent_Point_Two.Y := Tangent_Point_One.Y + Track_Radius * Cos (Theta);
      Tangent_Point_Two.Z := Center_Point_Z - Track_Radius * Sin (Theta);

      Tangent_Point_Two_Rear.X := 0.0;
      Tangent_Point_Two_Rear.Y := Tangent_Point_Two.Y -
                                    Sqrt (Distance_Between_Wheels ** 2 -
                                          (Tangent_Point_Two.Z - W) ** 2);
      Tangent_Point_Two_Rear.Z := W;
      Pace.Log.Put_Line ("tangent point one:", 8);
      Print_Pos (Tangent_Point_One);
      Pace.Log.Put_Line ("tangent point two:", 8);
      Print_Pos (Tangent_Point_Two);
   end Set_Tangent_Points;


   -- return true if time to stop raising else false
   function At_The_Endpoint return Boolean is
   begin
      if Front_Pos.Y >= Endpoint_Point.Y and Front_Pos.Z >= Endpoint_Point.Z then
         return True;
      else
         return False;
      end if;
   end At_The_Endpoint;

   -- return true if time to stop lowering, else false
   function At_The_Bottom return Boolean is
   begin
      if Lift_Box_Pos.Y <= Lift_Box_Standoff.Y then
         return True;
      else
         return False;
      end if;
   end At_The_Bottom;


   function Where_Is_Wheel (Wheel_Pos : Position) return Where_At is
      Result : Where_At;
   begin

      -- check for Straight_Elev
      -- using Z here and Y at the next spot is necessary
      if Wheel_Pos.Z >= Tangent_Point_Two.Z then
         Result := Straight_Elev;
      elsif Wheel_Pos.Y < Tangent_Point_One.Y then -- check for Straight_Vert
         Result := Straight_Vert;
      else
         Result := Curved;
      end if;

      return Result;
   end Where_Is_Wheel;

   -- Either increments or decrements Num by Delta_Num depending on
   -- the boolean Increment_It
   procedure Inc_Or_Dec_Num (Num : in out Float;
                             Delta_Num : in Float;
                             Increment_It : Boolean) is
   begin
      if Increment_It then
         Num := Num + Delta_Num;
      else
         Num := Num - Delta_Num;
      end if;
   end Inc_Or_Dec_Num;

   -- returns two points which define the line on the Str_Elev section
   -- for the current theta
   procedure Get_Str_Elev_Line (P1, P2 : out Hal.Position) is
      Alpha : Float := -Theta;
      function Calculate_Y (Z : Float) return Float is
      begin
         Pace.Log.Put_Line
           ("str_elev_line y value is " &
            Float'Image (-Z * Tan (Alpha) -
                         Dist_Trunnion_To_Str_Elev_Line / Cos (Alpha)));
         return -Z * Tan (Alpha) - Dist_Trunnion_To_Str_Elev_Line / Cos (Alpha);
      end Calculate_Y;

   begin
      P1.X := 0.0;
      P1.Z := 0.0;
      P1.Y := Calculate_Y (P1.Z);

      P2.X := 0.0;
      P2.Z := 0.200;
      P2.Y := Calculate_Y (P2.Z);
   end Get_Str_Elev_Line;

   -- Rear_Pos must be set already
   procedure Adjust_Front_Wheel_For_Str_Vert (Is_Rising : in Boolean) is
   begin
      Front_Pos.Y := Rear_Pos.Y + Distance_Between_Wheels;
   end Adjust_Front_Wheel_For_Str_Vert;

   procedure Adjust_Front_Wheel_For_Str_Elev is
   begin
      Front_Pos.Y := Rear_Pos.Y + Distance_Between_Wheels * Sin (Theta);
      Front_Pos.Z := Rear_Pos.Z + Distance_Between_Wheels * Cos (Theta);
   end Adjust_Front_Wheel_For_Str_Elev;

   -- this is how the front wheel position is calculated when the
   -- front wheel is on the curved section.. by doing an intersection
   -- of two circles.. one circle being centered at the rear wheel with
   -- a radius the distance between the wheels and the other circle
   -- being the curve of the track
   procedure Adjust_Front_For_Front_Curved is
      use Hal.Geometry_And_Trig;

      -- represents the center of the track
      Center_0 : Two_D_Point := (X => Center_Point_Z, Y => Tangent_Point_One.Y);

      -- represents the rear wheel location
      Center_1 : Two_D_Point := (X => Rear_Pos.Z, Y => Rear_Pos.Y);
      Intersect_Type : Cc_Intersect;
      Result1, Result2 : Two_D_Point;
   begin
      Circle_Intersect_Circle (Center_0, Track_Radius, Center_1,
                               Distance_Between_Wheels,
                               Intersect_Type, Result1, Result2);
      if Result1.Y > Result2.Y then
         Front_Pos.Y := Result1.Y;
         Front_Pos.Z := Result1.X;
      else
         Front_Pos.Y := Result2.Y;
         Front_Pos.Z := Result2.X;
      end if;
   end Adjust_Front_For_Front_Curved;

   -- this is how the front wheel position is calculated when the
   -- front wheel is on the Straight_Elev section and the rear wheel is
   -- on the Straight_Vert section or when the rear wheel is on the
   -- Curved section.
   -- These calculations are based on the artcle "Intersection of a
   -- Line and a Sphere (or circle)", written by Paul Bourke at
   -- http://astronomy.swin.edu.au/~pbourke/geometry/sphereline/
   procedure Adjust_Front_For_Other is
      P1, P2 : Hal.Position;
      Num_Intersections : Integer;
      Result1, Result2 : Hal.Position;
   begin
      Get_Str_Elev_Line (P1, P2);
      Hal.Geometry_And_Trig.Line_Intersect_Sphere
        (P1, P2, Rear_Pos, Distance_Between_Wheels,
         Num_Intersections, Result1, Result2);
      Pace.Log.Put_Line ("Num_intersections is " &
                         Integer'Image (Num_Intersections));
      if Result1.Y > Result2.Y then
         Front_Pos := Result1;
      else
         Front_Pos := Result2;
      end if;

   end Adjust_Front_For_Other;

   -- Is_Rising if true will add to the current position and
   -- if false will subtract
   -- Returns true if orientation should be modified, otherwise false
   function Adjust_Front_Position (Is_Rising : Boolean) return Boolean is
      Orientation_Should_Change : Boolean := False;
   begin
      if Rear_Pos.Y < Tangent_Point_One_Rear.Y then
         -- both wheels are on the Straight_Vert section
         Adjust_Front_Wheel_For_Str_Vert (Is_Rising);
      elsif Rear_Pos.Y >= Tangent_Point_Two.Y then
         -- both wheels are on the Straight_Elev section
         Pace.Log.Put_Line ("calling Adjust_Front_Wheel_For_Str_Elev", 8);
         Adjust_Front_Wheel_For_Str_Elev;
      elsif Rear_Pos.Y < Tangent_Point_Two_Rear.Y then
         -- front wheel is on the curved section
         Pace.Log.Put_Line ("calling Adjust_Front_For_Front_Curved", 8);
         Adjust_Front_For_Front_Curved;
         Orientation_Should_Change := True;
      else -- if Rear_Curved or Str_Elev_Vert then
         Pace.Log.Put_Line ("calling Adjust_Front_For_Other", 8);
         Adjust_Front_For_Other;
         Orientation_Should_Change := True;
      end if;
      Pace.Log.Put_Line ("front position is: ", 8);
      Print_Pos (Front_Pos);
      pragma Debug (Distance_Calc);
      return Orientation_Should_Change;
   end Adjust_Front_Position;

   -- Find where rear wheel should be for the Str_Vert section
   -- by using the intersection of line and circle approach
   procedure Adjust_Rear_Wheel_For_Str_Vert is
      P1 : Hal.Position := (0.0, 0.0, Rear_Pos_Standoff.Z);
      P2 : Hal.Position := (0.0, -0.2, Rear_Pos_Standoff.Z);
      Num_Intersections : Integer;
      Result1, Result2 : Hal.Position;
   begin
      Pace.Log.Put_Line ("inside RW: for Str_Vert", 8);
      Hal.Geometry_And_Trig.Line_Intersect_Sphere
        (P1, P2, Arms_Intersection_Pos, Arm2_Length,
         Num_Intersections, Result1, Result2);
      -- take the greater one
      if Result1.Y > Result2.Y then
         --Rear_Pos.Y := Result1.Y;
         Rear_Pos := Result1;
      else
         --Rear_Pos.Y := Result2.Y;
         Rear_Pos := Result2;
      end if;
   end Adjust_Rear_Wheel_For_Str_Vert;


   -- Find where rear wheel should be for the Str_Elev section
   -- by using the intersection of line and circle approach
   procedure Adjust_Rear_Wheel_For_Str_Elev is
      P1, P2 : Hal.Position;
      Num_Intersections : Integer;
      Result1, Result2 : Hal.Position;
   begin
      Pace.Log.Put_Line ("inside RW: for Str_Elev", 8);
      Get_Str_Elev_Line (P1, P2);
      Hal.Geometry_And_Trig.Line_Intersect_Sphere
        (P1, P2, Arms_Intersection_Pos, Arm2_Length,
         Num_Intersections, Result1, Result2);
      -- take the greater one
      if Result1.Y > Result2.Y then
         Rear_Pos := Result1;
      else
         Rear_Pos := Result2;
      end if;
   end Adjust_Rear_Wheel_For_Str_Elev;

   -- Find where rear wheel should be for the curved section
   -- by using the intersection of a circle and circle approach
   procedure Adjust_Rear_Wheel_For_Curved is
      use Hal.Geometry_And_Trig;

      -- represents the center of the track
      Center_0 : Two_D_Point := (Center_Point_Z, Tangent_Point_One.Y);

      -- represents the center of the arm pivot axis
      Center_1 : Two_D_Point := (X => Arms_Intersection_Pos.Z,
                                 Y => Arms_Intersection_Pos.Y);

      Intersect_Type : Cc_Intersect;
      Result1, Result2 : Two_D_Point;
   begin
      Pace.Log.Put_Line ("inside RW: for Curved", 8);
      Circle_Intersect_Circle (Center_0, Track_Radius, Center_1, Arm2_Length,
                               Intersect_Type, Result1, Result2);
      Pace.Log.Put_Line ("intersecting type is " & Cc_Intersect'Image (Intersect_Type), 8);
      -- assume two intersections.. choose the greater one
      if Result1.Y > Result2.Y then
         Rear_Pos.Y := Result1.Y;
         Rear_Pos.Z := Result1.X;
      else
         Rear_Pos.Y := Result2.Y;
         Rear_Pos.Z := Result2.X;
      end if;
   end Adjust_Rear_Wheel_For_Curved;


   procedure Adjust_Rear_Position is
   begin
      if Where_Is_Wheel (Rear_Pos) = Straight_Vert then
         Adjust_Rear_Wheel_For_Str_Vert;
      elsif Where_Is_Wheel (Rear_Pos) = Curved then
         Adjust_Rear_Wheel_For_Curved;
      else -- Straight_Elev section
         Adjust_Rear_Wheel_For_Str_Elev;
      end if;
      Pace.Log.Put_Line ("rear position is: ", 8);
      Print_Pos (Rear_Pos);
   end Adjust_Rear_Position;


   procedure Adjust_Arm1 is
   begin
      Arm1_Alpha := (Lift_Box_Pos.Y - Lift_Box_Standoff.Y) * 160.0 + 20.0;

      Arms_Intersection_Pos.Y := Lift_Box_Pos.Y -
                                   Cos (Hal.Rads (Arm1_Alpha)) * Arm1_Length;
      Arms_Intersection_Pos.Z := Lift_Box_Pos.Z -
                                   Sin (Hal.Rads (Arm1_Alpha)) * Arm1_Length;

      Pace.Log.Put_Line ("Arm1_Alpha is", 8);
      Pace.Log.Put_Line (Float'Image (Arm1_Alpha), 8);

      Pace.Log.Put_Line ("Arms_Intersection_Pos is", 8);
      Print_Pos (Arms_Intersection_Pos);
   end Adjust_Arm1;

   -- have three points so do law of cosines to find Arm2_Alpha
   procedure Adjust_Arm2 is
   begin
      Arm2_Alpha := -1.0 * Hal.Degs (Hal.Geometry_And_Trig.Law_Of_Cosines
                                       (A => Rear_Pos,
                                        B => Lift_Box_Pos,
                                        C => Arms_Intersection_Pos));
      Pace.Log.Put_Line ("Arm2_Alpha is " & Float'Image (Arm2_Alpha), 8);
   end Adjust_Arm2;

   -- the lift box moves up at a constant velocity.  so each
   -- time-increment it moves a distance Delta_D
   procedure Adjust_Lift_Box (Is_Rising : Boolean) is
   begin
      Inc_Or_Dec_Num (Lift_Box_Pos.Y, Delta_D, Is_Rising);
      if not Is_Rising then
         if At_The_Bottom then
            Lift_Box_Pos.Y := Lift_Box_Standoff.Y;
         end if;
      end if;
      Pace.Log.Put_Line ("Lift_Box is " & Float'Image (Lift_Box_Pos.Y), 8);
   end Adjust_Lift_Box;


   function Boundary_Condition (Alpha : Float) return Float is
   begin
      if Alpha > Max_Theta then
         Pace.Log.Put_Line ("!!!!! Changing morph loader angle from " &
                            Float'Image (Hal.Degs (Alpha)) & " to " &
                            Float'Image (Hal.Degs (Max_Theta)));
         return Max_Theta;
      elsif Alpha < Min_Theta then
         Pace.Log.Put_Line ("!!!!! Changing morph loader angle from " &
                            Float'Image (Hal.Degs (Alpha)) & " to " &
                            Float'Image (Hal.Degs (Min_Theta)));
         return Min_Theta;
      else
         return Alpha;
      end if;
   end Boundary_Condition;

   procedure Raise_Loader (Elevation : Float) is
      Current_Time : Duration := Pace.Now;
      Orientation_Should_Change : Boolean;
   begin
      Pace.Log.Put_Line ("raising loader to " & Float'Image (Elevation));
      Theta := Boundary_Condition (Hal.Rads (Elevation));
      Set_Endpoint_Point;
      Set_Tangent_Points;

      loop

         Adjust_Lift_Box (Is_Rising => True);
         Adjust_Arm1;

         Adjust_Rear_Position;

         Adjust_Arm2;

         Orientation_Should_Change := Adjust_Front_Position (Is_Rising => True);
         if Orientation_Should_Change then
            Current_Orn.A := Calculate_Orientation;
            Pace.Log.Put_Line ("new orientation is: " & Float'Image (Hal.Degs (Current_Orn.A)), 8);
            Hal.Sms.Set (To_String (Loader_Assembly), Rear_Pos, Current_Orn);
            pragma Debug (Hal.Sms.Set ("axis_front", Front_Pos));
         else
            Hal.Sms.Set (To_String (Loader_Assembly), Rear_Pos);
            pragma Debug (Hal.Sms.Set ("axis_front", Front_Pos));
         end if;
         Hal.Sms.Set (To_String (Liftbox_Assembly), Lift_Box_Pos);
         Hal.Sms.Set (Name => To_String (Arm1_Assembly),
                      Rot => (Hal.Rads (Arm1_Alpha), 0.0, 0.0));
         Hal.Sms.Set (Name => To_String (Arm2_Assembly),
                      Rot => (Hal.Rads (Arm2_Alpha), 0.0, 0.0));

         exit when At_The_Endpoint;
         Current_Time := Current_Time + Duration (Delta_T);
         Pace.Log.Wait_Until (Current_Time);
      end loop;
      Pace.Log.Put_Line ("Done Raising Loader.", 8);
   end Raise_Loader;



   procedure Lower_Loader (Elevation : Float) is
      Current_Time : Duration := Pace.Now;
      Orientation_Should_Change : Boolean;
   begin
      Pace.Log.Put_Line ("lowering loader from " & Float'Image (Elevation));
      Theta := Boundary_Condition (Hal.Rads (Elevation));
      Set_Tangent_Points;

      loop

         Adjust_Lift_Box (Is_Rising => False);
         Adjust_Arm1;

         Adjust_Rear_Position;

         Adjust_Arm2;

         Orientation_Should_Change :=
           Adjust_Front_Position (Is_Rising => False);
         if Orientation_Should_Change then
            Current_Orn.A := Calculate_Orientation;
            Pace.Log.Put_Line ("new orientation is: " & Float'Image (Hal.Degs (Current_Orn.A)), 8);
            Hal.Sms.Set (To_String (Loader_Assembly), Rear_Pos, Current_Orn);
            pragma Debug (Hal.Sms.Set ("axis_front", Front_Pos));
         else
            Hal.Sms.Set (To_String (Loader_Assembly), Rear_Pos);
            pragma Debug (Hal.Sms.Set ("axis_front", Front_Pos));
         end if;
         Hal.Sms.Set (To_String (Liftbox_Assembly), Lift_Box_Pos);
         Hal.Sms.Set (Name => To_String (Arm1_Assembly),
                      Rot => (Hal.Rads (Arm1_Alpha), 0.0, 0.0));
         Hal.Sms.Set (Name => To_String (Arm2_Assembly),
                      Rot => (Hal.Rads (Arm2_Alpha), 0.0, 0.0));

         exit when At_The_Bottom;
         Current_Time := Current_Time + Duration (Delta_T);
         Pace.Log.Wait_Until (Current_Time);
      end loop;

      -- reset wheels and lift box to their standoff/lowered position
      -- to stay consistent
      Rear_Pos := Rear_Pos_Standoff;
      Front_Pos := Front_Pos_Standoff;
      Current_Orn := (0.0, 0.0, 0.0);
      Lift_Box_Pos.Y := Lift_Box_Standoff.Y;
      Lift_Box_Pos.Z := Lift_Box_Standoff.Z;

   end Lower_Loader;

end Hal.Demonstrator_Loader;
