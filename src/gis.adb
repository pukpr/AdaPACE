with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Long_Elementary_Functions;

package body Gis is

   function To_String (Coordinate : Utm_Coordinate) return String is
   begin
      return ("Zone_Num : " & Coordinate.Zone_Num'Img &
              " Hemisphere : " & Coordinate.Hemisphere'Img &
              " Northing : " & Coordinate.Northing'Img &
              " easting : " & Coordinate.Easting'Img);
   end To_String;

   function Distance (C1, C2 : Utm_Coordinate) return Float is
      use Ada.Numerics.Elementary_Functions;
   begin
      return Sqrt ((C1.Northing - C2.Northing) * (C1.Northing - C2.Northing) +
                   (C1.Easting - C2.Easting) * (C1.Easting - C2.Easting));
   end Distance;


   Tenths_Arcsec_2_Radians : constant := 0.000000484813681109535;
   Wgs84_Es : constant := 0.00669437999013; -- Eccentricity squared
   Wgs84_Eer : constant :=      6378137.0; -- Ellipsoid equatorial radius (semi-major axis)

   procedure Wgs84_To_Cartesian (Latitude, Longitude, Altitude : in Long_Float;
                                 X, Y, Z : out Long_Float) is
      Coslat, Sinlat : Long_Float;
      N : Long_Float;                  -- radius of vertical in prime meridian
      use Ada.Numerics.Long_Elementary_Functions;
   begin

      Coslat := Cos (Latitude);
      Sinlat := Sin (Latitude);

      N := Wgs84_Eer / Sqrt (1.0 - Wgs84_Es * Sinlat * Sinlat);

      X := (N + Altitude) * Coslat * Cos (Longitude);
      Y := (N + Altitude) * Coslat * Sin (Longitude);
      Z := (N * (1.0 - Wgs84_Es) + Altitude) * Sinlat;

   end Wgs84_To_Cartesian;

   function Heading_C2_From_C1 (C1 : Utm_Coordinate; C2 : Utm_Coordinate) return Float is
      use Ada.Numerics;
      use Ada.Numerics.Elementary_Functions;
      Hypotenuse : Float := Distance (C1, C2);
      Theta : Float;
      Target_Heading : Float;
   begin
      if Hypotenuse = 0.0 then
         Target_Heading := 0.0;
      else
         Theta := Arccos (abs (C2.Northing - C1.Northing) / Hypotenuse);
         -- determine how to use theta.. differs by quadrant (vehicle is origin)
         if C2.Northing > C1.Northing then
            if C2.Easting >= C1.Easting then
               -- inside first quadrant
               Target_Heading := Theta;
            else
               -- inside second quadrant
               Target_Heading := -Theta;
            end if;
         else
            if C2.Easting >= C1.Easting then
               -- inside fourth quadrant
               Target_Heading := Pi - Theta;
            else
               -- inside third quadrant
               Target_Heading := -Pi + Theta;
            end if;
         end if;
      end if;
      return Target_Heading;
   end Heading_C2_From_C1;


end Gis;
