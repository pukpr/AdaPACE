with Pace.Log;
with Pace.Socket;
with Ada.Numerics.Elementary_Functions;
with Ada.Numerics;
with Ada.Strings.Unbounded;
with Hal.Terrain_Elevation.Dted;

package body Gis.Elevation_Cache is

   use Ada.Numerics.Elementary_Functions;

   procedure Inout (Obj : in out Profile) is
      use Ada.Strings.Unbounded;
      Msg : Profile_Array (Obj.Num_Intervals);
      Str : Unbounded_String;
   begin
      Msg.Heading := Obj.Heading;
      Msg.Interval := Obj.Interval;
      Pace.Dispatching.Inout (Msg);
      for I in Msg.Post_Data'Range loop
         Append (Str, Float'Image (Msg.Post_Data (I)));
      end loop;
      Obj.Post_Data := Str;
   end Inout;

   procedure Inout (Obj : in out Profile_Array) is
      X, Y : Float;
      Heading, X_Interval, Y_Interval : Float;
   begin
      Pace.Log.Trace (Obj);
      X := Mobility.North;
      Y := Mobility.East;
      Heading := Obj.Heading;
      X_Interval := Obj.Interval * Cos (Heading);
      Y_Interval := Obj.Interval * Sin (Heading);

      for I in Obj.Post_Data'Range loop
         X := X + X_Interval;
         Y := Y + Y_Interval;
         Obj.Post_Data (I) := Hal.Terrain_Elevation.Dted.Get_Altitude(Y, X, 11, 'S');
--          declare
--             Msg : Terrain.Get_Post_Data;
--          begin
--             Msg.X := X;
--             Msg.Y := Y;
--             Pace.Dispatching.Inout (Msg);
--             Obj.Post_Data (I) := Msg.P0;
--          end;
      end loop;
   end Inout;

end Gis.Elevation_Cache;
