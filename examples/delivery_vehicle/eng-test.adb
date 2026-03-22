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
with Wmi;
with Vkb;

-- note ... do not with in Aho.Delivery_Handling_Coordinator or
-- Ahm.Delivery_Handling_Coordinator... specific driver should with these in,
-- as Eng.Test works for either (and you don't want both happening at same
-- time!!)

package body Eng.Test is

   use Pace.Server.Dispatch;

   function Id is new Pace.Log.Unit_Id;

   -- used internally when a publish occurs.. essentially makes the publish/subscribe synchronous
   type Job_Done is new Pace.Notify.Subscription with null record;

   -- used for publishing to Delivery_Job_Complete subscription
   type Eng_Delivery_Job_Complete is new
     Ahd.Delivery_Job.Delivery_Job_Complete with null record;
   procedure Input (Obj : in Eng_Delivery_Job_Complete);
   procedure Input (Obj : in Eng_Delivery_Job_Complete) is
   begin
      declare
         Msg : Job_Done;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Input;

   type Trigger_Delivery_Job is new
     Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Trigger_Delivery_Job);

   procedure Do_Trigger_Delivery_Job (Job_Id : Integer) is
   begin
      Wmi.Call (Query => "mxr.delivery_order.call_for_delivery",
                Params => Vkb.Rules.S (Job_Id));

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
      declare
         Msg : Job_Done;
      begin
         Pace.Log.Put_Line ("Eng.Test is waiting for delivery job to complete");
         Inout (Msg);
         Pace.Log.Put_Line ("eng is done waiting for job to complete");
      end;

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

   end Do_Trigger_Delivery_Job;

   task Agent is
      entry Inout (Obj : in out Trigger_Delivery_Job);
   end Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);

      -- subscribe to Delivery_Job_Complete subscription
      declare
         use Ahd.Delivery_Job;
         Msg : Eng_Delivery_Job_Complete;
      begin
         Ahd.Delivery_Job.Input (Delivery_Job_Complete (Msg));
      end;

      loop
         accept Inout (Obj : in out Trigger_Delivery_Job) do
            Do_Trigger_Delivery_Job (Integer'Value (+Obj.Set));
         end Inout;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Inout (Obj : in out Trigger_Delivery_Job) is
   begin
      Agent.Inout (Obj);
   end Inout;


begin
   Save_Action (Trigger_Delivery_Job'(Pace.Msg with Set => +""));
end Eng.Test;
