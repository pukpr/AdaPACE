generic
package Pace.Queue.Guarded is
   -----------------------------------------
   -- PROTECTED_QUEUE -- Guarded queue
   -----------------------------------------
   -- Uses Pace.Queue to create a reentrant
   -- safe queue for multiple threads of control.
   -- CHANNEL is the queue element.
   pragma Elaborate_Body;

   procedure Put (Obj : in Channel);

   procedure Get (Obj : out Channel);

   function Is_Ready return Boolean;

   ------------------------------------------------------------------------------
   -- $id: pace-queue-guarded.ads,v 1.1 09/16/2002 18:18:34 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Queue.Guarded;
