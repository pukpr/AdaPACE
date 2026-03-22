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

