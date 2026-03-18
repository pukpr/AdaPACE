with Pace.Log;
with Pace.Socket;
with Pace.Notify;
with Orchestra;

package body Processor_Pkg is

   -- Use a subscription message to synchronize the internal task
   type Wait_Msg is new Pace.Notify.Subscription with null record;
   Event : Wait_Msg;

   task Processor;
   task body Processor is
      function ID is new Pace.Log.Unit_ID;
      Out_Msg : Orchestra.Refined_Data;
      Local_Serial : Integer := 0;
   begin
      Pace.Log.Agent_Id (ID);
      
      loop
         -- Wait for the Input primitive to trigger us
         Pace.Notify.Subscribe (Event);
         
         -- Simulation: Actual data would be in a shared protected buffer
         -- Here we just increment for the demo
         Local_Serial := Local_Serial + 1;
         
         Pace.Log.Put_Line ("Processor: Processing Raw Data #" & Integer'Image(Local_Serial));
         Pace.Log.Wait (2.0); -- Processing time
         
         Out_Msg.Serial := Local_Serial;
         Out_Msg.Factor := Float(Local_Serial) * 1.5;
         
         Pace.Socket.Send (Out_Msg);
      end loop;
   end Processor;

   -- We need a way to notify the task from the Input primitive
   procedure Notify_Processor is
   begin
      Pace.Notify.Publish (Event);
   end Notify_Processor;

end Processor_Pkg;
