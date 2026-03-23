with Pace.Server.Html;
with Pace.Server.Dispatch;
with Pace.Server;
with Pace.Notify;
with Pace.Log;
with Pace.Strings; use Pace.Strings;
with Uio.State.Deliver;
with Mxr.Delivery_Order;
with Ahd.Delivery_Job;
with Ahd;
with Ahd.Job_Order_Status;
with Vkb;

procedure Drone is

   use Pace.Server.Dispatch;

begin
      Pace.Log.Agent_ID;
      

--      Wmi.Call (Query => "mxr.delivery_order.call_for_delivery",
--                Params => Vkb.Rules.S (Job_Id));

      declare
         Msg : mxr.delivery_order.call_for_delivery;
      begin
         -- Msg.Set := +"1";
         Pace.Dispatching.Inout (Msg);
      end;


      declare
         Msg : Mxr.Delivery_Order.Is_Delivery_Order_Received;
      begin
         Pace.Dispatching.Inout (Msg);
         if not Msg.Val then
            declare
               Msg : Mxr.Delivery_Order.Wait_For_Job_Received;
            begin
               Pace.Dispatching.Inout (Msg);
            end;
         end if;
      end;

      declare
         Msg : Uio.State.Deliver.Next_State;
      begin
         Msg.Set := +"ACKNOWLEDGE";
         Pace.Dispatching.Inout (Msg);
      end;

      declare
         Msg : Uio.State.Deliver.Next_State;
      begin
         Msg.Set := +"EMPLACE";
         Pace.Dispatching.Inout (Msg);
      end;

      declare
         Msg : Uio.State.Deliver.Next_State;
      begin
         Msg.Set := +"ATTEMPT_CONFIGURE_EQUIPMENT";
         Pace.Dispatching.Inout (Msg);
      end;

      declare
         Msg : Uio.State.Deliver.Next_State;
      begin
         Msg.Set := +"ENABLE";
         Pace.Dispatching.Inout (Msg);
      end;

      -- wait for end of delivery job from ahd before moving on
--      declare
--         Msg : Job_Done;
--      begin
--         Pace.Log.Put_Line ("Eng.Test is waiting for delivery job to complete");
--         Inout (Msg);
--         Pace.Log.Put_Line ("eng is done waiting for job to complete");
--      end;

      declare
         Msg : Uio.State.Deliver.Next_State;
      begin
         Msg.Set := +"ITEMS_COMPLETE";
         Pace.Dispatching.Inout (Msg);
      end;

      declare
         Msg : Uio.State.Deliver.Next_State;
      begin
         Msg.Set := +"CLEAR_ITEMS_COMPLETE";
         Pace.Dispatching.Inout (Msg);
      end;


end Drone;
