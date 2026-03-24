with Ada.Tags;
with Pace.Hash_Table;
with Pace.Queue;

package body Pace.Msg_Io is

   package Queue is new Pace.Queue (Channel);

   protected type Mailbox is
      procedure Transmit (Obj : in Channel);
      entry Receive (Obj : out Channel);
      function Is_Ready return Boolean;
      function Is_Receiving return Boolean;
      entry Acknowledge;
   private
      Buffer : Queue.Channel_Link;
      Ready  : Boolean := False;
      Ack    : Boolean := False;
   end Mailbox;

   type Slot is access Mailbox;
   Empty : Slot := null;

   package Slots is new Pace.Hash_Table.Simple_Htable (
      Element => Slot,
      No_Element => Empty,
      Key => Ada.Tags.Tag,
      Hash => Pace.Hash_Table.Hash,
      Equal => Ada.Tags. "=");

   protected body Mailbox is
      procedure Transmit (Obj : in Channel) is
      begin
         Queue.Append (Buffer, Obj);
         Ready := True;
         Ack   := False;
      end Transmit;

      entry Receive (Obj : out Channel) when Ready is
         Ch : Channel;
      begin
         Ch  := Queue.Front (Buffer);
         Obj := Flow (Ch.all);
         if Receive'Count = 0 then
            Queue.Pop (Buffer);
            Pace.Free (Ch);
            if Queue.Is_Empty (Buffer) then
               Ready := False;
            end if;
         end if;
         Ack := True;
      end Receive;

      function Is_Receiving return Boolean is
      begin
         return Receive'Count > 0;
      end Is_Receiving;

      function Is_Ready return Boolean is
      begin
         return Ready;
      end Is_Ready;

      entry Acknowledge when Ack is
      begin
         null;
      end Acknowledge;

   end Mailbox;

   protected Lock is
      procedure Set (Id : in Ada.Tags.Tag);
   end Lock;

   protected body Lock is
      procedure Set (Id : in Ada.Tags.Tag) is
      begin
         if Slots.Get (Id) = null then
            Slots.Set (Id, new Mailbox);
         end if;
      end;
   end Lock;

   procedure Await
     (Obj          : out Msg'Class;
      Obj_Received : out Boolean;
      Wait         : in Boolean := True)
   is
      Id : Ada.Tags.Tag := Obj'Tag;
      Ch : Channel;
   begin
      Lock.Set (Id);
      if Wait or else Slots.Get (Id).Is_Ready then

         Slots.Get (Id).Receive (Ch);
         Obj := Ch.all;
         Pace.Free (Ch);
         Obj_Received := True;
      else
         Obj_Received := False;
      end if;
   end Await;

   procedure Send (Obj : in Msg'Class; Ack : in Boolean := False; Immediate : in Boolean := False) is
      Id : Ada.Tags.Tag := Obj'Tag;
      Ch : Channel;
   begin
      Lock.Set (Id);
      Ch := Flow (Obj);
      if Immediate then
         if Slots.Get (Id).Is_Receiving then
            Slots.Get (Id).Transmit (Ch);
         end if;
      else
         Slots.Get (Id).Transmit (Ch);
         if Ack then
            Slots.Get (Id).Acknowledge;
         end if;
      end if;
   end Send;

   procedure Flush (Obj : in Msg'Class) is
      Id : Ada.Tags.Tag := Obj'Tag;
      Ch : Channel;
   begin
      if Slots.Get (Id) = null then
         return;
      end if;
      while Slots.Get (Id).Is_Ready loop
         Slots.Get (Id).Receive (Ch);
         Pace.Free (Ch);
      end loop;
   end Flush;

----------------------------------------------------------------------------
----------------------------------------------------------------------------
end Pace.Msg_Io;
