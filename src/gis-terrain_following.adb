--with Gis.Ctdb;
with Hal.Terrain_Elevation;
with Hal.Ve;
with Hal;
with Pace.Server.Xml;
with Pace.Log;
--with Hal.Rotations;
with Ada.Numerics;
with Gis.Tdb;

-- makes calls to VE to determine pitch, roll, and elevation...
-- if VE not running
-- then does its own calculation based on map data.
package body Gis.Terrain_Following is

   function Id is new Pace.Log.Unit_Id;
   function Name return String renames Pace.Log.Name;

   Monitor_Terrain : Boolean := True;

   --   Is_Dted_Map : Boolean := Pace.Command_Line.Has_Argument ("-dted");

   Minimum : constant := Hal.Terrain_Elevation.Minimum;
   Maximum : constant := Hal.Terrain_Elevation.Maximum;

   procedure Inout (Obj : in out Turn_Off_Terrain_Monitoring) is
   begin
      Monitor_Terrain := False;
      Pace.Log.Trace (Obj);
   end Inout;

   procedure Inout (Obj : in out Turn_On_Terrain_Monitoring) is
   begin
      Monitor_Terrain := True;
      Pace.Log.Trace (Obj);
   end Inout;

   procedure Input (Obj : in Set_Pitch_Roll_Elevation) is
      use Pace.Server.Xml;
      Pos : Hal.Position := (0.0, 0.0, 0.0);
      Ori : Hal.Orientation := (0.0, 0.0, 0.0);
      Dummy_Scale : Hal.Position := (0.0, 0.0, 0.0);
      Active : Boolean := False;
      Pitch, Roll, Elevation : Float := 0.0;
   begin
--       if Loc.Is_Using_Ctdb then
--          Pos := Loc.Get_Vehicle_Pos_From_Sw_Corner;
--          Gis.Ctdb.Place_Vehicle (
--                         U => Loc.Get_Location,
--                         X => Long_Float (Pos.X),
--                         Y => Long_Float (Pos.Z),
--                         Length => Mobility.Phys.Base_Length,
--                         Width => Mobility.Phys.Base_Width,
--                         Heading => Mobility.Heading,
--                         Elevation => Mobility.Altitude,
--                         Pitch => Mobility.Pitch,
--                         Roll => Mobility.Roll,
--                         Viscosity => Mobility.Viscosity);
      if Loc.Is_Using_Tdb then
         --Pace.Log.Put_Line ("OTF Place Vehicle Called!!!");
         Gis.Tdb.Place_Vehicle (
                        U => Loc.Get_Location,
                        Length => Mobility.Phys.Base_Length,
                        Width => Mobility.Phys.Base_Width,
                        Heading => Mobility.Heading,
                        Elevation => Mobility.Altitude,
                        Pitch => Mobility.Pitch,
                        Roll => Mobility.Roll,
                        Viscosity => Mobility.Viscosity);
      else
         -- check to see if a virtual environment can actively respond back with data
         Hal.Ve.Get_Coordinate ("", Pos, Ori, Active, True, Dummy_Scale);
         -- if active use VE values, otherwise leave the values at zero
         if Active then
            -- vega periodically responds with zeroed out values for pitch and roll
            -- when it is actually something else.  Therefore here we do not accept
            -- zeroed out values.
            if Ori.A = 0.0 then
               Pace.Log.Put_Line ("Avoiding bad return by vega on pitch.  Using previous value.", 4);
               Pitch := Mobility.Pitch;
            else
               Pitch := Ori.A;
               Pace.Log.Put_Line ("pitch from ve is " & Float'Image (Pitch), 4);
            end if;

            if Ori.C = 0.0 then
               Pace.Log.Put_Line ("Avoiding bad return by vega on roll.  Using previous value.", 4);
               Roll := Mobility.Roll;
            else
               Roll := Ori.C;
               Pace.Log.Put_Line ("roll from ve is " & Float'Image (Roll), 4);
            end if;

            if Pos.Y = 0.0 then
               Pace.Log.Put_Line ("Avoiding bad return by vega on elevation.  Using previous value.", 4);
               Elevation := Mobility.Altitude;
            else
               Elevation := Pos.Y;
               Pace.Log.Put_Line ("elevation from ve is " & Float'Image (Elevation), 4);
            end if;
            Pace.Log.Put_Line ("orientation(P,R) is : " & Float'Image(Pitch) & " " & Float'Image(Roll), 4);
         end if;
         Mobility.Pitch := Pitch;
         Mobility.Roll := Roll;
         Mobility.Altitude := Elevation;
      end if;
   end Input;

   procedure Inout (Obj : in out Get_Terrain_Elevation) is
      use Pace.Server.Xml;
      N : Float := Obj.Northing - Loc.Get_Sw_Corner_Northing;
      E : Float := Obj.Easting - Loc.Get_Sw_Corner_Easting;
      Active : Boolean := False;
      UTM_Coord : Utm_Coordinate;
      Pitch, Roll, Elevation, Viscosity : Float;
   begin
      if Loc.Is_Using_Tdb then
         UTM_Coord := (Easting => Obj.Easting,
                       Northing => Obj.Northing,
                       Zone_Num => Mobility.Zone,
                       Hemisphere => Gis.North);  --! Check only northern Hemisphere

         -- get elevation from ctdb
--          Gis.Ctdb.Place_Vehicle (
--                            U => UTM_Coord,
--                            X => Long_Float (E),
--                            Y => Long_Float (N),
--                            Length => 1.0,
--                            Width => 1.0,
--                            Heading => 0.0,  -- Don't care
--                            Elevation => Elevation,
--                            Pitch => Pitch,
--                            Roll => Roll,
--                            Viscosity => Viscosity);
         Gis.Tdb.Place_Vehicle (
                        U => UTM_Coord,
                        Length => 1.0,
                        Width => 1.0,
                        Heading => 0.0,
                        Elevation => Elevation,
                        Pitch => Pitch,
                        Roll => Roll,
                        Viscosity => Viscosity);
         Obj.Elevation := Elevation;
--      elsif Loc.Is_Using_Otf then
--         Pace.Log.Put_Line ("OTF Eleveation not implemented yet!!!");
      else
         -- check to see if a virtual environment can actively respond back with data
         Hal.Ve.Get_Terrain_Elevation (N, E, Obj.Elevation, Active);
         if not Active then
            Obj.Elevation := 0.0;
         end if;
      end if;
   end Inout;

   task Agent is pragma Task_Name (Name);
   end Agent;
   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);

      -- wait until vehicle is initialized
      declare
         Msg : Loc.Vehicle_Initialized;
      begin
         Pace.Dispatching.Inout (Msg);
      end;

      loop
         if Monitor_Terrain then
            declare
               Msg : Set_Pitch_Roll_Elevation;
            begin
               Pace.Dispatching.Input (Msg);
            end;
         else
            -- set values to zero and wait until time to monitor terrain again
            Pace.Log.Put_Line ("turning terrain monitoring off");
            Mobility.Pitch := 0.0;
            Mobility.Roll := 0.0;
            Mobility.Altitude := 0.0;
            while not Monitor_Terrain loop
               Pace.Log.Wait (Delta_Time);
            end loop;
         end if;
         Pace.Log.Wait (Delta_Time);
      end loop;

   exception
      when Event: others =>
         Pace.Log.Ex (Event);
   end Agent;

   use Pace.Server.Dispatch;
begin
   Save_Action (Turn_Off_Terrain_Monitoring'(Pace.Msg with Set => Default));
   Save_Action (Turn_On_Terrain_Monitoring'(Pace.Msg with Set => Default));
end Gis.Terrain_Following;
