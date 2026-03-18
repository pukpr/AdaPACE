with Pace.Log;
with Pace.Socket;
with Handshake;
with Ada.Text_IO;
with Ses.Pp;

procedure Verifier_Main is
   function ID is new Pace.Log.Unit_ID;
begin
   Pace.Log.Agent_Id (ID);
   Ada.Text_IO.Put_Line ("Verifier Node 3 Started.");

   -- Listen for shutdown signal
   Ses.Pp.Parser;
exception
    when others =>
        Ses.Os_Exit (0);
end Verifier_Main;
