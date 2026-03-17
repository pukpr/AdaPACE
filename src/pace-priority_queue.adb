with Ada.Unchecked_Deallocation;

package body Pace.Priority_Queue is
   procedure Free is new Ada.Unchecked_Deallocation (
      Channel_Link,
      Channel_Ptr);

   procedure Append
     (Q    : in out Channel_Link;
      Item : in Channel;
      Prty : in Priorities)
   is
      Curr    : Channel_Ptr;
      New_Ptr : Channel_Ptr;
      Found   : Boolean := False;
   begin
      if Q.Next = null then
         Q.Next := new Channel_Link'(Item, Prty, null); -- Insert at front
      elsif Prty > Q.Next.Priority then
         New_Ptr := new Channel_Link'(Item, Prty, Q.Next);
         Q.Next  := New_Ptr;
      else
         Curr := Q.Next;
         while Curr.Next /= null and then Prty < Curr.Next.Priority loop
            Curr := Curr.Next;
         end loop;
         New_Ptr   := new Channel_Link'(Item, Prty, Curr.Next);
         Curr.Next := New_Ptr;
      end if;
   end Append;

   procedure Pop (Q : in out Channel_Link) is
      Free_Ptr : Channel_Ptr;
   begin
      if Q.Next /= null then
         Free_Ptr := Q.Next;
         Q.Next   := Q.Next.Next;
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

   procedure Show_Priorities (Q : in Channel_Link) is
      Ptr : Channel_Ptr;
   begin
      Pace.Display ("Queue Priorities:");
      begin
         if Q.Next = null then
            Pace.Display ("Empty");
         else
            Ptr := Q.Next;
            loop
               exit when Ptr.Next = null;
               Pace.Display (Image (Ptr.Priority));
               Ptr := Ptr.Next;
            end loop;
            Pace.Display (Image (Ptr.Priority));
         end if;
      end;
   end Show_Priorities;

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-queue.adb,v 1.1 09/16/2002 18:18:35 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Priority_Queue;
