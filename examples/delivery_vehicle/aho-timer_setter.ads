with Pace;
with Pace.Notify;

package Aho.Timer_Setter is

   pragma Elaborate_Body;

   type Timer_Item is new Pace.Msg with
      record
         Item_Number : Integer;
      end record;
   procedure Input (Obj : in Timer_Item);

   type Timer_Complete is new Pace.Notify.Subscription with null record;

end Aho.Timer_Setter;
