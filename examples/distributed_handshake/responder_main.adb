with Pace.Log;
with Pace.Socket;
with Handshake;
with Ada.Text_IO;
with Pace.Ses.Pp;

procedure Responder_Main is
   function ID is new Pace.Log.Unit_ID;
begin
   Pace.Log.Agent_Id (ID);
   Ada.Text_IO.Put_Line ("Responder Node 2 Started.");

   -- Listen for shutdown signal
   Pace.Ses.Pp.Parser;
exception 
   when others =>
      pace.Log.OS_Exit(0);
end Responder_Main;
