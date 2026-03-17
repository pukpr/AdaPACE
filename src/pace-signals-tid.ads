with Ada.Task_Identification;

package Pace.Signals.Tid is
   -----------------------------------------------------
   -- TASK_ID -- Events for waking up tasks
   -----------------------------------------------------
   -- SIGNAL a task with a given ID, which wakes up that thread of control.
   -- WAIT will suspend on the current task, waiting for a wakeup signal
   pragma Elaborate_Body;

   procedure Signal (Id : Ada.Task_Identification.Task_Id);
   procedure Signal (Msg : Pace.Msg'Class); -- Task_ID from Msg.ID field

   procedure Wait;

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-signals-tid.ads,v 1.1 09/16/2002 18:18:49 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Signals.Tid;
