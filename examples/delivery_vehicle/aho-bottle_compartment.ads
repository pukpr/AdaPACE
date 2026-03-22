with Pace;
with Pace.Notify;

package Aho.Bottle_Compartment is

   pragma Elaborate_Body;

   use Hal;

   type Index_Compartment is new Pace.Msg with
      record
         Item : Integer;
      end record;
   procedure Input (Obj : in Index_Compartment);

   type Index_To_Delivery_Position is new Pace.Msg with null record;
   procedure Input (Obj : in Index_To_Delivery_Position);

   type Index_To_Shuttle_Gate is new Pace.Msg with null record;
   procedure Input (Obj : in Index_To_Shuttle_Gate);

   type Index_To_Final_Position is new Pace.Msg with null record;
   procedure Input (Obj : in Index_To_Final_Position);

   type Index_Complete is new Pace.Notify.Subscription with null record;

private
   pragma Inline (Input);

end Aho.Bottle_Compartment;
