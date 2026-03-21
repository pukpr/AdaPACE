with Pace;
with Pace.Log;
with Pace.Surrogates;
with Hal;
with Hal.Sms;
with Hal.Audio.Mixer;
with Ada.Numerics;
with Aho.Inventory_Loader;
with Aho.Morph_Track;
with Aho.Demonstrator_Track;
with Plant.Drone;
with Plant;
with Ada.Strings.Unbounded;

separate (Aho.Drone)
package body Elevation_Drive is

   function Id is new Pace.Log.Unit_Id;

   Current_Orn : Hal.Orientation := (0.0, 0.0, 0.0);
   Elevation_Angle : Float := 0.0;
   Angular_Difference : Float;

   Ramp_Up : constant Duration := 0.5207;
   Ramp_Down : constant Duration := 0.5207;
   Settle_Time : constant Duration := 0.3124;

   type Drone_Elevate is new Pace.Msg with
      record
         Final : Hal.Orientation;
         Assembly : Ada.Strings.Unbounded.Unbounded_String;
         Speed : Float;
         Axis : Character;
      end record;
   procedure Input (Obj : in Drone_Elevate);

   task Agent is
      entry Input (Obj : in Elevate_Drone);
   end Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         accept Input (Obj : in Elevate_Drone) do
            Elevation_Angle := Obj.Angle;
         end Input;

         -- if drone is already at the desired elevation angle then
         -- don't make calls to hal, but still need to say that
         -- elevation is complete
         if Current_Orn.A /= Elevation_Angle then
            Angular_Difference := abs (Current_Orn.A - Elevation_Angle);

            -- if using the morph loader or the demonstrator loader then
            -- their tracks must move also!
--              declare
--                 use Aho.Inventory_Loader;
--              begin
--                 if Get_Which_Loader = Morph_Loader then
--                    declare
--                       Msg : Aho.Morph_Track.Do_Morph;
--                    begin
--                       Msg.Starting_Angle := Current_Orn.A;
--                       Msg.Ending_Angle := Elevation_Angle;
--                       Pace.Dispatching.Input (Msg);
--                    end;
--                 elsif Get_Which_Loader = Demonstrator_Loader then
--                    declare
--                       Msg : Aho.Demonstrator_Track.Adjust_Track;
--                    begin
--                       Msg.Starting_Angle := Current_Orn.A;
--                       Msg.Ending_Angle := Elevation_Angle;
--                       Pace.Dispatching.Input (Msg);
--                    end;
--                 end if;
--              end;
            Pace.Log.Put_Line ("Elevating drone in VE to " &
                               Float'Image (Elevation_Angle));
            declare
               Msg : Drone_Elevate;
            begin
               Msg.Speed := Hal.Rads (Plant.Drone_Elevation_Rate);
               Msg.Final := (Elevation_Angle, 0.0, 0.0);
               Msg.Axis := 'X';
               Msg.Assembly := Ada.Strings.Unbounded.To_Unbounded_String
                 ("Drone_Elevation");
               Pace.Dispatching.Input (Msg);
            end;
         end if;

         declare
            Msg : Elevation_Complete;
         begin
            Pace.Log.Put_Line ("elevation completed");
            Pace.Dispatching.Input (Msg);
         end;

      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Elevate_Drone) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Update_Elevation_Cb (Ori : Hal.Orientation) is
   begin
      Plant.Drone.Set_Drone_Elevation (Ori.A);
   end Update_Elevation_Cb;


   function Pick_File_Length return String is
   begin
      if Angular_Difference < 10.0 then
         return "drone_elevate_1";
      elsif Angular_Difference < 50.0 then
         return "drone_elevate_3";
      else
         return "drone_elevate_6";
      end if;
   end Pick_File_Length;

   procedure Input (Obj : in Drone_Elevate) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation := (Hal.Rads (Obj.Final.A), 0.0, 0.0);
      Rate : Hal.Rate;
      Audio_Msg : Hal.Audio.Mixer.Play_Mix := Make_Audio (Pick_File_Length);
   begin
      Rate.Units := Obj.Speed;

      -- starting sound
      Pace.Dispatching.Inout (Audio_Msg);

      Hal.Sms.Rotation (Ada.Strings.Unbounded.To_String (Obj.Assembly),
                        (Hal.Rads (Current_Orn.A), 0.0, 0.0),
                        End_Orn, Rate, Stopped, Ramp_Up,
                        Ramp_Down, Update_Elevation_Cb'Access);
      Current_Orn.A := Hal.Degs (End_Orn.A);

      -- stopping sound
      Pace.Dispatching.Inout (Audio_Msg);

      Pace.Log.Wait (Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

end Elevation_Drive;

