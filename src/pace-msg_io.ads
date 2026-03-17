generic
   type Connections is range <>;  -- Number of message connections
package Pace.Msg_Io is
   -----------------------------------------------------
   -- MSG_IO -- queued-output message-passing interface
   -----------------------------------------------------
   -- Message connections are buffered in the CHANNEL object and
   --  matched sender-to-receiver through their dereferenced object's tag.
   -- SEND is an asynchronous "send and forget" call, processed immediately.
   -- If ACK is true, it waits for acknowledgement (Synchronous mode).
   -- AWAIT is either sync or async depending on the WAIT parameter. It
   --  will return immediately if WAIT is FALSE or messages are in the queue.
   -- FLUSH removes all awaiting messages from the receiving queue.
   pragma Elaborate_Body;

   procedure Send (Obj : in Msg'Class;
                   Ack : in Boolean := False; -- Synchronized
                   Immediate : in Boolean := False);  -- To queue or not to queue

   procedure Await
     (Obj          : out Msg'Class;
      Obj_Received : out Boolean;           -- If no Wait
      Wait         : in Boolean := True);  -- Synchronized

   procedure Flush (Obj : in Msg'Class);

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-msg_io.ads,v 1.1 09/16/2002 18:18:29 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Msg_Io;
