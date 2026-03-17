generic
   type Channel is private;

   type Priorities is private;
   with function "<" (L, R : Priorities) return Boolean;
   with function ">" (L, R : Priorities) return Boolean;
   with function Image (P : Priorities) return String;

package Pace.Priority_Queue is
   -----------------------------------------
   -- PRIORITY_QUEUE -- A queueing abstract data type
   -----------------------------------------
   -- CHANNEL_LINK is the queue ADT.
   -- ITEM is a queue element of type CHANNEL.
   -- Note: Un/comment the top line if generic.
   pragma Elaborate_Body;

   -- Priorities are values; with larger numbers
   -- indicating higher priorities unless < reversed.

   type Channel_Link is private;

   procedure Append
     (Q    : in out Channel_Link;
      Item : in Channel;
      Prty : in Priorities);
   procedure Pop (Q : in out Channel_Link); -- Cleans up
   function Front (Q : in Channel_Link) return Channel;
   function Is_Empty (Q : in Channel_Link) return Boolean;

   procedure Show_Priorities (Q : in Channel_Link);

private
   type Channel_Ptr is access Channel_Link;
   type Channel_Link is record
      Buffer   : Channel;
      Priority : Priorities;
      Next     : Channel_Ptr := null;
   end record;

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-queue.ads,v 1.1 09/16/2002 18:18:36 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Priority_Queue;
