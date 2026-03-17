with Pace.Command_Line;

package Gis.CTDB is

   ---------------------------------------------------------
   -- Higher Level Interface
   ---------------------------------------------------------
   pragma Elaborate_Body;

   Is_Using_CTDB_World : Boolean := Pace.Command_Line.Has_Argument ("-tdbtype");

   No_CTDB_Found : exception;
   
   procedure Place_Vehicle  -- Either flavour of CTDB
     (U                      : in UTM_Coordinate; -- If using World coordinates
      X, Y                   : in Long_Float;     -- If not using World
      Length, Width, Heading : in Float;
      Elevation              : out Float;
      Pitch, Roll            : out Float;
      Viscosity              : out Float);        -- Based on soil type


   procedure UTM  -- Returns lower left of data 
     (Latitude, Longitude : in Long_Float;        -- Required if World
      SW_UTM, UTM         : out UTM_Coordinate);


end Gis.CTDB;
 
