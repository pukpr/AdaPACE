with Pace;
with Pace.Log;
with Pace.Surrogates;
with Hal;
with Hal.Sms;
with Ada.Numerics;

with Aho.Inventory_Loader;
with Plant.Drone;
with Plant;

separate (Aho.Drone)
package body Traverse_Drive is

   function Id is new Pace.Log.Unit_Id;

   Current_Orn : Hal.Orientation := (0.0, 0.0, 0.0);
   Spin_Rate : constant Float := Hal.Rads (10.0);
   Traverse_Angle : Float := 0.0;

   Ramp_Up : constant Duration := 0.6687;
   Ramp_Down : constant Duration := 0.6687;
   Settle_Time : constant Duration := 0.4012;

   type Drone_Traverse is new Pace.Msg with
      record
         Final : Hal.Orientation;
         Assembly : Ada.Strings.Unbounded.Unbounded_String;
         Speed : Float;
         Axis : Character;
      end record;
   procedure Input (Obj : in Drone_Traverse);

   task Agent is
      entry Input (Obj : in Traverse_Drone);
   end Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         accept Input (Obj : in Traverse_Drone) do
            -- the division model is backwards in relation to the SSOM so negate it here
            --Traverse_Angle := -1.0 * Obj.Angle;
            Traverse_Angle := Obj.Angle;
            Plant.Drone.Set_Drone_Azimuth (Hal.Rads (Obj.Angle));
         end Input;

         -- don't do any rotation if it is already at the desired angle,
         -- but still need to send traverse_complete signal
         if Traverse_Angle /= Current_Orn.B then
            if Traverse_Angle > Plant.Max_Traverse_Angle then
               Traverse_Angle := Plant.Max_Traverse_Angle;
            elsif Traverse_Angle < -1.0 * Plant.Max_Traverse_Angle then
               Traverse_Angle := -1.0 * Plant.Max_Traverse_Angle;
            end if;
            -- the loader swing tray counter traverses simultaneously with
            -- the traversal of the drone/loader.  The counter_rotate loader forks off
            -- a surrogate and it must rotate at the same speed as the drone/loader
            -- traversal so that the shuttles can transfer their inventory at anytime
            -- to the loader.
            declare
               use Aho.Inventory_Loader;
               Msg : Counter_Rotate;
            begin
               Msg.Offset := -Traverse_Angle;
               Msg.Max_Velocity := Spin_Rate;
               Msg.Ramp_Up := Ramp_Up;
               Msg.Ramp_Down := Ramp_Down;
               Pace.Surrogates.Input (Msg);
            end;
            declare
               Msg : Drone_Traverse;
            begin
               Msg.Axis := 'Y';
               Msg.Speed := Spin_Rate;
               Msg.Final := (0.0, Traverse_Angle, 0.0);
               Msg.Assembly := Ada.Strings.Unbounded.To_Unbounded_String
                 ("Azimuth_Angle");
               Pace.Log.Put_Line ("traversing azimuth in VE to " &
                                  Float'Image (-1.0 * Traverse_Angle));
               Pace.Dispatching.Input (Msg);
            end;
         end if;
         -- At this point we assume the align loader is finished as well
         -- since it rotated the same distance at the same rate
         declare
            Msg : Traverse_Complete;
         begin
            Pace.Dispatching.Input (Msg);
         end;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Traverse_Drone) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Update_Azimuth_Cb (Ori : in Hal.Orientation) is
   begin
      Plant.Drone.Set_Drone_Azimuth (Ori.B);
   end Update_Azimuth_Cb;

   procedure Input (Obj : in Drone_Traverse) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation;
      Rate : Hal.Rate;
   begin
      End_Orn := (0.0, Hal.Rads (Obj.Final.B), 0.0);
      Rate.Units := Obj.Speed;
      Hal.Sms.Rotation (Ada.Strings.Unbounded.To_String (Obj.Assembly),
                        (0.0, Hal.Rads (Current_Orn.B), 0.0),
                        End_Orn, Rate, Stopped, Ramp_Up, Ramp_Down, Update_Azimuth_Cb'Access);
      Current_Orn.B := Hal.Degs (End_Orn.B);
      Pace.Log.Wait (Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

end Traverse_Drive;

