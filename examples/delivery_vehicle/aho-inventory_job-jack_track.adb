with Pace.Log;
with Ada.Numerics.Elementary_Functions;
with Hal;
with Hal.Key_Frame;
with Hal.Jack_Track;
with Hal.Sms;
with Pace.Command_Line;
with Plant.Drone;

separate (Aho.Inventory_Job)
package body Jack_Track is

   procedure Check (Pos : Hal.Position) is
   begin
      null;
   end Check;

   function Get_Elevation (Wait : Boolean := False) return Float is
   begin
      return Plant.Drone.Get_Drone_Elevation;
   end Get_Elevation;

   package Track is new Hal.Jack_Track
                          (Name => "axis_loader",
                           Radius => Pace.Command_Line.Argument
                                       ("jt_radius", 0.4242),
                           Length => Pace.Command_Line.Argument
                                       ("jt_length", 0.875),
                           Height => Pace.Command_Line.Argument
                                       ("jt_height", 0.45),
                           Offset => Pace.Command_Line.Argument
                                       ("jt_offset", 0.52),
                           Width => Pace.Command_Line.Argument
                                      ("jt_width", 0.22),
                           Up_Velocity => Pace.Command_Line.Argument
                                            ("jt_up_vel", 1.29),
                           Down_Velocity => Pace.Command_Line.Argument
                                              ("jt_down_vel", 1.404),
                           Delta_T => Pace.Command_Line.Argument
                                        ("jt_delta", 0.033),
                           Wheel => Pace.Command_Line.Argument
                                      ("jt_wheel", 0.1067),
                           Base => Pace.Command_Line.Argument ("jt_base", 0.29),
                           Shift => Pace.Command_Line.Argument
                                      ("jt_shift", -0.07),
                           Crook => Pace.Command_Line.Argument
                                      ("jt_crook", 0.3908 * 0.6),
                           Short => Pace.Command_Line.Argument
                                      ("jt_short", 0.08),
                           Start_Pos => (0.0, 0.0, 0.0),
                           Start_Ori => (0.0, 0.0, 0.0),
                           Elevation => Get_Elevation,
                           Callback_Check => Check,
                           Back_Track => Hal.Key_Frame.Points'(1 .. 0 => (0.0, 0.0, 0.0)));

   procedure Input (Obj : in Raise_Loader) is
   begin
      Track.Up; -- (Obj.Elevation);
   end Input;

   procedure Input (Obj : in Lower_Loader) is
   begin
      Track.Down;
   end Input;

end Jack_Track;
