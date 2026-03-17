generic
   type Channel is private;
   Fifo : in Boolean := True;
package Pace.Queue is
   -----------------------------------------
   -- QUEUE -- A queueing abstract data type
   -----------------------------------------
   -- CHANNEL_LINK is the queue ADT.
   -- ITEM is a queue element of type CHANNEL.
   -- Note: Un/comment the top line if generic.
   pragma Elaborate_Body;

   type Channel_Link is private;

   procedure Append (Q : in out Channel_Link;
                     Item : in Channel);
   procedure Pop (Q : in out Channel_Link); -- Cleans up
   function Front (Q : in Channel_Link) return Channel;
   function Is_Empty (Q : in Channel_Link) return Boolean;

private
   type Channel_Ptr is access Channel_Link;
   type Channel_Link is
      record
         Buffer : Channel;
         Next : Channel_Ptr := null;
      end record;

   ------------------------------------------------------------------------------
   -- $id: pace-queue.ads,v 1.1 09/16/2002 18:18:36 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Queue;
