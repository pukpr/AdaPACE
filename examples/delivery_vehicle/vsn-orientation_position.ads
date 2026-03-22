with Pace;
with Hal;
package Vsn.Orientation_Position is

   pragma Elaborate_Body;

   -- considers a vehicles pitch, roll, and yaw as well as absolute position in order
   -- to convert a position vector from the vehicle's frame of reference to an absolute
   -- frame of reference
   type Vehicle_To_Absolute is new Pace.Msg with
      record
         Relative_To_Vehicle : Hal.Position;  -- input
         Absolute_Pos : Hal.Position; -- output
      end record;
   procedure Inout (Obj : in out Vehicle_To_Absolute);

end Vsn.Orientation_Position;
