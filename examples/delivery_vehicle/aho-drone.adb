with Pace;
with Pace.Command_Line;
with Pace.Log;
with Pace.Semaphore;
with Pace.Server.Dispatch;
with Pace.Surrogates;

with Hal;
with Hal.Sms;
with Hal.Audio.Mixer;
with Pace.Strings;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

with Aho.Inventory_Job;
with Aho.Door;
with Ahd.Job_Order_Status;
with Ahd.Delivery_Job;
with Plant.Drone;

with Vsn.Orientation_Position;
with Abk.Technical_Delivery_Direction;
with Veh.Delivery_Motion;
with Vkb;
with Acu;
with Ifc.Job_Data;

with Sim.Inventory;



package body Aho.Drone is

   package Traverse_Drive is
      type Traverse_Drone is new Pace.Msg with
         record
            Angle : Float;
         end record;
      procedure Input (Obj : in Traverse_Drone);
   private
      pragma Inline (Input);
   end Traverse_Drive;
   package body Traverse_Drive is separate;

   package Elevation_Drive is
      type Elevate_Drone is new Pace.Msg with
         record
            Angle : Float;
         end record;
      procedure Input (Obj : in Elevate_Drone);
   private
      pragma Inline (Input);
   end Elevation_Drive;
   package body Elevation_Drive is separate;

   function Id is new Pace.Log.Unit_Id;

   Drone_Elev_Standoff : constant Float := 0.0;
   Total_Items : Integer;
   Items : Ahd.Items_Array;
   Items_Delivered : Integer := 0;
   Job : Ahd.Job_Record;

   task Agent is
      entry Input (Obj : in Initialize);
      entry Input (Obj : in Aim_Drone);
      entry Input (Obj : in Start_Delivery_Job);
      entry Input (Obj : in Test_Drone_Movement);
   end Agent;

   procedure Move_Drone (Elevation : Float; Azimuth : Float) is
   begin

      declare
         Msg : Traverse_Drive.Traverse_Drone;
      begin
         Msg.Angle := Azimuth;
         Pace.Dispatching.Input (Msg);
      end;

      declare
         Msg : Elevation_Drive.Elevate_Drone;
      begin
         Msg.Angle := Elevation;
         Pace.Dispatching.Input (Msg);
      end;
   end Move_Drone;

   procedure Move_Drone (Item_Num : Integer) is
   begin
      Move_Drone (Items (Item_Num).Elevation, Items (Item_Num).Azimuth);
   end Move_Drone;

   procedure Delivery_Box (Item_Num : Integer) is
      use Ifc.Job_Data.Item_Vector;
      use Pace.Strings;
      Start_Pos : Hal.Position := (0.0, 0.0, 0.0);
      Dummy_Ori : Hal.Orientation;
      Dummy_Scale : Hal.Position;
      Active : Boolean := True;
   begin

      Hal.Sms.Get_Coordinate ("inore", Start_Pos, Dummy_Ori, Active, True, Dummy_Scale);

   end Delivery_Box;


   type Lift_Off is new Pace.Msg with null record;
   procedure Input (Obj : in Lift_Off);
   procedure Input (Obj : in Lift_Off) is
      Stopped : Boolean := True;
      Relax_Pos : Hal.Position := (0.0, 0.0, 0.0);
      Lift_Off_Pos : Hal.Position := (0.0, 0.0, -1.0668); -- desired

      Freq : Hal.Rate := (1.5, 1);
      Damp : Hal.Rate := (0.15, 1);
      Max_Time : Duration := 3.0;
   begin
      -- the ramping values here were arbitrarily chosen..
      Hal.Sms.Translation ("sa_lift_off_mass", Relax_Pos, Lift_Off_Pos, 0.15, Stopped, 0.7, 0.8);
      Pace.Log.Wait (0.1);
      Hal.Sms.Translation ("sa_lift_off_mass", Lift_Off_Pos, Relax_Pos, 0.65, Stopped, 0.2, 0.45);
      Pace.Log.Trace (Obj);
   end Input;

   type Launch is new Pace.Msg with null record;
   procedure Input (Obj : in Launch);
   procedure Input (Obj : in Launch) is
   begin
      Pace.Log.Wait (0.11);
      Pace.Log.Trace (Obj);
   end Input;

   -- exists so can be called in a surrogate task since
   -- this sound isn't tied to any mechanical motion and need
   -- to reclaim the memory with the ending inout
   type Play_Sound is new Pace.Msg with null record;
   procedure Input (Obj : Play_Sound);
   procedure Input (Obj : Play_Sound) is
      use Hal.Audio.Mixer;
      use Vkb.Rules;

      Audio_Msg : Hal.Audio.Mixer.Play_Mix;
      V : Variables (1 .. 2);
   begin
      Vkb.Agent.Query ("drone_sound", V);
      Audio_Msg.File := V(1);
      Audio_Msg.Volume := Integer'Value (+V(2));
      Pace.Dispatching.Inout (Audio_Msg);
      Pace.Log.Wait (5.5);
      Pace.Dispatching.Inout (Audio_Msg);
   end Input;

   procedure Delivery (Item_Num : Integer) is
   begin
      Plant.Drone.Set_Launchpad_Velocity (Item_Num,
                                        Items (Item_Num).Launchpad_Velocity);

      declare
         Msg : Launch;
      begin
         Input (Msg);
      end;

      declare
         Msg : Veh.Delivery_Motion.Rock_Vehicle;
      begin
         Msg.Elevation := Items (Item_Num).Elevation;
         Pace.Surrogates.Input (Msg);
      end;

      declare
         Msg : Veh.Delivery_Motion.Rebound_Vehicle;
      begin
         Msg.Elevation := Items (Item_Num).Elevation;
         Pace.Surrogates.Input (Msg);
      end;

      --Delivery_Box (Item_Num);

      -- surrogate this since the springy action takes longer than we want
      declare
         Msg : Lift_Off;
      begin
         Pace.Surrogates.Input (Msg);
      end;

      declare
         Msg : Play_Sound;
      begin
         Pace.Surrogates.Input (Msg);
      end;

      Pace.Log.Wait (0.9);

      Pace.Log.Put_Line ("DELIVERY");
   end Delivery;

   type Photo is new Pace.Msg with null record;
   procedure Input (Obj : Photo);
   procedure Input (Obj : Photo) is
   begin
      Pace.Log.Wait (0.7);
      Pace.Log.Trace (Obj);
   end Input;

   task body Agent is

      procedure Wait_To_Delivery (Item_Index : Integer) is
      begin
         if Ahd.Delivery_Job.Is_Time_On_Customer then
            declare
               use Ifc.Job_Data;
               Msg : Ahd.Delivery_Job.Get_Delivery_Job;
               Delivery_Time : Duration;
               Start_Time : Duration;
            begin
               Pace.Dispatching.Output (Msg);
               Start_Time := Msg.Job.Data.Start_Time;
               Delivery_Time := Msg.Job.Items (Item_Index).Delivery_Time;
               -- Wait to appointed time to delivery the item
               if (Start_Time + Delivery_Time) < Pace.Now then
                  Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!Delivery: Immediately.. missed desired delivery time by " & Duration'Image (Pace.Now - (Start_Time + Delivery_Time)));
               else
                  Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!waiting " &
                                     Duration'Image ((Start_Time + Delivery_Time) - Pace.Now) &
                                     " seconds to delivery");
                  Pace.Log.Wait_Until (Start_Time + Delivery_Time);
               end if;
            end;
         else
            Pace.Log.Put_Line ("Delivery: Immediately");
         end if;
      end Wait_To_Delivery;

      procedure Finalize_Delivery_Job is
      begin
         declare
            use Aho.Inventory_Job;
            Msg : Stow_Equipment;
         begin
            Pace.Dispatching.Input (Msg);
            Pace.Log.Put_Line ("Stow Equipment");
         end;
         Pace.Log.Put_Line ("Traverse Drone to Stow");
         Pace.Log.Put_Line ("Elevate Drone to Stow");
         Move_Drone (Azimuth => 0.0, Elevation => Drone_Elev_Standoff);

         -- ensure that traversal and elevation are complete
         declare
            Msg : Elevation_Complete;
         begin
            Pace.Dispatching.Inout (Msg);
         end;
         declare
            Msg : Traverse_Complete;
         begin
            Pace.Dispatching.Inout (Msg);
         end;

         -- notify that job is complete
         Ahd.Delivery_Job.Publish_Delivery_Job_Complete;
         Pace.Log.Put_Line ("Delivery Job Complete");

      end Finalize_Delivery_Job;

      procedure Adjust_For_Terrain is
      begin
         -- adjust drone elev and azimuth for terrain
         null;
      end Adjust_For_Terrain;

      -- we do this because the vehicle may have moved between when this was
      -- calculated last and now
      procedure Recalculate_Vel_And_Az is
      begin
         declare
            Msg : Ahd.Delivery_Job.Get_Delivery_Job;
            Modified_Job : Ahd.Job_Record;
         begin
            Pace.Dispatching.Output (Msg);
            Modified_Job := Msg.Job;
            Abk.Technical_Delivery_Direction.Calculate_Vel_And_Az (Modified_Job);
            Items := Modified_Job.Items;
            declare
               Msg2 : Ahd.Delivery_Job.Adjust_Items;
            begin
               Msg2.Items := Items;
               Pace.Dispatching.Input (Msg2);
            end;
         end;
      end Recalculate_Vel_And_Az;

   begin
      Pace.Log.Agent_Id (Id);
      loop
         select
            accept Input (Obj : in Initialize) do
               Total_Items := Obj.Num_Items;
               Items := Obj.Items;
               Pace.Log.Put_Line ("!!!!!!! elevation of the first item is " & Items(1).Elevation'Img);
               if Ahd.Delivery_Job.Has_Customer then
                  Adjust_For_Terrain;
               end if;
               Pace.Log.Trace (Obj);
            end Input;
            declare
               Msg : Aho.Inventory_Job.Initialize;
            begin
               Msg.Total_Items := Total_Items;
               Pace.Dispatching.Input (Msg);
            end;
            accept Input (Obj : in Aim_Drone) do
               -- move to the first items elev and azim
               -- will move a second time in case vel and az have changed
               Move_Drone (1);
               Pace.Log.Trace (Obj);
            end Input;
            accept Input (Obj : in Start_Delivery_Job) do
               Items_Delivered := 0;
               Pace.Log.Put_Line ("Total Items" &
                                  Integer'Image (Total_Items));
               if Ahd.Delivery_Job.Has_Customer then
                  Recalculate_Vel_And_Az;
                  Adjust_For_Terrain;
                  -- clear out the first move_drone above
                  -- unrealistic here if the first move isn't done yet
                  -- then it will finish and then move to new angles..
                  -- when we would want to immediately move to the new angles.
                  -- need to add some sort of canceling effect to the drone drives
                  declare
                     Msg : Traverse_Complete;
                  begin
                     Pace.Dispatching.Inout (Msg);
                  end;
                  declare
                     Msg : Elevation_Complete;
                  begin
                     Pace.Dispatching.Inout (Msg);
                  end;
                  Move_Drone (1);
               end if;
               Pace.Log.Trace (Obj);
            end Input;

            declare
               Msg : Ahd.Delivery_Job.Get_Delivery_Job;
            begin
               Pace.Dispatching.Output (Msg);
               Job := Msg.Job;
            end;

            loop
               declare
                  use Aho.Inventory_Job;
                  Msg : Load_Drone;
               begin
                  Msg.Item_Index := Items_Delivered + 1;
                  Msg.Elevation := Items (Items_Delivered + 1).Elevation;
                  Msg.Azimuth := Items (Items_Delivered + 1).Azimuth;
                  Pace.Log.Put_Line ("Load_Drone");
                  Pace.Dispatching.Input (Msg);
               end;

               if Items_Delivered /= 0 then
                  declare
                     Msg : Aho.Door.Rotate_Done;
                  begin
                     Pace.Dispatching.Inout (Msg);
                  end;
               end if;

               declare
                  use Aho.Inventory_Job;
                  Msg : Ack_Load_Drone_Complete;
               begin
                  Pace.Dispatching.Input (Msg);
               end;

               -- ensure that elevation and traversal is complete before delivery!
               declare
                  Msg : Traverse_Complete;
               begin
                  Pace.Dispatching.Inout (Msg);
               end;
               declare
                  Msg : Elevation_Complete;
               begin
                  Pace.Dispatching.Inout (Msg);
               end;

               Wait_To_Delivery (Items_Delivered + 1);

               -- Wait for Clear_To_Delivery
               declare
                   Msg : Aho.Inventory_Job.Clear_To_Delivery;
                begin
                   Pace.Dispatching.Inout (Msg);
                end;

               Delivery (Items_Delivered + 1);

               Items_Delivered := Items_Delivered + 1;

               declare
                  use Ahd.Job_Order_Status;
                  Msg : Modify_Box;
               begin
                  Msg.Index := Items_Delivered;
                  Msg.Status := Delivered;
                  Pace.Dispatching.Input (Msg);
               end;
               -- remove 1 box and 1 bottle
               Sim.Inventory.Remove_Box (Ifc.Job_Data.Item_Vector.Element (Job.Data.Items, Items_Delivered).Box);
               if Job.Items (Items_Delivered).Power_Level <= 2 then
                  null; -- Sim.Inventory.Remove_Bottle (Sim.Inventory.Half, Job.Items (Items_Delivered).Power_Level);
               else
                  Sim.Inventory.Remove_Bottle (Sim.Inventory.Full, Job.Items (Items_Delivered).Power_Level);
               end if;

               Pace.Log.Put_Line ("Items Delivered : " &
                                  Integer'Image (Items_Delivered) & " total_items : " & Total_Items'Img);
               exit when Items_Delivered = Total_Items;
               Pace.Log.Put_Line ("moving drone");
               Move_Drone (Items_Delivered + 1);
            end loop;

            Finalize_Delivery_Job;
         or
            accept Input (Obj : in Test_Drone_Movement) do
               Move_Drone (Obj.Elevation, Obj.Azimuth);
               -- even though we don't care, call these or it will hang
               -- since the elevation and traverse drives will be expecting
               -- them
               declare
                  Msg : Elevation_Complete;
               begin
                  Pace.Dispatching.Inout (Msg);
               end;
               declare
                  Msg : Traverse_Complete;
               begin
                  Pace.Dispatching.Inout (Msg);
               end;
               Pace.Log.Trace (Obj);
            end Input;
         end select;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;


   -- Range is 0 to -75 orientation,
   procedure Input (Obj : in Initialize) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Aim_Drone) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Load_Complete) is
   begin
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Start_Delivery_Job) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Test_Drone_Movement) is
   begin
      Agent.Input (Obj);
   end Input;

   type Delivery_Drone is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Delivery_Drone);
   procedure Inout (Obj : in out Delivery_Drone) is
      use Pace.Server.Dispatch;
   begin
      Delivery (1);
   end Inout;

   type Peek_Items_Delivered is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Peek_Items_Delivered);

   procedure Inout (Obj : in out Peek_Items_Delivered) is
      use Pace.Server.Dispatch;
      use Pace.Strings;
   begin
      Obj.Set := +Integer'Image (Items_Delivered);
      Pace.Server.Put_Data (+Obj.Set);
   end Inout;

   use Pace.Server.Dispatch;
begin
   Save_Action (Peek_Items_Delivered'(Pace.Msg with Set => Default));
   Save_Action (Delivery_Drone'(Pace.Msg with Set => Default));
end Aho.Drone;
