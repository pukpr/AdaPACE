with Pace;
with Hal;

package Aho.Box_Shuttle is

   pragma Elaborate_Body;

   type Begin_Delivery_Order is new Pace.Msg with
      record
         Num_Items : Integer;
      end record;
   procedure Input (Obj : in Begin_Delivery_Order);

   type Transfer_Box_To_Loader is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Box_To_Loader);

   type Await_Box_Transfer is new Pace.Msg with null record;
   procedure Input (Obj : in Await_Box_Transfer);

   type Box_Shuttle_Clear is new Pace.Msg with null record;
   procedure Input (Obj : in Box_Shuttle_Clear);

   type Stow is new Pace.Msg with null record;
   procedure Input (Obj : in Stow);

   type Ack_Box_Transfer is new Pace.Msg with null record;
   procedure Input (Obj : in Ack_Box_Transfer);

   type Begin_Rearm is new Pace.Msg with
      record
         Items : Integer;
      end record;
   procedure Input (Obj : in Begin_Rearm);

   type Transfer_Complete is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Complete);

   type Retrieve_Box is new Pace.Msg with null record;
   procedure Input (Obj : in Retrieve_Box);

   type Spin_Shuttle_To_Compartment is new Pace.Msg with null record;
   procedure Input (Obj : in Spin_Shuttle_To_Compartment);

   type Spin_Shuttle_To_Loader is new Pace.Msg with null record;
   procedure Input (Obj : in Spin_Shuttle_To_Loader);

   type Spin_To_Resupply_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Spin_To_Resupply_Shuttle);

   type Extend_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Extend_Shuttle);

   type Extend_Shuttle_To_Mag is new Pace.Msg with null record;
   procedure Input (Obj : in Extend_Shuttle_To_Mag);

   type Retract_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Retract_Shuttle);

   type Transfer_Box_To_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Box_To_Shuttle);

   type Transfer_Box_From_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Box_From_Shuttle);

   type Transfer_Box_From_Resupply is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Box_From_Resupply);

   type Transfer_Box_To_Mag is new Pace.Msg with null record;
   procedure Input (Obj : in Transfer_Box_To_Mag);

   type Engage_Bottle_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Engage_Bottle_Shuttle);

   type Disengage_Bottle_Shuttle is new Pace.Msg with null record;
   procedure Input (Obj : in Disengage_Bottle_Shuttle);

   type Store_Box is new Pace.Msg with null record;
   procedure Input (Obj : in Store_Box);
   
   type Index_Compartment is new Pace.Msg with null record;
   procedure Input (Obj : in Index_Compartment);

private
   pragma Inline (Input);

end Aho.Box_Shuttle;
