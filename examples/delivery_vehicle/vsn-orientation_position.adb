with Acu;
with Hal;
with Hal.Rotations;
with Pace.Log;
with Ada.Numerics.Elementary_Functions;
with Nav.Location;

package body Vsn.Orientation_Position is

   -----------
   -- Inout --
   -----------
   use Hal.Rotations;
   use Ada.Numerics.Elementary_Functions;

   procedure Inout (Obj : in out Get_Barrel_Orientation) is
      Pos : Hal.Position := (1.0, 0.0, 0.0);
   begin

      Pace.Log.Put_Line
                    ("INPUT TO VSN: " & "\npitch-> " & Float'Image (Acu.Pitch) &
                     "\troll-> " & Float'Image (Acu.Roll) &
                     "\theading-> " & Float'Image (Acu.Heading) &
                     "\tabs_el-> " & Float'Image (Obj.Abs_El) &
                     "\tabs_az-> " & Float'Image (Obj.Abs_Az), 8);

      -- Obtain desired absolute location (no roll component) in the SSOM vehicle CS
      -- (So negate Azimuth but not Elevation since it is a special case)
      Pos := Hal.Rotations.R3_Terrain (Pos, (A => 0.0,
                                             B => Obj.Abs_El,
                                             C => -Obj.Abs_Az));

      -- Do the inverse transformation in SSOM vehicle CS and obtain the Relative location
      Pos := Hal.Rotations.R3_Terrain (P => Pos,
                                       R => (A => Acu.Roll,
                                             B => Acu.Pitch,
                                             C => Acu.Heading),
                                       Invert => True);

      -- Convert from SSOM CS to VE CS
      declare
         Temp_Pos : constant Hal.Position := Pos;
      begin
         Pos := (-Temp_Pos.Y, -Temp_Pos.Z, Temp_Pos.X);
      end;

      -- use trig to get relative elevation and azimuth in VE CS
      Obj.Rel_El := Arctan (Pos.Y, Sqrt (Pos.X * Pos.X + Pos.Z * Pos.Z));
      Obj.Rel_Az := Arctan (Pos.X, Pos.Z);

      Pace.Log.Put_Line
                      ("OUTPUT FROM VSN: " & "\nrel_el-> " &
                       Float'Image (Obj.Rel_El) & "\trel_az-> " &
                       Float'Image (Obj.Rel_Az), 8);
   end Inout;

   procedure Inout (Obj : in out Vehicle_To_Absolute) is
      Veh_Ref_Frame : Hal.Orientation := (A => Acu.Roll,
                                          B => Acu.Pitch,
                                          C => Acu.Heading);

      Veh_Pos : Hal.Position := Nav.Location.Get_Vehicle_Pos_From_Sw_Corner;
   begin
      Obj.Absolute_Pos := Hal.Rotations.R3_Terrain (Obj.Relative_To_Vehicle, Veh_Ref_Frame);

      -- add in vehicles position offset from absolute zero
      Obj.Absolute_Pos.X := Obj.Absolute_Pos.X + Veh_Pos.X;
      Obj.Absolute_Pos.Y := Obj.Absolute_Pos.Y + Veh_Pos.Y;
      Obj.Absolute_Pos.Z := Obj.Absolute_Pos.Z + Veh_Pos.Z;
   end Inout;

end Vsn.Orientation_Position;

