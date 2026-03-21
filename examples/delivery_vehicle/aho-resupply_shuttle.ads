with Pace;
with Pace.Log;
with Hal;

package Aho.Resupply_Shuttle is


  type Begin_Rearm is new Pace.Msg with
  record
    Clip_Type : Integer;
	Items : Integer;
  end record;
  procedure Input (Obj : in Begin_Rearm);
  
  type Ack_Receipt_Of_Item is new Pace.Msg with null record;
  procedure Input (Obj : in Ack_Receipt_Of_Item);

  type Transfer_Item_Complete is new Pace.Msg with null record;
  procedure Input (Obj : in Transfer_Item_Complete);

  type Ack_Clear_To_Move is new Pace.Msg with null record;
  procedure Input (Obj : in Ack_Clear_To_Move);

  type Transfer_Item is new Pace.Msg with null record;
  procedure Input (Obj : in Transfer_Item);

  type Ready_To_Transfer_Item is new Pace.Msg with null record;
  procedure Input (Obj : in Ready_To_Transfer_Item);
  
  type Transfer_Item_To_Shuttle is new Pace.Msg with null record;
  procedure Input (Obj : in Transfer_Item_To_Shuttle);

  type Transfer_Item_From_Clip is new Pace.Msg with null record;
  procedure Input (Obj : in Transfer_Item_From_Clip);

  type Move_Shuttle_To_Box_Shuttle is new Pace.Msg with null record;
  procedure Input (Obj : in Move_Shuttle_To_Box_Shuttle);

  type Move_Shuttle_To_Bottle_Shuttle is new Pace.Msg with null record;
  procedure Input (Obj : in Move_Shuttle_To_Bottle_Shuttle);

  type Elevate_To_Box_Shuttle is new Pace.Msg with null record;
  procedure Input (Obj : in Elevate_To_Box_Shuttle);

  type Elevate_To_Bottle_Shuttle is new Pace.Msg with null record;
  procedure Input (Obj : in Elevate_To_Bottle_Shuttle);

  type Elevate_To_Clip is new Pace.Msg with null record;
  procedure Input (Obj : in Elevate_To_Clip);

  type Flip_Shuttle_To_Clip is new Pace.Msg with null record;
  procedure Input (Obj : in Flip_Shuttle_To_Clip);

  type Flip_Shuttle_To_P_Shuttle is new Pace.Msg with null record;
  procedure Input (Obj : in Flip_Shuttle_To_P_Shuttle);

  type Extend_To_Clip is new Pace.Msg with null record;
  procedure Input (Obj : in Extend_To_Clip);

  type Extend_To_Bottle_Shuttle is new Pace.Msg with null record;
  procedure Input (Obj : in Extend_To_Bottle_Shuttle);

  type Extend_To_Box_Shuttle is new Pace.Msg with null record;
  procedure Input (Obj : in Extend_To_Box_Shuttle);
  
  type Move_Shuttle_To_Clip is new Pace.Msg with null record;
  procedure Input (Obj : in Move_Shuttle_To_Clip);
  
  type Translate_Shuttle is new Pace.Msg with
      record
         Final : Hal.Position;
         Speed : Float;
         Axis : Character;
      end record;
   procedure Input (Obj : in Translate_Shuttle);

   type Rotate_Shuttle is new Pace.Msg with
      record
         Final : Hal.Orientation;
         Speed : Float;
         Axis : Character;
      end record;
   procedure Input (Obj : in Rotate_Shuttle);

private
   pragma Inline (Input);

end Aho.Resupply_Shuttle;
