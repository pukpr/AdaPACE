with Pace;
with Pace.Log;
with Assembly;
with Ada.Text_IO;
with Pace.Ses.Pp;

procedure Robot_B_Main is
   function ID is new Pace.Log.Unit_ID;
   Node_ID : constant Integer := Pace.Getenv ("PACE_NODE", 0);
begin
   Pace.Log.Agent_Id (ID);
   Ada.Text_IO.Put_Line ("Robot B 6-Axis (Node" & Integer'Image(Node_ID) & ") Started.");
   Pace.Ses.Pp.Parser;
exception
    when others =>
        Pace.Log.Os_Exit (0);
end Robot_B_Main;
