with Hal;
with Hal.Sms;
with Pace.Log;
with Pace.Surrogates;
with Ada.Numerics.Elementary_Functions;
with Plant;

package body Aho.Demonstrator_Track is

   function Id is new Pace.Log.Unit_Id;


   function Calculate_Tangent_Point (Theta : Float) return Hal.Position is
      use Ada.Numerics.Elementary_Functions;
      N : constant Float := 0.281;
      M : constant Float := 0.410;
      Result : Hal.Position;
   begin
      Result.X := 0.0;
      Result.Y := N * Tan (Theta) - M / Cos (Theta);
      Result.Z := 0.2822;
      return Result;
   end Calculate_Tangent_Point;


   -- does the vertical translation of the track.. encapsulated as
   -- a Pace.Msg solely for purpose of being able to use a surrogate task
   type Move_Track_Up is new Pace.Msg with
      record
         Starting_Angle : Float; -- degrees
         Ending_Angle : Float; -- degrees
      end record;
   procedure Input (Obj : in Move_Track_Up);
   procedure Input (Obj : in Move_Track_Up) is
      Starting_Point : Hal.Position :=
        Calculate_Tangent_Point (Hal.Rads (Obj.Starting_Angle));
      Ending_Point : Hal.Position :=
        Calculate_Tangent_Point (Hal.Rads (Obj.Ending_Angle));
      Delta_Time : Float;
      Rate : Hal.Rate;
      Stopped : Boolean;
   begin
      -- need to ensure that the translation will begin and end at same
      -- time as rotation, so determine how fast to translate based on
      -- how long it takes to do the rotation
      Delta_Time := abs (Obj.Starting_Angle - Obj.Ending_Angle) /
                      Plant.Drone_Elevation_Rate;
      Rate.Units := abs (Starting_Point.Y - Ending_Point.Y) / Delta_Time;

      Hal.Sms.Translation ("MorphTrack", Starting_Point,
                           Ending_Point, Rate, Stopped);
      -- don't want a trace here since this wouldn't otherwise be a Pace.Msg
   end Input;

   -- need to do two motions simultaneously.. a rotation and a vertical
   -- translation.. they should begin and end at same time
   procedure Do_Adjust_Track (Starting_Angle, Ending_Angle : Float) is
   begin
      -- no where to go if angles are equal
      if Starting_Angle /= Ending_Angle then
         -- the vertical translation
         declare
            Msg : Move_Track_Up;
         begin
            Msg.Starting_Angle := Starting_Angle;
            Msg.Ending_Angle := Ending_Angle;
            Pace.Surrogates.Input (Msg);
         end;
         -- the rotation
         declare
            Stopped : Boolean;
            Rate : Hal.Rate;
            Starting_Ori : Hal.Orientation :=
              (-1.0 * Hal.Rads (Starting_Angle), 0.0, 0.0);
            Destination_Ori : Hal.Orientation :=
              (-1.0 * Hal.Rads (Ending_Angle), 0.0, 0.0);
         begin
            Rate.Units := Hal.Rads (Plant.Drone_Elevation_Rate);
            Hal.Sms.Rotation ("LoaderPivot", Starting_Ori,
                              Destination_Ori, Rate, Stopped);
         end;
      end if;
   end Do_Adjust_Track;



   task Agent is
      entry Input (Obj : Adjust_Track);
   end Agent;

   task body Agent is

   begin
      Pace.Log.Agent_Id (Id);

      loop
         declare
            Starting_Angle, Ending_Angle : Float;
         begin
            accept Input (Obj : Adjust_Track) do
               Starting_Angle := Obj.Starting_Angle;
               Ending_Angle := Obj.Ending_Angle;
               Pace.Log.Trace (Obj);
            end Input;
            Do_Adjust_Track (Starting_Angle, Ending_Angle);
         end;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Adjust_Track) is
   begin
      Agent.Input (Obj);
   end Input;

end Aho.Demonstrator_Track;
