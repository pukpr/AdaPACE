with Pace;
with Pace.Log;
with Assembly;
with Ada.Text_IO;
with Pace.Ses.Pp;

procedure Vision_Main is
   function ID is new Pace.Log.Unit_ID;
   Node_ID : constant Integer := Pace.Getenv ("PACE_NODE", 0);
begin
   Pace.Log.Agent_Id (ID);
   Ada.Text_IO.Put_Line ("Vision Agent (Node" & Integer'Image(Node_ID) & ") Started.");
   Pace.Ses.Pp.Parser;
exception
    when others =>
        Pace.Log.Os_Exit (0);
end Vision_Main;
