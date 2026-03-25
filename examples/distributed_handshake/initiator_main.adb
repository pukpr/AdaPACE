with Pace.Log;
with Pace.Socket;
with Handshake;
with Ada.Text_IO;
with Pace.Ses.Pp;

procedure Initiator_Main is
   function ID is new Pace.Log.Unit_ID;
   P : Handshake.Propose;
begin
   Pace.Log.Agent_Id;  -- For non-distributed "main" DES mode
   Ada.Text_IO.Put_Line ("Initiator Node 1 Started.");

   -- Wait for other nodes to be ready
   Pace.Log.Wait (2.0);

   P.Request_Id := 101;
   Ada.Text_IO.Put_Line ("Initiator: Sending Propose to Responder...");
   Pace.Socket.Send (P, Ack => True);
   Ada.Text_IO.Put_Line ("Initiator: READY");
   
   -- Listen for shutdown signal
   Pace.Ses.Pp.Parser;
exception 
   when others =>
      pace.Log.OS_Exit(0);
end Initiator_Main;
