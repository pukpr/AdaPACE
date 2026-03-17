with Pace;
with Ada.Strings.Unbounded;
with Gis.Terrain_Following;
with Mob.Vehicle;

generic
   with package Mobility is new Mob.Vehicle (<>);
   with package Terrain is new Gis.Terrain_Following (<>);
package Gis.Elevation_Cache is

   pragma Elaborate_Body;

   type Mountain_Type is array (Integer range <>) of Float;

   type Profile_Array (Num_Intervals : Integer) is new Pace.Msg with
      record
         Heading : Float; -- Radians
         Interval : Float;
         Post_Data : Mountain_Type (1 .. Num_Intervals);
      end record;
   procedure Inout (Obj : in out Profile_Array);
   --This operation inputs values of Heading and Interval, and returns an
   --array of elevation points of the terrain for the given heading (in
   --the record Profile_Array).


   -- same as Profile_Array but returns a String in Post_Data instead
   -- of an array
   type Profile is new Pace.Msg with
      record
         Heading : Float; -- Radians
         Interval : Float;
         Num_Intervals : Integer;
         Post_Data : Ada.Strings.Unbounded.Unbounded_String;
      end record;
   procedure Inout (Obj : in out Profile);

end Gis.Elevation_Cache;
