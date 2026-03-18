with Pace;
with Pace.Log;
with Pace.Socket;
with Max_Finder;
with Ada.Text_IO;
with Ses.Pp;

procedure Server_Main is
   function ID is new Pace.Log.Unit_ID;
   Node_ID : constant Integer := Pace.Getenv ("PACE_NODE", 0);
begin
   Pace.Log.Agent_Id (ID);
   Ada.Text_IO.Put_Line ("Server Node" & Integer'Image(Node_ID) & " Started.");
   Ada.Text_IO.Put_Line ("Waiting for numbers from workers...");

   -- Listen for shutdown signal
   Ses.Pp.Parser;
exception
    when others =>
        Ses.Os_Exit (0);
end Server_Main;
