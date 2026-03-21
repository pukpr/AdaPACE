with Pace;
with Pace.Log;
with Pace.Surrogates;
with Hal;
with Hal.Sms;
with Hal.Audio.Mixer;
with Ada.Numerics;

with Aho.Bottle_Compartment;
with Aho.Resupply_Shuttle;
with Aho.Bottle_Shuttle_Grippers;

package body Aho.Bottle_Shuttle is

   function Id is new Pace.Log.Unit_Id;

   -- TransFlip orientations
   Spin_Standoff_Orn : constant Hal.Orientation := (0.0, 0.0, 0.0);
   Extend_Standoff_Pos : constant Hal.Position := (0.0, 0.0, 0.0);

   Box : constant Integer := 1;
   Bottle : constant Integer := 2;
   Nil : constant Integer := 0;
   Spin_Rate : constant Float := Hal.Rads (300.0);

   Current_Extend_Pos : Hal.Position := Extend_Standoff_Pos;
   Current_Spin_Orn : Hal.Orientation := Spin_Standoff_Orn;
   Current_Hor_Pos : Hal.Position := (0.0, 0.0, 0.0);
   Current_Vert_Pos : Hal.Position := (0.0, 0.0, 0.0);

   Tot_Items : Integer;
   Items_Complete : Integer := 0;
   Cell_Index : Integer := 1;
   Inventory_Id : Integer := 1;

   Translate_Ramp_Up : constant Duration := 0.1921;
   Translate_Ramp_Down : constant Duration := 0.1921;
   Translate_Settle_Time : constant Duration := 0.1153;
   Spin_Ramp_Up : constant Duration := 0.2262;
   Spin_Ramp_Down : constant Duration := 0.2262;
   Spin_Settle_Time : constant Duration := 0.1357;

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
      entry Input (Obj : in Transfer_Bottle_To_Loader);
      entry Input (Obj : in Await_Bottle_Transfer);
      entry Input (Obj : in Bottle_Shuttle_Clear);
      entry Input (Obj : in Begin_Rearm);
      entry Input (Obj : in Ack_Bottle_Transfer);
      entry Input (Obj : in Transfer_Complete);
   end Agent;

   procedure Get_Bottle is
   begin
      -- wait for indexing to complete
      declare
         Msg : Aho.Bottle_Compartment.Index_Complete;
      begin
         Pace.Dispatching.Inout (Msg);
      end;
      declare
         Msg : Spin_To_Mag;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Extend_Shuttle;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Transfer_Bottle_To_Shuttle;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Retract_Shuttle;
      begin
         Pace.Dispatching.Input (Msg);
      end;
	  --  Index Compartment to apbottleriate position
      if Items_Complete+1 = 1 then
         declare
            Msg : Aho.Bottle_Compartment.Index_To_Shuttle_Gate;
         begin
            Pace.Surrogates.Input (Msg);
         end;
      else
         declare
            Msg : Aho.Bottle_Compartment.Index_To_Delivery_Position;
         begin
            Pace.Surrogates.Input (Msg);
         end;
      end if;

      declare
         Msg : Spin_To_Loader;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Get_Bottle;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         select
            accept Input (Obj : in Begin_Delivery_Order) do
               Pace.Log.Trace (Obj);
               Tot_Items := Obj.Num_Items;
               Items_Complete := 0;
            end Input;

            loop
               Get_Bottle;
               -- wait until loader has lowered and signalled to do transfer
               accept Input (Obj : in Transfer_Bottle_To_Loader) do
                  Pace.Log.Trace (Obj);
               end Input;
               declare
                  Msg : Extend_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               accept Input (Obj : in Await_Bottle_Transfer) do
                  Pace.Log.Trace (Obj);
               end Input;
               declare
                  Msg : Transfer_Bottle_From_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               -- Wait for Loader Door to Close
               accept Input (Obj : in Ack_Bottle_Transfer) do
                  Pace.Log.Trace (Obj);
               end Input;
               declare
                  use Aho.Bottle_Shuttle_Grippers;
                  Msg : Open_Bottle_Shuttle_Grippers;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Retract_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               accept Input (Obj : in Bottle_Shuttle_Clear) do
                  Pace.Log.Trace (Obj);
               end Input;
               Items_Complete := Items_Complete + 1;

               Pace.Log.Put_Line ("Bottle Item " &
                                  Integer'Image (Items_Complete) & " Loaded");

               exit when Tot_Items = Items_Complete;

            end loop;
            declare
               Msg : Spin_To_Mag;
            begin
               Pace.Dispatching.Input (Msg);
            end;
            Pace.Log.Wait (4.0);
            Pace.Log.Put_Line ("bottle shuttle completed mission");

         or

            accept Input (Obj : in Begin_Rearm) do
               Pace.Log.Trace (Obj);
               Tot_Items := Obj.Items;
            end Input;
            declare
               Msg : Aho.Resupply_Shuttle.Begin_Rearm;
            begin
               Msg.Clip_Type := 2;
               Msg.Items := Tot_Items;
               Pace.Dispatching.Input (Msg);
               Pace.Log.Put_Line ("BOTTLE Calling Resupply Shuttle");
            end;
            for I in 1 .. Tot_Items loop
               declare
                  Msg : Spin_To_Resupply;
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
                  use Aho.Bottle_Shuttle_Grippers;
                  Msg : Close_Bottle_Shuttle_Grippers;
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
                  Msg : Spin_To_Mag;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Extend_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  use Aho.Bottle_Shuttle_Grippers;
                  Msg : Open_Bottle_Shuttle_Grippers;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Resupply_Bottle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               declare
                  Msg : Retract_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
            end loop;
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

   procedure Input (Obj : in Transfer_Bottle_To_Loader) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Await_Bottle_Transfer) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Bottle_Shuttle_Clear) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Begin_Rearm) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Ack_Bottle_Transfer) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Complete) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Move_To_Clip) is
   begin
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Extend_Shuttle) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Total_Time := 0.7;
         Msg.Final := (0.170, 0.0, 0.0);
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
         Msg.Final := Extend_Standoff_Pos;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Translate_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;


   procedure Input (Obj : in Spin_To_Loader) is
   begin
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Total_Time := 0.8;
         Msg.Final := (0.0, -98.141, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Spin_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Spin_To_Mag) is
   begin
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Total_Time := 0.8;
         Msg.Final := Spin_Standoff_Orn;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Spin_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Spin_To_Resupply) is
   begin
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Total_Time := 0.8;
         Msg.Final := (0.0, -90.0, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Spin_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Bottle_From_Shuttle) is
   begin
      Hal.Sms.Set ("LoadArmBottle", "on", 0.0);
      Hal.Sms.Set ("BottleShuttleBottle", "off", 0.0);
      Pace.Log.Wait (0.8);
