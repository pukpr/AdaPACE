with Pace.Server.Html;
with Pace.Server.Dispatch;
with Pace.Server;
with Pace.Notify;
with Pace.Log;
with Pace.Strings; use Pace.Strings;

with Uio.State.Deliver;
with Mxr.Delivery_Order;
with Ahd.Delivery_Mission;
with Ahd;
with Ahd.Delivery_Order_Status;
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
   type Fm_Done is new Pace.Notify.Subscription with null record;

   -- used for publishing to Delivery_Mission_Complete subscription
   type Eng_Delivery_Mission_Complete is new
     Ahd.Delivery_Mission.Delivery_Mission_Complete with null record;
   procedure Input (Obj : in Eng_Delivery_Mission_Complete);
   procedure Input (Obj : in Eng_Delivery_Mission_Complete) is
   begin
      declare
         Msg : Fm_Done;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Input;

   type Trigger_Delivery_Mission is new
     Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Trigger_Delivery_Mission);

   procedure Do_Trigger_Delivery_Mission (Mission_Id : Integer) is
   begin
      Wmi.Call (Query => "mxr.delivery_order.call_for_delivery",
                Params => Vkb.Rules.S (Mission_Id));

      declare
         Msg : Mxr.Delivery_Order.Is_Delivery_Order_Received;
      begin
         Pace.Dispatching.Inout (Msg);
         if not Msg.Val then
            declare
               Msg : Mxr.Delivery_Order.Wait_For_Mission_Received;
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

      -- wait for end of delivery mission from ahd before moving on
      declare
         Msg : Fm_Done;
      begin
         Pace.Log.Put_Line ("Eng.Test is waiting for delivery mission to complete");
         Inout (Msg);
         Pace.Log.Put_Line ("eng is done waiting for fm to complete");
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

   end Do_Trigger_Delivery_Mission;

   task Agent is
      entry Inout (Obj : in out Trigger_Delivery_Mission);
   end Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);

      -- subscribe to Delivery_Mission_Complete subscription
      declare
         use Ahd.Delivery_Mission;
         Msg : Eng_Delivery_Mission_Complete;
      begin
         Ahd.Delivery_Mission.Input (Delivery_Mission_Complete (Msg));
      end;

      loop
         accept Inout (Obj : in out Trigger_Delivery_Mission) do
            Do_Trigger_Delivery_Mission (Integer'Value (+Obj.Set));
         end Inout;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Inout (Obj : in out Trigger_Delivery_Mission) is
   begin
      Agent.Inout (Obj);
   end Inout;


begin
   Save_Action (Trigger_Delivery_Mission'(Pace.Msg with Set => +""));
end Eng.Test;
