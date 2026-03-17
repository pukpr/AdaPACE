with Pace.Log;
with Pace.Socket; -- Needed for remote IPC
with Gyrator;     -- Force elaboration of Gyrator package
with Ada.Text_IO;
with Ses.Pp;

procedure Gyrator_Main is
   function ID is new Pace.Log.Unit_ID;
begin
   Pace.Log.Agent_Id (ID);
   Ada.Text_IO.Put_Line ("Gyrator Server Started. Waiting for commands...");
   
   -- The server primarily responds to commands, so we can just wait or loop.
   -- Since Pace is event-driven via tasks, the main procedure can just hang out.
   -- Or we can just wait forever.
   --loop
   --   delay 1.0;
   --end loop;
   
   -- or do this, whuch is waiting on stdio, ctrl-D to exit
   Ses.Pp.Parser;
exception
    when others =>
        Ses.Os_Exit (0);   
end Gyrator_Main;