--        declare
--           use Aho.Bottle_Shuttle_Grippers;
--           Msg : Open_Bottle_Shuttle_Grippers;
--        begin
--           Pace.Dispatching.Input (Msg);
--        end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Bottle_To_Shuttle) is
   begin
      Hal.Sms.Set ("BottleShuttleBottle", "on", 0.0);
      declare
         use Aho.Bottle_Shuttle_Grippers;
         Msg : Close_Bottle_Shuttle_Grippers;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Resupply_Bottle) is
   begin
      Hal.Sms.Set ("BottleShuttleBottle", "off", 0.0);
--      Hal.Sms.Set ("axis_paddle", "BottleRearmReset", 0.0);
      Pace.Log.Wait (0.75);
      Pace.Log.Trace (Obj);
   end Input;
   procedure Input (Obj : in Extract_Box) is
   begin
      Hal.Sms.Set ("ResupplyBox", "on", 0.0);
      --Hal.Sms.Set ("axis_paddle", "RearmfromClip");  ????  Comment out or in Other Vdifile?
      Pace.Log.Wait (0.75);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Resupply_Box) is
   begin
--      Hal.Sms.Set ("BottleShuttleBottle", "off", 0.0);
--      Hal.Sms.Set ("axis_paddle", "BottleRearmReset");
      Pace.Log.Wait (0.75);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Index_Compartment) is
   begin
      declare
         Msg : Aho.Bottle_Compartment.Index_To_Final_Position;
      begin
         Pace.Surrogates.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Translate_Shuttle) is
      Stopped : Boolean;
      End_Pos : Hal.Position := Obj.Final;
      Audio_Msg : Hal.Audio.Mixer.Play_Mix := Make_Audio ("shuttle_translate");
   begin
      -- starting sound
      Pace.Dispatching.Inout (Audio_Msg);

      Hal.Sms.Translation ("BottleShuttleExtend", Current_Extend_Pos, End_Pos,
                           Obj.Total_Time - Translate_Settle_Time, Stopped,
                           Translate_Ramp_Up, Translate_Ramp_Down);

      -- stopping sound
      Pace.Dispatching.Inout (Audio_Msg);

      Current_Extend_Pos := End_Pos;
   end Input;

   procedure Input (Obj : in Rotate_Shuttle) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation;
   begin
      End_Orn := (0.0, Hal.Rads (Obj.Final.B), 0.0);
      Hal.Sms.Rotation ("BottleShuttleSpin",
                        (0.0, Hal.Rads (Current_Spin_Orn.B), 0.0), End_Orn,
                        Obj.Total_Time - Spin_Settle_Time, Stopped,
                        Spin_Ramp_Up, Spin_Ramp_Down);
      Current_Spin_Orn.B := Obj.Final.B;
   end Input;

end Aho.Bottle_Shuttle;
