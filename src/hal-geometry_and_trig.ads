
package Hal.Geometry_And_Trig is

   pragma Elaborate_Body;

   --------------------------------------------------------------
   -- Geometry and Trig functions
   --------------------------------------------------------------

   -- represents a point on a plane
   type Two_D_Point is
      record
         X : Float;
         Y : Float;
      end record;

   -- represents a point in spherical coordinates
   type Spherical_Position is
      record
         R : Float;  -- distance from origin to the point on x-y plane
         Theta : Float; -- polar coordinate in radians!
         Z : Float; -- distance from x-y plane to the point
      end record;

   -- return distance between two points.. if want 2 dimensions just
   -- have one of the dimensions have values of zero or use the next one
   -- below
   function Distance_Between_Points (P1, P2 : Hal.Position) return Float;

   -- return distance between two points in 2 dimensions
   function Distance_Between_Points (P1, P2 : Two_D_Point) return Float;

   -- Given a triangle defined by points A, B, and C, returns the angle
   -- at point C
   function Law_Of_Cosines (A, B, C : Hal.Position) return Float;

   -- Given a triangle defined by distances A, B, and C, returns the angle
   -- across from side C in radians
   function Law_Of_Cosines (A, B, C : Float) return Float;

   -- Intersection of a line with a sphere or circle
   -- http://astronomy.swin.edu/au/~pbourke/geometry/sphereline/
   -- P1 and P2 define the line
   -- P3 is center of sphere and Radius is radius of sphere
   -- Num_Intersections may be 0, 1, or 2.
   -- Result1 will be set if Num_Intersections is 1 or 2
   -- Result2 will be set if Num_Intersections is 2
   -- If you want the intersection of a line with a circle then for
   -- the unwanted dimension just have P1, P2, and P3 have a value of 0.
   procedure Line_Intersect_Sphere (P1, P2, P3 : in Hal.Position;
                                    Radius : in Float;
                                    Num_Intersections : out Integer;
                                    Result1, Result2 : out Hal.Position);


   -- the various ways that two circles can intersect.  The circles may
   -- be completely separate, or one circle could be inside the other.
   type Cc_Intersect is (One, Two, Separated, Inside);

   -- Intersection of a circle with a circle on the same plane
   -- http://astronomy.swin.edu/au/~pbourke/geometry/2circle/
   -- Center_0 and Radius_0 describe one circle and
   -- Center_1 and Radius_1 describe the other circle
   -- Intersect_Type is returned as well as Result1 and Result2 which
   -- are the intersection points.
   procedure Circle_Intersect_Circle (Center_0 : in Two_D_Point;
                                      Radius_0 : in Float;
                                      Center_1 : in Two_D_Point;
                                      Radius_1 : in Float;
                                      Intersect_Type : out Cc_Intersect;
                                      Result1 : out Two_D_Point;
                                      Result2 : out Two_D_Point);

   function Cartesian_To_Spherical_Conversion
              (Cartesian_Point : in Hal.Position) return Spherical_Position;


   -- Last point of polygon assumed to connect to first point
   type Polygon is array (Positive range <>) of Two_D_Point;
   function Is_Inside (X, Y : in Float; P : in Polygon) return Boolean;


   procedure Cartesian_To_Polar_Conversion
              (Cartesian_Point : in Hal.Position;
               Radius, Theta, Phi : out Float);


   -- LP1 and LP2 define the line
   -- Pt defines the point
   -- Distance is the minimum distance between Pt and the line represented by Lp1 and Lp2
   -- Intersection_Point is the point at which Pt and this distance intersect the line
   -- Returns a negative distance if Lp1 and Lp2 are coincident
   procedure Minimum_Distance_Between_Point_And_Line (Lp1 : Two_D_Point;
                                                      Lp2 : Two_D_Point;
                                                      Pt : Two_D_Point;
                                                      Distance : out Float;
                                                      Intersection_Point : out Two_D_Point);

end Hal.Geometry_And_Trig;
