with Ada.Strings.Unbounded;
with Pace.Hash_Table;

package body Pace.Event_Io is

   protected type Mailbox is
      procedure Transmit;
      entry Receive;
      function Is_Ready return Boolean;
      entry Acknowledge;
   private
      Ready : Boolean := False;
      Ack : Boolean := False;
   end Mailbox;

   type Slot is access Mailbox;
   Empty : Slot := null;

   use Ada.Strings.Unbounded;

   package Slots is new Pace.Hash_Table.Simple_Htable 
      (Element => Slot,
       No_Element => Empty,
       Key => Unbounded_String,
       Hash => Pace.Hash_Table.Hash,
       Equal => "=");

   protected body Mailbox is
      procedure Transmit is
      begin
         Ready := True;
         Ack := False;
      end Transmit;

      entry Receive when Ready is
      begin
         if Receive'Count = 0 then
            Ready := False;
         end if;
         Ack := True;
      end Receive;

      function Is_Ready return Boolean is
      begin
         return Ready;
      end Is_Ready;

      entry Acknowledge when Ack is
      begin
         null;
      end Acknowledge;

   end Mailbox;

   procedure Await (Obj : in String;
                    Obj_Received : out Boolean;
                    Wait : in Boolean := True) is
      Id : Unbounded_String := To_Unbounded_String (Obj);
   begin
      if Slots.Get (Id) = null then
         Slots.Set (Id, new Mailbox);
      end if;
      if Wait or else Slots.Get (Id).Is_Ready then
         Slots.Get (Id).Receive;
         Obj_Received := True;
      else
         Obj_Received := False;
      end if;
   end Await;

   procedure Send (Obj : in String; Ack : in Boolean := False) is
      Id : Unbounded_String := To_Unbounded_String (Obj);
   begin
      if Slots.Get (Id) = null then
         Slots.Set (Id, new Mailbox);
      end if;
      Slots.Get (Id).Transmit;
      if Ack then
         Slots.Get (Id).Acknowledge;
      end if;
   end Send;

   procedure Flush (Obj : in String) is
      Id : Unbounded_String := To_Unbounded_String (Obj);
   begin
      if Slots.Get (Id) = null then
         return;
      end if;
      while Slots.Get (Id).Is_Ready loop
         Slots.Get (Id).Receive;
      end loop;
   end Flush;
   
-----------------------------------------------------
--  $Id: pace-event_io.adb,v 1.2 2006/03/16 21:42:32 pukitepa Exp $
-----------------------------------------------------   
end Pace.Event_Io;
