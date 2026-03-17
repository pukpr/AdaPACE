package Gis.TDB is

   ---------------------------------------------------------
   -- Higher Level Interface
   ---------------------------------------------------------
   pragma Elaborate_Body;

   function Is_Using_TDB return Boolean;
   
   procedure Place_Vehicle
     (U                      : in UTM_Coordinate;
      Length, Width, Heading : in Float;
      Elevation              : out Float;
      Pitch, Roll            : out Float;
      Viscosity              : out Float);        -- Based on soil type

   procedure UTM  -- Returns lower left of data 
     (Latitude, Longitude : in Long_Float;
      SW_UTM, UTM         : out UTM_Coordinate);


end Gis.TDB;
 
