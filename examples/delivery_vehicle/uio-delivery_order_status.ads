with Pace;
with Pace.Server.Dispatch;

package Uio.Delivery_Order_Status is

   pragma Elaborate_Body;

-- Action Requests

   type Update_Delivery_Mission is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Update_Delivery_Mission);

   type Get_Current_Item is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Current_Item);

   type Clear_Delivery_Mission is new Pace.Msg with null record;
   procedure Input (Obj : in Clear_Delivery_Mission);

-- Commands


private
   pragma Inline (Output);
   -- $Id: uio-delivery_order_status.ads,v 1.10 2004/09/20 22:18:13 pukitepa Exp $
end Uio.Delivery_Order_Status;
