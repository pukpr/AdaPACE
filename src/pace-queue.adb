with Ada.Unchecked_Deallocation;

package body Pace.Queue is
   procedure Free is new Ada.Unchecked_Deallocation (Channel_Link, Channel_Ptr);

   procedure Append (Q : in out Channel_Link;
                     Item : in Channel) is
      Ptr : Channel_Ptr;
   begin
      if Fifo then
         if Q.Next = null then
            Q.Next := new Channel_Link'(Item, null);
         else
            Ptr := Q.Next;
            loop
               exit when Ptr.Next = null;
               Ptr := Ptr.Next;
            end loop;
            Ptr.Next := new Channel_Link'(Item, null);
         end if;
      else
         if Q.Next = null then
            Q.Next := new Channel_Link'(Item, null);
         else
            Ptr := Q.Next;
            Q.Next := new Channel_Link'(Item, null);
            Q.Next.Next := Ptr;
         end if;
      end if;
   end Append;

   procedure Pop (Q : in out Channel_Link) is
      Free_Ptr : Channel_Ptr;
   begin
      if Q.Next /= null then
         Free_Ptr := Q.Next;
         Q.Next := Q.Next.Next;
         Free (Free_Ptr);
      end if;
   end Pop;

   function Front (Q : in Channel_Link) return Channel is
   begin
      return Q.Next.Buffer;
   end Front;

   function Is_Empty (Q : in Channel_Link) return Boolean is
   begin
      return Q.Next = null;
   end Is_Empty;

   ------------------------------------------------------------------------------
   -- $id: pace-queue.adb,v 1.1 09/16/2002 18:18:35 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Queue;
