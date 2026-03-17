with Pace.Msg_Io;
with Ada.Task_Identification;
with Pace.Log;

package body Pace.Notify is

   type Connections is new Integer range 1 .. 200;
   package Mailbox is new Pace.Msg_Io (Connections);

   procedure Input (Obj : in Subscription) is
   begin
      Publish (Obj);
   end Input;

   procedure Inout (Obj : in out Subscription) is
   begin
      Subscribe (Obj => Obj);
   end Inout;


   procedure Publish (Obj : in Subscription'Class) is
   begin
      Mailbox.Send (Obj, Ack => Obj.Ack, Immediate => Obj.Immediate);
      Pace.Log.Trace (Obj);
   end Publish;

   procedure Subscribe (Obj : in out Subscription'Class) is
      Id : Ada.Task_Identification.Task_Id := Obj.Id;
      Time : Pace.Art.Time_Span := Obj.Time;
   begin
      if Obj.Flush then
         Mailbox.Flush (Obj);
      end if;
      Mailbox.Await (Obj, Obj_Received => Obj.Received, Wait => Obj.Ack);
      Obj.Id := Id;
      Obj.Send := Pace.Balk;
      Obj.Time := Time;
      Pace.Log.Trace (Obj);
   end Subscribe;

   ------------------------------------------------------------------------------
   -- $id: pace-notify.adb,v 1.1 09/16/2002 18:18:30 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Notify;
