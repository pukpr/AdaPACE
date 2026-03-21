with Pace;
with Pace.Notify;
with Pace.Log;
with Hal;

package Aho.Bottle_Shuttle is

   pragma Elaborate_Body;

   type Begin_Delivery_Order is new Pace.Msg with
      record
         Num_Items : Integer;
      end record;
   procedure Input (Obj : in Begin_Delivery_Order);

   type Begin_Rearm is new Pace.Msg with
      record
         Items : Integer;
      end record;
   procedure Input (Obj : in Begin_Rearm);

   type Await_Bottle_Transfer is new Pace.Msg with null record;
   procedure Input (Obj : in Await_Bottle_Transfer);

   type Ack_Bottle_Transfer is new Pace.Msg with null record;
   procedure Input (Obj : in Ack_Bottle_Transfer);

   type Bottle_Shuttle_Clear is new Pace.Msg with null record;
   procedure Input (Obj : in Bottle_Shuttle_Clear);

   type Transfer_Bottle_To_Loader is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Bottle_To_Loader);

   type Transfer_Complete is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Complete);

   -- notify signal given to let the loader know that the bottle shuttle is
   -- done accessing the compartment and the loader can lower now
   type Clear_For_Loader_To_Lower is new
     Pace.Notify.Subscription with null record;

   type Extend_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Extend_Shuttle);


   type Move_To_Clip is new Pace.Msg with
      record
         Col_Index : Integer;
         Row_Index : Integer;
      end record;
   procedure Input (Obj : in Move_To_Clip);

   type Extract_Box is new Pace.Msg with null record;
   procedure Input (Obj : in Extract_Box);

   type Resupply_Bottle is new Pace.Msg with null record;
   procedure Input (Obj : in Resupply_Bottle);

   type Resupply_Box is new Pace.Msg with null record;
   procedure Input (Obj : in Resupply_Box);

   type Spin_To_Mag is new Pace.Msg with null record;
   procedure Input (Obj : in Spin_To_Mag);

   type Spin_To_Loader is new Pace.Msg with null record;
   procedure Input (Obj : in Spin_To_Loader);

   type Spin_To_Resupply is new Pace.Msg with null record;
   procedure Input (Obj : in Spin_To_Resupply);

   type Transfer_Bottle_To_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Bottle_To_Shuttle);

   type Retract_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Retract_Shuttle);

   type Transfer_Bottle_From_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Bottle_From_Shuttle);

   type Index_Compartment is new Pace.Msg with null record;
   procedure Input (Obj : in Index_Compartment);

private
   pragma Inline (Input);

end Aho.Bottle_Shuttle;
