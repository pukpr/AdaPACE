with Pace.Log;
with Pace.Socket;
with Gyrator;
with Ada.Text_IO;
with Ses.PP;

procedure Client_Main is

   task Monitor;
   task body Monitor is
   begin
      Ses.Pp.Parser;   
   exception
      when others =>
         Ses.Os_Exit (0);         
   end Monitor;

   function ID is new Pace.Log.Unit_ID;
   
   Move_Cmd : Gyrator.Move;
   Halt_Cmd : Gyrator.Halt;
   Status_Request : Gyrator.Get_Status;
   
begin
   Pace.Log.Agent_Id (ID);
   Ada.Text_IO.Put_Line ("Client: Sending commands to Gyrator...");
   
   -- Send Move
   Ada.Text_IO.Put_Line ("Client: Sending Move...");
   Pace.Socket.Send (Move_Cmd, Ack => True);
   
   -- Check Status
   Ada.Text_IO.Put_Line ("Client: Checking Status...");
   Pace.Socket.Send_Out (Status_Request);
   Ada.Text_IO.Put_Line ("Client: Status is " & Gyrator.Status_Type'Image(Status_Request.Value));
   
   pace.log.wait(2.0);
   
   -- Send Halt
   Ada.Text_IO.Put_Line ("Client: Sending Halt...");
   Pace.Socket.Send (Halt_Cmd, Ack => True);

   -- Check Status Again
   Ada.Text_IO.Put_Line ("Client: Checking Status...");
   Pace.Socket.Send_Out (Status_Request);
   Ada.Text_IO.Put_Line ("Client: Status is " & Gyrator.Status_Type'Image(Status_Request.Value));
   
   Ada.Text_IO.Put_Line ("Client: Finished.");
   
end Client_Main;
