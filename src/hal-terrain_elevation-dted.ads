package Hal.Terrain_Elevation.DTED is

   procedure Get_Terrain_Data
     (Easting, Northing : in Float;
      Zone_Number       : in Integer;
      Zone_Letter       : in Character; -- Hemisphere
      Heading           : in Float;
      Altitude          : out Float;
      Pitch, Roll       : out Float);

   function Get_Altitude
     (Easting, Northing : in Float;
      Zone_Number       : in Integer;
      Zone_Letter       : in Character)
      return              Float;

   procedure UTM  -- Returns lower left of data 
     (Latitude, Longitude : in Long_Float;
      SW_East, SW_North   : out Float;
      Easting, Northing   : out Float;
      Zone_Number         : out Integer;
      Hemisphere          : out Character);

end Hal.Terrain_Elevation.DTED;
