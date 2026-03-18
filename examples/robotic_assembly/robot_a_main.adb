with Pace;
with Pace.Log;
with Assembly;
with Ada.Text_IO;
with Ses.Pp;

procedure Robot_A_Main is
   function ID is new Pace.Log.Unit_ID;
   Node_ID : constant Integer := Pace.Getenv ("PACE_NODE", 0);
begin
   Pace.Log.Agent_Id (ID);
   Ada.Text_IO.Put_Line ("Robot A SCARA (Node" & Integer'Image(Node_ID) & ") Started.");
   Ses.Pp.Parser;
exception
    when others =>
        Ses.Os_Exit (0);
end Robot_A_Main;
