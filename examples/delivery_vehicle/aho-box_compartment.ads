with Hal;
with Pace;
with Pace.Notify;

package Aho.Box_Compartment is

   pragma Elaborate_Body;

   type Select_Box_Completed is new Pace.Notify.Subscription with
      record
         Available_Slot : Integer;
      end record;

   type Select_Box is new Pace.Msg with
      record
         Slot_Num : Integer;
      end record;
   procedure Input (Obj : Select_Box);

   type Increment_Slot is new Pace.Msg with
      record
         Which_Way : Hal.Rotation_Direction;
      end record;
   procedure Input (Obj : Increment_Slot);

   type Abort_Selection is new Pace.Msg with null record;
   procedure Input (Obj : Abort_Selection);

   type Open_Door is new Pace.Msg with null record;
   procedure Input (Obj : in Open_Door);

   type Close_Door is new Pace.Msg with null record;
   procedure Input (Obj : in Close_Door);

--    type Index_Compartment is new Pace.Msg with null record;
--    procedure Input (Obj : in Index_Compartment);
   
   type Index_To_Delivery_Position is new Pace.Msg with null record;
   procedure Input (Obj : in Index_To_Delivery_Position);

   type Index_To_Shuttle_Gate is new Pace.Msg with null record;
   procedure Input (Obj : in Index_To_Shuttle_Gate);

   type Index_To_Final_Position is new Pace.Msg with null record;
   procedure Input (Obj : in Index_To_Final_Position);

   type Index_Complete is new Pace.Notify.Subscription with null record;

private

   pragma Inline (Input);

end Aho.Box_Compartment;
