with Pace;
with Pace.Log;
with Hal;
with Hal.Sms;
with Hal.Audio.Mixer;
with Ada.Numerics;
with Pace.Surrogates;

with Aho.Box_Shuttle_Grippers;
with Aho.Box_Compartment;
with Ahd.Delivery_Order_Status;
with Aho.Timer_Setter;
with Aho.Resupply_Shuttle;

package body Aho.Box_Shuttle is

   function Id is new Pace.Log.Unit_Id;


   -- Stow Locations
   Extend_Stow : constant Hal.Position := (0.0, 0.0, 0.0);
   Spin_Stow : constant Hal.Orientation := (0.0, 0.0, 0.0);

   -- BoxShuttleExtend locations
   Retract_Position : constant Hal.Position := (0.0, 0.0, 0.0);
   Extend_Position : constant Hal.Position := (-0.185, 0.0, 0.0);

   -- BoxShuttleSpin orientations
   Spin_Standoff : constant Hal.Orientation := (0.0, 0.0, 0.0);
   Spin_Loader_Handoff : constant Hal.Orientation := (0.0, 99.44, 0.0);
   Spin_Mag_Handoff : constant Hal.Orientation := (0.0, 0.0, 0.0);
   Spin_Resupply_Bottle_Handoff : constant Hal.Orientation := (0.0, -95.0, 0.0);
   Spin_Tag_Standoff : constant Hal.Orientation := (0.0, 94.343, 0.0);

   Standoff_Orientation : Hal.Orientation := Spin_Standoff;
   Current_Orn : Hal.Orientation := Spin_Stow;
   Current_Pos : Hal.Position := Extend_Stow;
   Spin_Rate : constant Float := Hal.Rads (300.0);
   Tot_Items : Integer;
   Items_Complete : Integer := 0;

   Translate_Ramp_Up : constant Duration := 0.1921;
   Translate_Ramp_Down : constant Duration := 0.1921;
   Translate_Settle_Time : constant Duration := 0.1153;
   Spin_Ramp_Up : constant Duration := 0.2639;
   Spin_Ramp_Down : constant Duration := 0.2639;
   Spin_Settle_Time : constant Duration := 0.1583;

   type Translate_Shuttle is new Pace.Msg with
      record
         Total_Time : Duration;
         Final : Hal.Position;
      end record;
   procedure Input (Obj : in Translate_Shuttle);

   type Rotate_Shuttle is new Pace.Msg with
      record
         Total_Time : Duration;
         Final : Hal.Orientation;
      end record;
   procedure Input (Obj : in Rotate_Shuttle);

   task Agent is
      entry Input (Obj : in Begin_Delivery_Order);
      entry Input (Obj : in Begin_Rearm);
      entry Input (Obj : in Transfer_Complete);
      entry Input (Obj : in Transfer_Box_To_Loader);
      entry Input (Obj : in Await_Box_Transfer);
      entry Input (Obj : in Box_Shuttle_Clear);
      entry Input (Obj : in Stow);
      entry Input (Obj : in Ack_Box_Transfer);
   end Agent;

   procedure Get_Box_From_Mag is
   begin
      -- wait for indexing to complete
      declare
         Msg : Aho.Box_Compartment.Index_Complete;
      begin
         Pace.Dispatching.Inout (Msg);
      end;
      declare
         Msg : Extend_Shuttle_To_Mag;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Transfer_Box_To_Shuttle;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Retract_Shuttle;
      begin
         Pace.Dispatching.Input (Msg);
      end;
	  if Tot_Items+1 > 2 then
	    declare
		  Msg : Aho.Box_Compartment.Index_To_Delivery_Position;
		begin
		  Pace.Surrogates.Input (Msg);
		end;
	  else
	    declare
		  Msg : Aho.Box_Compartment.Index_To_Shuttle_Gate;
		begin
		  Pace.Surrogates.Input (Msg);
		end;
	  end if;

   end Get_Box_From_Mag;

   procedure Stow_Equipment is
   begin
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Total_Time := 0.8;
         Msg.Final := Spin_Stow;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Spin_Settle_Time);
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := Extend_Stow;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Translate_Settle_Time);
   end Stow_Equipment;

   type Spin_To_Tag_Station is new Pace.Msg with null record;
   procedure Input (Obj : Spin_To_Tag_Station);
   procedure Input (Obj : Spin_To_Tag_Station) is
   begin
      -- Rotate to 11 degrees outside of Loader Handoff.
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Total_Time := 0.8;
         Msg.Final := Spin_Tag_Standoff;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Spin_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   type Remove_Tag_ID is new Pace.Msg with null record;
   procedure Input (Obj : Remove_Tag_ID);
   procedure Input (Obj : Remove_Tag_ID) is
   begin
      Pace.Log.Wait (0.5); -- replace with actual motion
      Pace.Log.Trace (Obj);
   end Input;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         select
            accept Input (Obj : in Begin_Delivery_Order) do
               Pace.Log.Trace (Obj);
               Items_Complete := 0;
               Tot_Items := Obj.Num_Items;
            end Input;

            declare
               Msg : Spin_Shuttle_To_Compartment;
            begin
               Pace.Dispatching.Input (Msg);
            end;
            loop
               exit when Tot_Items = Items_Complete;

               Get_Box_From_Mag;

               declare
                  use Aho.Timer_Setter;
                  Msg : Timer_Item;
               begin
                  Msg.Item_Number := Items_Complete + 1;
                  -- this returns immediately
                  Pace.Dispatching.Input (Msg);
               end;

               declare
                  Msg : Spin_To_Tag_Station;
               begin
                  Input (Msg);
               end;

               declare
                  Msg : Remove_Tag_ID;
               begin
                  Input (Msg);
               end;

               declare
                  Msg : Spin_Shuttle_To_Loader;
               begin
                  Pace.Dispatching.Input (Msg);
               end;

               -- waits for loader to be ready and for
               -- timer to finish before moving to loader
               accept Input (Obj : in Transfer_Box_To_Loader) do
                  Pace.Log.Trace (Obj);
               end Input;

               declare
                  Msg : Aho.Timer_Setter.Timer_Complete;
               begin
                  Pace.Dispatching.Inout (Msg);
               end;
               declare
                  Msg : Extend_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               accept Input (Obj : in Await_Box_Transfer) do
                  Pace.Log.Trace (Obj);
               end Input;
               declare
                  Msg : Transfer_Box_From_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               accept Input (Obj : in Ack_Box_Transfer) do
                  Pace.Log.Trace (Obj);
               end Input;
               declare
                  Msg : Retract_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               accept Input (Obj : in Box_Shuttle_Clear) do
                  Pace.Log.Trace (Obj);
               end Input;

               Items_Complete := Items_Complete + 1;
               Pace.Log.Put_Line ("Box Item " &
                                  Integer'Image (Items_Complete) & " Loaded");

               if Items_Complete /= Tot_Items then

                  declare
                     Msg : Spin_Shuttle_To_Compartment;
                  begin
                     Pace.Dispatching.Input (Msg);
                  end;
               end if;
            end loop;
            accept Input (Obj : in Stow) do
               Pace.Log.Trace (Obj);
            end Input;
            Stow_Equipment;
         or
            accept Input (Obj : in Begin_Rearm) do
               Pace.Log.Trace (Obj);
               Tot_Items := Obj.Items;
            end Input;
            declare
               use Aho.Resupply_Shuttle;
               Msg : Aho.Resupply_Shuttle.Begin_Rearm;
            begin
               Msg.Clip_Type := 1;
               Msg.Items := Tot_Items;
               Pace.Dispatching.Input (Msg);
            end;
            for I in 1 .. Tot_Items loop
               declare
                  Msg : Spin_To_Resupply_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  use Aho.Resupply_Shuttle;
                  Msg : Ready_To_Transfer_Item;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Extend_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  use Aho.Resupply_Shuttle;
                  Msg : Transfer_Item;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  use Aho.Resupply_Shuttle;
                  Msg : Transfer_Item_Complete;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  use Aho.Box_Shuttle_Grippers;
                  Msg : Close_Box_Shuttle_Grippers;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  use Aho.Resupply_Shuttle;
                  Msg : Ack_Receipt_Of_Item;
               begin
                  Pace.Dispatching.Input (Msg);
               end;

               declare
                  use Aho.Resupply_Shuttle;
                  Msg : Ack_Clear_To_Move;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Retract_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Spin_Shuttle_To_Compartment;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Extend_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Transfer_Box_To_Mag;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Retract_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
            end loop;
            Stow_Equipment;
            accept Input (Obj : in Transfer_Complete) do
               Pace.Log.Trace (Obj);
            end Input;
         end select;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Begin_Delivery_Order) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Box_To_Loader) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Await_Box_Transfer) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Box_Shuttle_Clear) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Stow) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Begin_Rearm) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Complete) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Retrieve_Box) is
   begin
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Ack_Box_Transfer) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Spin_Shuttle_To_Compartment) is
   begin
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Total_Time := 0.8;
         Msg.Final := Spin_Mag_Handoff;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Spin_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Spin_Shuttle_To_Loader) is
   begin
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Total_Time := 0.8;
         Msg.Final := Spin_Loader_Handoff;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Spin_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Spin_To_Resupply_Shuttle) is
   begin
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Total_Time := 0.8;
         Msg.Final := Spin_Resupply_Bottle_Handoff;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Spin_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Extend_Shuttle) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := Extend_Position;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Translate_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Extend_Shuttle_To_Mag) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := (-0.175, 0.0, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Translate_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Retract_Shuttle) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := Retract_Position;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Translate_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Box_To_Shuttle) is
   begin
      Hal.Sms.Set ("ShuttleBox", "on", 0.0);
      declare
         use Aho.Box_Shuttle_Grippers;
         Msg : Close_Box_Shuttle_Grippers;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Engage_Bottle_Shuttle) is
   begin
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Disengage_Bottle_Shuttle) is
   begin
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Store_Box) is
   begin
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Index_Compartment) is
   begin
      declare
         Msg : Aho.Box_Compartment.Index_To_Final_Position;
      begin
         Pace.Surrogates.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;


   procedure Input (Obj : in Transfer_Box_From_Shuttle) is
   begin
      Hal.Sms.Set ("LoadArmBox", "on", 0.0);
      Hal.Sms.Set ("ShuttleBox", "off", 0.0);
      declare
         use Aho.Box_Shuttle_Grippers;
         Msg : Open_Box_Shuttle_Grippers;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Box_From_Resupply) is
   begin
      Hal.Sms.Set ("ShuttleBox", "on", 0.0);
      Hal.Sms.Set ("ResupplyBox", "off", 0.0);
      Hal.Sms.Set ("axis_paddle", "BottleRearmReset", 0.0);
      Pace.Log.Wait (0.3);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Box_To_Mag) is
   begin
      declare
         use Aho.Box_Shuttle_Grippers;
         Msg : Open_Box_Shuttle_Grippers;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      Hal.Sms.Set ("ShuttleBox", "off", 0.0);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Translate_Shuttle) is
      Stopped : Boolean;
      End_Pos : Hal.Position;
      Audio_Msg : Hal.Audio.Mixer.Play_Mix := Make_Audio ("shuttle_translate");
   begin
      End_Pos := (Obj.Final.X, 0.0, 0.0);

      -- starting sound
      Pace.Dispatching.Inout (Audio_Msg);

      Hal.Sms.Translation ("BoxShuttleExtend", (Current_Pos.X, 0.0, 0.0),
                           End_Pos, Obj.Total_Time - Translate_Settle_Time,
                           Stopped, Translate_Ramp_Up, Translate_Ramp_Down);

      -- stopping sound
      Pace.Dispatching.Inout (Audio_Msg);

      Current_Pos.X := End_Pos.X;
   end Input;

   procedure Input (Obj : in Rotate_Shuttle) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation;
   begin
      End_Orn := (0.0, Hal.Rads (Obj.Final.B), 0.0);
      Hal.Sms.Rotation ("BoxShuttleSpin",
                        (0.0, Hal.Rads (Current_Orn.B), 0.0), End_Orn,
                        Obj.Total_Time - Spin_Settle_Time, Stopped,
                        Spin_Ramp_Up, Spin_Ramp_Down);
      Current_Orn.B := Obj.Final.B;
   end Input;

end Aho.Box_Shuttle;
