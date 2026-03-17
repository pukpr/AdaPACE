with Pace.Notify;
with Hal;
with Gkb;
with Mob.Vehicle;

generic

   -- the mobility package
   with package Mobility is new Mob.Vehicle (<>);

   with package Kb is new Gkb (<>);
   -- At runtime, Kb must have matches for the following :
   -- northing (N).
   -- easting (E).
   -- zone (Z).
   -- hemisphere (H).
   -- southwest_easting (E).
   -- southwest_northing (N).
package Gis.Location is

   pragma Elaborate_Body;

   -- Interfaces to world positioning and time

   -- transforms a given easting and northing according to southwest location of the map
   -- Y (or altitude) will be set to 0
   function Get_Pos_From_Sw_Corner (Easting : Float; Northing : Float) return Hal.Position;

   -- returns a vehicles position north and east of the southwest location
   -- of the map
   function Get_Vehicle_Pos_From_Sw_Corner return Hal.Position;

   function Get_Sw_Corner_Easting return Float;

   function Get_Sw_Corner_Northing return Float;

   -- Returns true if an alternate terrain database is being used
   function Is_Using_Tdb return Boolean;

   type Init is new Pace.Msg with null record;
   procedure Input (Obj : in Init);

   type Get_Data is new Pace.Msg with record
      Coordinate : Utm_Coordinate;
      Altitude   : Float;
      Heading    : Float;  -- North is zero, then CW
      Speed      : Float;
      Pitch      : Float; -- radians
      Roll       : Float; -- radians
      Latitude   : Long_Float;
      Longitude  : Long_Float;
      Odometer   : Float;
   end record;
   procedure Output (Obj : out Get_Data);

   function Get_Location return Utm_Coordinate;

   type Track_Heading is new Pace.Msg with record
      Target_Easting  : Float; -- input desired target
      Target_Northing : Float;
      --
      -- Computation involves actual vehicle location and heading
      --
      Heading : Float; -- output compass direction
      -- absolute value (positive) of angle between target location and
      -- current location/heading.. so not a compass direction as above
      Heading_Difference : Float;
      Distance           : Float; -- distance to target
      Time               : Duration; -- time to target
   end record;
   procedure Inout (Obj : in out Track_Heading);

   type Relocate is new Pace.Msg with record
      Easting  : Float; -- input
      Northing : Float; -- input
      Heading  : Float; -- radians
      Success  : Boolean;  -- output
   end record;
   procedure Inout (Obj : in out Relocate);

   procedure Set_Vehicle_Location_From_LL (Latitude : in Long_Float;
                                          Longitude : in Long_Float);

   type Vehicle_Initialized is new Pace.Notify.Subscription with null record;

private
   pragma Inline (Inout);
end Gis.Location;
