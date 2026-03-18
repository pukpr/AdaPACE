with Pace.Ses.Generic_Launcher;
with Text_IO;
with Gnat.Os_Lib;
with Ada.Command_Line;

procedure Generic_p4_launcher is
begin
   Pace.Ses.Generic_Launcher.Run;
exception
   when Constraint_Error =>
      Text_IO.Put_Line ("Usage: " & Ada.Command_Line.Command_Name & " app [args]");
      Gnat.Os_Lib.Os_Exit (0);
end Generic_p4_launcher;
