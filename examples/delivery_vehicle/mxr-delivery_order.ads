with Pace;
with Pace.Notify;
with Pace.Server.Dispatch;
with Str;

package Mxr.Delivery_Order is
   pragma Elaborate_Body;

   type Is_Delivery_Order_Received is new Pace.Msg with
      record
         Val : Boolean := False;
      end record;
   procedure Inout (Obj : in out Is_Delivery_Order_Received);

   -- signals that the job has been received
   type Wait_For_Job_Received is new
     Pace.Notify.Subscription with null record;

   type Clear_Delivery_Order_Received is new Pace.Msg with null record;
   procedure Input (Obj : in Clear_Delivery_Order_Received);

   -- may schedule delivery job
   type Call_For_Delivery is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Call_For_Delivery);

   -- adds a delivery job directly to queue
   procedure Add_To_Queue (Job_Id : Str.Bstr.Bounded_String);

private
   pragma Inline (Input);
end Mxr.Delivery_Order;

