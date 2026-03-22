with Pace;
with Pace.Server.Dispatch;

package Uio.Job_Order_Status is

   pragma Elaborate_Body;

-- Action Requests

   type Update_Delivery_Job is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Update_Delivery_Job);

   type Get_Current_Item is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Current_Item);

   type Clear_Delivery_Job is new Pace.Msg with null record;
   procedure Input (Obj : in Clear_Delivery_Job);

-- Commands


private
   pragma Inline (Output);
end Uio.Job_Order_Status;
