with Pace;
with Pace.Log;
with Pace.Surrogates;
with Hal;
with Hal.Sms;
with Ada.Numerics;
with Aho.Resupply_Clip;

package body Aho.Resupply_Shuttle is

   function Id is new Pace.Log.Unit_Id;

   -- Standoff is same as stow position;

   Extend_Standoff_Pos : Hal.Position := (0.0, 0.0, 0.0);
   Hor_Standoff_Pos : Hal.Position := (0.0, 0.0, 0.0);
   Vert_Standoff_Pos : Hal.Position := (0.0, 0.0, 0.0);
   Flip_Standoff_Orn : Hal.Orientation := (0.0, 0.0, 0.0);

   Current_Extend_Pos : Hal.Position := Extend_Standoff_Pos;
   Current_Hor_Pos : Hal.Position := Hor_Standoff_Pos;
   Current_Vert_Pos : Hal.Position := Vert_Standoff_Pos;
   Current_Flip_Orn : Hal.Orientation := Flip_Standoff_Orn;

   Spin_Rate : constant Float := Hal.Rads (300.0);
   Items : Integer := 0;
   Inventory_Id : Integer;
   Index : Integer;

   task Agent is
      entry Input (Obj : in Begin_Rearm);
      entry Input (Obj : in Transfer_Item);
      entry Input (Obj : in Ack_Receipt_Of_Item);
      entry Input (Obj : in Ack_Clear_To_Move);
      entry Input (Obj : in Transfer_Item_Complete);
      entry Input (Obj : in Ready_To_Transfer_Item);
   end Agent;

   procedure Unstow_Shuttle is
   begin
      declare
         Msg : Aho.Resupply_Clip.Next_Cell;
      begin
         Msg.Cell := Index;
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Move_Shuttle_To_Clip;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Unstow_Shuttle;

   procedure Get_Inventory_From_Clip is
   begin
      declare
         Msg : Transfer_Item_From_Clip;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Elevate_To_Bottle_Shuttle;
      begin
         Pace.Surrogates.Input (Msg);
      end;
      Pace.Log.Wait (0.25);
      declare
         Msg : Aho.Resupply_Clip.Next_Cell;
      begin
         Msg.Cell := Index;
         Pace.Surrogates.Input (Msg);
      end;
      declare
         Msg : Flip_Shuttle_To_P_Shuttle;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      if Inventory_Id = 1 then
         declare
            Msg : Move_Shuttle_To_Box_Shuttle;
         begin
            Pace.Dispatching.Input (Msg);
         end;
      else
         declare
            Msg : Move_Shuttle_To_Bottle_Shuttle;
         begin
            Pace.Dispatching.Input (Msg);
         end;
      end if;
   end Get_Inventory_From_Clip;


   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         accept Input (Obj : in Begin_Rearm) do
            Pace.Log.Trace (Obj);
            Items := Obj.Items;
            Index := 1;
            Inventory_Id := Obj.Clip_Type;
            Pace.Log.Put_Line ("ITEMS is " & Integer'Image (Items));
            Pace.Log.Put_Line ("CLIP_TYPE is " & Integer'Image (Inventory_Id));
         end Input;
         Unstow_Shuttle;
         for I in 1 .. Items loop
            Get_Inventory_From_Clip;
            accept Input (Obj : in Ready_To_Transfer_Item) do
               Pace.Log.Trace (Obj);
            end Input;
            accept Input (Obj : in Transfer_Item) do
               Pace.Log.Trace (Obj);
            end Input;
            if Inventory_Id = 1 then
               declare
                  Msg : Extend_To_Box_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
            else
               declare
                  Msg : Extend_To_Bottle_Shuttle;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
            end if;
            declare
               Msg : Transfer_Item_To_Shuttle;
            begin
               Pace.Dispatching.Input (Msg);
            end;
            accept Input (Obj : in Transfer_Item_Complete) do
               Pace.Log.Trace (Obj);
            end Input;
            accept Input (Obj : in Ack_Receipt_Of_Item) do
               Pace.Log.Trace (Obj);
            end Input;
            declare
               Msg : Extend_To_Clip;
            begin
               Pace.Dispatching.Input (Msg);
            end;
            accept Input (Obj : in Ack_Clear_To_Move) do
               Pace.Log.Trace (Obj);
            end Input;
            declare
               Msg : Move_Shuttle_To_Clip;
            begin
               Pace.Dispatching.Input (Msg);
            end;
--                      declare
--                        Msg : Elevate_To_Bottle_Shuttle;
--                      begin
--                        Pace.Dispatching.Input (Msg);
--                      end;
            declare
               Msg : Flip_Shuttle_To_Clip;
            begin
               Pace.Surrogates.Input (Msg);
            end;
            Pace.Log.Wait (0.15);
            declare
               Msg : Elevate_To_Clip;
            begin
               Pace.Dispatching.Input (Msg);
            end;
            Pace.Log.Wait (0.5);
            if Index < 9 then
               Index := Index + 1;
            else
               Index := 1;
            end if;
         end loop;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Begin_Rearm) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Item_Complete) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Ready_To_Transfer_Item) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Ack_Receipt_Of_Item) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Item) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Ack_Clear_To_Move) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Item_To_Shuttle) is
   begin
      if Inventory_Id = 1 then
         Hal.Sms.Set ("ShuttleBox", "on", 0.0);
         Hal.Sms.Set ("resupply_box", "off", 0.0);
      else
         Hal.Sms.Set ("BottleShuttleBottle", "on", 0.0);
         Hal.Sms.Set ("resupply_bottle", "off", 0.0);
      end if;
      Pace.Log.Wait (0.35);
      if Inventory_Id = 1 then
         Hal.Sms.Set ("resupply_box", "reset", 0.0);
      else
         Hal.Sms.Set ("resupply_bottle", "reset", 0.0);
      end if;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Transfer_Item_From_Clip) is
   begin
      if Inventory_Id = 1 then
         Hal.Sms.Set ("resupply_box", "on", 0.0);
         Hal.Sms.Set ("resupply_box", "move_to_shuttle", 1.0);
      else
         Hal.Sms.Set ("resupply_bottle", "on", 0.0);
         Hal.Sms.Set ("resupply_bottle", "move_to_shuttle", 1.0);
      end if;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Move_Shuttle_To_Clip) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Axis := 'X';
         Msg.Speed := 1.1;
         Msg.Final := Hor_Standoff_Pos;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Move_Shuttle_To_Box_Shuttle) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Axis := 'X';
         Msg.Speed := 1.1;
         Msg.Final := (-0.154, 0.0, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Move_Shuttle_To_Bottle_Shuttle) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Axis := 'X';
         Msg.Speed := 1.1;
         Msg.Final := (0.105, 0.0, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Elevate_To_Box_Shuttle) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Axis := 'Y';
         Msg.Speed := 1.1;
         Msg.Final := (0.0, 0.0, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Elevate_To_Bottle_Shuttle) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Axis := 'Y';
         Msg.Speed := 1.1;
         Msg.Final := (0.0, 0.6405, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Elevate_To_Clip) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Axis := 'Y';
         Msg.Speed := 1.1;
         Msg.Final := (0.0, 0.0, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Flip_Shuttle_To_Clip) is
   begin
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Axis := 'X';
         Msg.Speed := Spin_Rate;
         Msg.Final := Flip_Standoff_Orn;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Flip_Shuttle_To_P_Shuttle) is
   begin
      declare
         Msg : Rotate_Shuttle;
      begin
         Msg.Axis := 'X';
         Msg.Speed := Spin_Rate;
         Msg.Final := (90.0, 0.0, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Extend_To_Clip) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Axis := 'Z';
         Msg.Speed := 1.1;
         Msg.Final := (0.0, 0.0, 0.0);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Extend_To_Bottle_Shuttle) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Axis := 'Z';
         Msg.Speed := 1.1;
         Msg.Final := (0.0, 0.0, 0.935);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Extend_To_Box_Shuttle) is
   begin
      declare
         Msg : Translate_Shuttle;
      begin
         Msg.Axis := 'Z';
         Msg.Speed := 1.1;
         Msg.Final := (0.0, 0.0, 0.862);
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;



   procedure Input (Obj : in Translate_Shuttle) is
      Stopped : Boolean;
      End_Pos : Hal.Position := Obj.Final;
      Rate : Hal.Rate;
   begin
      Rate.Units := Obj.Speed;
      if Obj.Axis = 'x' or else Obj.Axis = 'X' then
         Hal.Sms.Translation ("res_trans_x", Current_Hor_Pos,
                              End_Pos, Rate, Stopped);
         Current_Hor_Pos := End_Pos;
      elsif Obj.Axis = 'y' or else Obj.Axis = 'Y' then
         Hal.Sms.Translation ("res_trans_y", Current_Vert_Pos,
                              End_Pos, Rate, Stopped);
         Current_Vert_Pos := End_Pos;
      else
         Hal.Sms.Translation ("res_trans_z", Current_Extend_Pos,
                              End_Pos, Rate, Stopped);
         Current_Extend_Pos := End_Pos;
      end if;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Rotate_Shuttle) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation;
      Rate : Hal.Rate;
   begin
      if Obj.Axis = 'X' or else Obj.Axis = 'x' then
         End_Orn := (Hal.Rads (Obj.Final.A), 0.0, 0.0);
         Rate.Units := Obj.Speed;
         Hal.Sms.Rotation
           ("res_flip", (Hal.Rads (Current_Flip_Orn.A), 0.0, 0.0),
            End_Orn, Rate, Stopped, 0.0, 0.0);
         Current_Flip_Orn.A := Obj.Final.A;
      end if;
      Pace.Log.Trace (Obj);
   end Input;

end Aho.Resupply_Shuttle;
