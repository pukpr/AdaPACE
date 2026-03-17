package Gis is
   -- Geographical Information Systems
   pragma Pure;

   type Hemisphere_Type is (North, South);
   Hemi_Code : constant array (Hemisphere_Type) of Character := (North => 'N',
                                                                 South => 'S');

   -- the Zone_Letter that sometimes accompanies a UTM zone is essentially useless
   -- since Northing is measured from the equator.  Instead, we need to know the hemisphere.
   type Utm_Coordinate is
      record
         Northing, Easting : Float := 0.0;
         Zone_Num : Integer range 0 .. 60 := 0;
         Hemisphere : Hemisphere_Type := North;
      end record;

   function To_String (Coordinate : Utm_Coordinate) return String;
   function Distance (C1, C2 : Utm_Coordinate) return Float;

   -- types of checkpoints
   type Checkpoint_Type is (Sp, -- Start point
                            Cp, -- Check point
                            Wp, -- Way point
                            Rp, -- Release point
                            Tp);-- Target point

   type Checkpoint is
      record
         Kind : Checkpoint_Type := Cp;
         Coord : Utm_Coordinate;
         Time : Duration;
      end record;

   procedure Wgs84_To_Cartesian (Latitude, Longitude,
                                 Altitude : in Long_Float;
                                 X, Y, Z : out Long_Float); -- Geocentric Coordinates

   -- returns the absolute direction that coordinate c2 is in relation to coordinate c1,
   -- with north being 0, east being Pi/2, south being Pi or -Pi, and west being -Pi/2
   -- doesn't work across utm zones/hemispheres
   function Heading_C2_From_C1 (C1 : Utm_Coordinate; C2 : Utm_Coordinate) return Float;

   -- $Id

end Gis;
