with Ada.Numerics.Elementary_Functions;
with Pace.Log;

package body Hal.Geometry_And_Trig is

   use Ada.Numerics.Elementary_Functions;

   function Distance_Between_Points (P1, P2 : Hal.Position) return Float is
   begin
      -- abs necessary due to way ** works
      return Sqrt ((abs (P1.X - P2.X)) ** 2 + (abs (P1.Y - P2.Y)) ** 2 +
                   (abs (P1.Z - P2.Z)) ** 2);
   end Distance_Between_Points;

   function Distance_Between_Points (P1, P2 : Two_D_Point) return Float is
   begin
      -- abs necessary due to way ** works
      return Sqrt ((abs (P1.X - P2.X)) ** 2 + (abs (P1.Y - P2.Y)) ** 2);
   end Distance_Between_Points;

   function Law_Of_Cosines (A, B, C : Hal.Position) return Float is
   begin
      return Law_Of_Cosines (A => Distance_Between_Points (A, C),
                             B => Distance_Between_Points (B, C),
                             C => Distance_Between_Points (A, B));
   end Law_Of_Cosines;

   function Law_Of_Cosines (A, B, C : Float) return Float is
   begin
      return Arccos ((-C * C + A * A + B * B) / (2.0 * A * B));
   end Law_Of_Cosines;


   -- see spec for comments
   procedure Line_Intersect_Sphere (P1, P2, P3 : in Hal.Position;
                                    Radius : in Float;
                                    Num_Intersections : out Integer;
                                    Result1, Result2 : out Hal.Position) is

      function Point_Calc (N1, N2, U : Float) return Float is
      begin
         return N1 + U * (N2 - N1);
      end Point_Calc;

      C : Float;
      B : Float;
      A : Float;
      -- the two quadratic values
      Inside_Sqrt : Float;
      U1 : Float;
      U2 : Float;
   begin
      Pace.Log.Put_Line ("P1.Y is " & Float'Image (P1.Y), 8);
      Pace.Log.Put_Line ("P2.Y is " & Float'Image (P2.Y), 8);

      C := P3.X * P3.X + P3.Y * P3.Y + P3.Z * P3.Z +
        P1.Y * P1.Y + P1.Z * P1.Z + P1.X * P1.X -
        2.0 * (P3.X * P1.X + P3.Y * P1.Y + P3.Z * P1.Z) - Radius ** 2;

      Pace.Log.Put_Line ("C is " & Float'Image (C), 8);

      B := 2.0 * ((P2.X - P1.X) * (P1.X - P3.Y) +
                  (P2.Y - P1.Y) * (P1.Y - P3.Y) +
                  (P2.Z - P1.Z) * (P1.Z - P3.Z));

      Pace.Log.Put_Line ("B is " & Float'Image (B), 8);

      A := (P2.X - P1.X) * (P2.X - P1.X) + (P2.Y - P1.Y) * (P2.Y - P1.Y) +
        (P2.Z - P1.Z) * (P2.Z - P1.Z);

      Pace.Log.Put_Line ("A is " & Float'Image (A), 8);

      Inside_Sqrt := B * B - 4.0 * A * C;
      if Inside_Sqrt < 0.0 then
         Num_Intersections := 0;
      elsif Inside_Sqrt = 0.0 then
         Num_Intersections := 1;
         U1 := -B / (2.0 * A);
         Result1.X := Point_Calc (P1.X, P2.X, U1);
         Result1.Y := Point_Calc (P1.Y, P2.Y, U1);
         Result1.Z := Point_Calc (P1.Z, P2.Z, U1);
      else
         Num_Intersections := 2;
         U1 := (-B + Sqrt (Inside_Sqrt)) / (2.0 * A);
         U2 := (-B - Sqrt (Inside_Sqrt)) / (2.0 * A);
         Result1.X := Point_Calc (P1.X, P2.X, U1);
         Result1.Y := Point_Calc (P1.Y, P2.Y, U1);
         Result1.Z := Point_Calc (P1.Z, P2.Z, U1);
         Result2.X := Point_Calc (P1.X, P2.X, U2);
         Result2.Y := Point_Calc (P1.Y, P2.Y, U2);
         Result2.Z := Point_Calc (P1.Z, P2.Z, U2);
      end if;
   end Line_Intersect_Sphere;


   -- see spec for comments
   procedure Circle_Intersect_Circle (Center_0 : in Two_D_Point;
                                      Radius_0 : in Float;
                                      Center_1 : in Two_D_Point;
                                      Radius_1 : in Float;
                                      Intersect_Type : out Cc_Intersect;
                                      Result1 : out Two_D_Point;
                                      Result2 : out Two_D_Point) is
      Dist_Between_Centers : Float :=
        Distance_Between_Points (Center_0, Center_1);
      A, H : Float;
      P2 : Two_D_Point;
   begin
      if Dist_Between_Centers > Radius_0 + Radius_1 then
         Intersect_Type := Separated;
      elsif Dist_Between_Centers < abs (Radius_0 - Radius_1) then
         Intersect_Type := Inside;
      else
         A := (Radius_0 ** 2 - Radius_1 ** 2 + Dist_Between_Centers ** 2) /
           (2.0 * Dist_Between_Centers);
         H := Sqrt (Radius_0 ** 2 - A * A);
         P2.X := Center_0.X + A * (Center_1.X - Center_0.X) /
           Dist_Between_Centers;
         P2.Y := Center_0.Y + A * (Center_1.Y - Center_0.Y) /
           Dist_Between_Centers;

         if Dist_Between_Centers = Radius_0 + Radius_1 then
            Intersect_Type := One;
            Result1.X := P2.X;
            Result1.Y := P2.Y;
         else
            Intersect_Type := Two;
            Result1.X := P2.X + H * (Center_1.Y - Center_0.Y) /
              Dist_Between_Centers;
            Result1.Y := P2.Y - H * (Center_1.X - Center_0.X) /
              Dist_Between_Centers;
            Result2.X := P2.X - H * (Center_1.Y - Center_0.Y) /
              Dist_Between_Centers;
            Result2.Y := P2.Y + H * (Center_1.X - Center_0.X) /
              Dist_Between_Centers;
         end if;
      end if;
   end Circle_Intersect_Circle;

   function Cartesian_To_Spherical_Conversion
     (Cartesian_Point : in Hal.Position) return Spherical_Position is
      Result : Spherical_Position;
   begin
      Result.Z := Cartesian_Point.Z;
      -- should this be arctan2(Cartesian_Point.Y, Cartesian_Point.X)
      Result.Theta := Arctan (Cartesian_Point.Y / Cartesian_Point.X);
      Result.R := Sqrt (Cartesian_Point.X * Cartesian_Point.X +
                        Cartesian_Point.Y * Cartesian_Point.Y);
      return Result;
   end Cartesian_To_Spherical_Conversion;


   procedure Cartesian_To_Polar_Conversion
     (Cartesian_Point : in Hal.Position;
      Radius, Theta, Phi : out Float) is
      R : Float;
   begin
      if Cartesian_Point.X = 0.0 and Cartesian_Point.Y = 0.0 and Cartesian_Point.Z = 0.0 then
         Radius := 0.0;
         Theta := 0.0;
         Phi := 0.0;
         return;
      end if;

      Phi := Arctan (X => Cartesian_Point.X, Y => Cartesian_Point.Y);
      R := Cartesian_Point.X * Cartesian_Point.X +
        Cartesian_Point.Y * Cartesian_Point.Y;
      Radius := Sqrt (R +
                      Cartesian_Point.Z * Cartesian_Point.Z);
      Theta := Arctan (X => Sqrt (R), Y => Cartesian_Point.Z);

      --     Phi := Arctan (Cartesian_Point.X, Cartesian_Point.Z);
      --     R := Cartesian_Point.X * Cartesian_Point.X +
      --          Cartesian_Point.Z * Cartesian_Point.Z;
      --     Radius := Sqrt (R +
      --                     Cartesian_Point.Y * Cartesian_Point.Y);
      --     Theta := Arctan (Cartesian_Point.Y, Sqrt (R));
   end;


   --    function Polar_To_Euler (Theta, Phi : Float) return Hal.Orientation is
   --      Z : constant Float := Cos(Phi); -- X -> Z
   --      X : constant Float := Sin(Phi); -- Y -> X
   --      A : constant Float := 0.0;
   --      B : constant Float := -Arctan(Z,X); -- Arctan(X,Y) -> arctan(Z,X)
   --      C : constant Float := Theta; -- Arctan(Y,P); -- Arctan(Z,P) -> arctan(Y,P)
   --    begin
   --      return Hal.Orientation'(A,B,C);
   --    end;

   function Polar_To_Euler (Theta, Phi : Float) return Hal.Orientation is
      A : constant Float := Phi;
      B : constant Float := Theta; -- Arctan(X,Y) -> arctan(Z,X)
      C : constant Float := 0.0; -- Arctan(Y,P); -- Arctan(Z,P) -> arctan(Y,P)
   begin
      return Hal.Orientation'(A,B,C);
   end;


   function Is_Inside (X, Y : in Float; P : in Polygon) return Boolean is
      use Ada.Numerics;
      Pi2 : constant := 2.0 * Pi;
      Tol : constant Float := 4.0 * Float'Epsilon * Pi;
      Sum : Float := 0.0;
      Theta, Theta1, Thetai : Float;

      procedure Sum_Difference_From_Angle (Next_Theta : in Float) is
         Angle : Float := abs (Next_Theta - Theta);
      begin
         if Angle > Pi then
            Angle := Angle - Pi2;
         end if;
         if Theta > Next_Theta then
            Angle := -Angle;
         end if;
         Sum := Sum + Angle;
      end Sum_Difference_From_Angle;
   begin
      Theta1 := Arctan (P (1).X - X, P (1).Y - Y);
      Theta := Theta1;
      for I in 2 .. P'Last loop
         Thetai := Arctan (P (I).X - X, P (I).Y - Y);
         Sum_Difference_From_Angle (Thetai);
         Theta := Thetai;
      end loop;
      Sum_Difference_From_Angle (Theta1);
      Pace.Log.Put_Line (Float'Image (Sum / Pi2), 8);
      -- Returns value close to 0.0 if outside and value close to +-1.0 if inside.
      -- To make sure the 1.0 value when truncated does not go to 0.0, we add 0.2.
      return Integer (abs (Sum) / Pi2 + 0.2) /= 0;
   end Is_Inside;


   -- Calculate according to http://astronomy.swin.edu.au/~pbourke/geometry/pointline/
   procedure Minimum_Distance_Between_Point_And_Line (Lp1 : Two_D_Point;
                                                      Lp2 : Two_D_Point;
                                                      Pt : Two_D_Point;
                                                      Distance : out Float;
                                                      Intersection_Point : out Two_D_Point) is
      U_Denominator : Float := ((Lp2.Y - Lp1.Y)*(Lp2.Y - Lp1.Y) + (Lp2.X - Lp1.X)*(Lp2.X - Lp1.X));
   begin
      if U_Denominator = 0.0 then
         Distance := -1.0;
      else
         declare
            U : Float := ((Pt.X - Lp1.X)*(Lp2.X - Lp1.X) + (Pt.Y - Lp1.Y)*(Lp2.Y - Lp1.Y)) /
              U_Denominator;
         begin
            Intersection_Point.X := Lp1.X + U * (Lp2.X - Lp1.X);
            Intersection_Point.Y := Lp1.Y + U * (Lp2.Y - Lp1.Y);
            Distance := Distance_Between_Points (Intersection_Point, Pt);
         end;
      end if;
   end Minimum_Distance_Between_Point_And_Line;

end Hal.Geometry_And_Trig;
