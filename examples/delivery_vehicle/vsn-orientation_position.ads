with Pace;
with Hal;
package Vsn.Orientation_Position is

   pragma Elaborate_Body;

   type Get_Barrel_Orientation is new Pace.Msg with
      record
         Abs_El : Float; -- input desired pointing elevation (radians)
         Abs_Az : Float; -- input desired pointing azimuth (radians)
         --
         -- Computation involves actual vehicle orientation (yaw, pitch roll)
         --
         Rel_El : Float; -- output needed relative drone QE (radians)
         Rel_Az : Float; -- output needed relative drone traverse (radians)
      end record;
   procedure Inout (Obj : in out Get_Barrel_Orientation);

   -- considers a vehicles pitch, roll, and yaw as well as absolute position in order
   -- to convert a position vector from the vehicle's frame of reference to an absolute
   -- frame of reference
   type Vehicle_To_Absolute is new Pace.Msg with
      record
         Relative_To_Vehicle : Hal.Position;  -- input
         Absolute_Pos : Hal.Position; -- output
      end record;
   procedure Inout (Obj : in out Vehicle_To_Absolute);

-- $id: vsn-orientation_position.ads,v 1.3 06/17/2003 15:24:02 ludwiglj Exp $
end Vsn.Orientation_Position;
