with Pace.Server.Dispatch;
with Pace;
with Gkb;
with Mob.Vehicle;
with Gis.Location;

generic
   -- amount of time to wait between setting pitch, roll, and terrain_elevation
   Delta_Time : Duration;
   with package Mobility is new Mob.Vehicle (<>);
   with package Loc is new Gis.Location (<>);
   with package Kb is new Gkb (<>);
   -- At runtime, Kb must have matches for the following :
   -- ctd_data_file (Name).
   -- easting (Easting).
   -- northing (Northing).
   -- southwest_easting (Easting).
   -- southwest_northing (Northing).
   -- the following is only needed if SSOM_PITCH_ROLL stuff may be used
   -- utm_raw ("center", Lat, Long, N, E).
   -- utm_raw ("se", Lat, Long, N, E).
   -- utm_raw ("sw", Lat, Long, N, E).
   -- utm_raw ("ne", Lat, Long, N, E).
   -- map_name_dted (Name).
   -- map_name_dem (Name).
package Gis.Terrain_Following is

   pragma Elaborate_Body;

   -- This class has an agent which will monitor the vehicle's location and
   -- adjust the pitch and roll values

   -- turns off terrain elevation monitoring
   type Turn_Off_Terrain_Monitoring is new
     Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Turn_Off_Terrain_Monitoring);

   -- turns on terrain elevation monitoring
   type Turn_On_Terrain_Monitoring is new
     Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Turn_On_Terrain_Monitoring);

   type Get_Terrain_Elevation is new Pace.Msg with
      record
         Easting, Northing : Float;  -- the input
         Elevation : Float; -- the output in meters
      end record;
   procedure Inout (Obj : in out Get_Terrain_Elevation);

private

   pragma Inline (Inout);

   type Set_Pitch_Roll_Elevation is new Pace.Msg with null record;
   procedure Input (Obj : in Set_Pitch_Roll_Elevation);

end Gis.Terrain_Following;
