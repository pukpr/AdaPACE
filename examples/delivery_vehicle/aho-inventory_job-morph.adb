with Pace;
with Pace.Log;
with Hal.Morph_Loader;
with hal.bounded_Assembly;

separate (Aho.Inventory_Job)
package body Morph is

   use hal.bounded_Assembly;

   package Morph_Loader is
     new Hal.Morph_Loader (Track_Radius => 0.203,
                           Center_Point_Z => 0.3051,
                           Center_Point_Y_At_Zero_Theta => 0.4319,
                           Liftbox_Rising_Velocity => 0.65,
                           Liftbox_Lowering_Velocity => 1.0,
                           Distance_Between_Wheels => 0.661,
                           Loader_Assembly => To_Bounded_String ("axis_loader"),
                           Arm1_Assembly => To_Bounded_String ("axis_arm1"),
                           Arm2_Assembly => To_Bounded_String ("axis_arm2"),
                           Liftbox_Assembly => To_Bounded_String ("Liftbox"),
                           Rear_Pos_Standoff => (0.0, -1.2838, 0.1021),
                           Endpoint_Z_Stopping_Point => 1.00945);

   procedure Input (Obj : Raise_Loader) is
   begin
      Morph_Loader.Raise_Loader (Obj.Elevation);
      Pace.Log.Trace (Obj);
   end Input;


   procedure Input (Obj : Lower_Loader) is
   begin
      Morph_Loader.Lower_Loader (Obj.Elevation);
      Pace.Log.Trace (Obj);
   end Input;

end Morph;
