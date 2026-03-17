package Pace.Notify is
   -------------------------------------------------
   -- NOTIFY -- Publish/Subscribe pattern
   -------------------------------------------------
   pragma Elaborate_Body;

   type Subscription is new Pace.Msg with
      record
         Ack : Boolean := True; -- Blocking wait on Publish or Subscribe
         Flush : Boolean := False; -- Flushes subscribers on Subscribe
         Received : Boolean := False; -- Subscribe receives a message
         -- Releases any pending subscribers, doesn't queue, doesn't ack
         -- eliminates need for flush on subscriber side
         Immediate : Boolean := False;
      end record;
   procedure Input (Obj : in Subscription);
   procedure Inout (Obj : in out Subscription);
   --
   -- Primitive dipatching operations :
   -- INPUT will call the class-wide type Publish below
   -- INOUT will call the class-wide type Subscribe below

   procedure Publish (Obj : in Subscription'Class);
   -- Triggers the Subscriber to unsuspend

   procedure Subscribe (Obj : in out Subscription'Class);
   -- Blocks until Publish unsuspends

   ------------------------------------------------------------------------------
   -- $id: pace-notify.ads,v 1.1 09/16/2002 18:18:31 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Notify;
