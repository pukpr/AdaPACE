with Pace.Ses.Pp;
with Ada.Command_Line;
with Ada.Environment_Variables;
with Gnat.Expect;
with Gnat.Os_Lib;
with Gnat.Regpat;
with Text_IO;
with Pace.Log;

package body Pace.Ses.Generic_Launcher is

   package Exp renames Gnat.Expect;

   Pid : Exp.Process_Descriptor;

   task Parser_Task is
      entry Ready;
   end;
   task body Parser_Task is
      Status : Integer;
   begin
      accept Ready;
      Pace.Ses.Pp.Parser;
   exception
      when Text_IO.End_Error =>
         Text_IO.Put_Line ("Interrupting Process");
         Exp.Interrupt(Pid);
         Text_IO.Put_Line ("Cancelled Process");
         Exp.Close(Pid, Status);
         Text_IO.Put_Line ("Closed Process");
         -- This will raise a process died exception in main
         -- Gnat.Os_Lib.Os_Exit (0);
   end Parser_Task;

   procedure Run is
      Num : constant Natural := Ada.Command_Line.Argument_Count;
      -- The following will raise an exception if no Exe argument
      -- Num will be 0. Have to catch this in the main procedure
      Params : Gnat.Os_Lib.Argument_List (1 .. Num-1);

      Result : Exp.Expect_Match;
      use type Exp.Expect_Match;
      Exe : constant String := Ada.Command_Line.Argument (1);
   begin
      for I in 2 .. Num loop
         Params (I-1) := new String'(Ada.Command_Line.Argument (I));
      end loop;
      Pace.Log.Put_Line ("SPAWN:" & Exe & " with" & Num'Img & " args");
      Exp.Non_Blocking_Spawn
        (Pid,
         Exe,
         Params,
         Err_To_Out  => True,
         Buffer_Size => 5_000);

      Parser_Task.Ready;

      Pace.Log.Put_Line ("EXPECT:" & Exe);
      loop
         Exp.Expect (Pid, Result, "[ -~]*\n", 1_000_000); -- 1_000 = 10 seconds
         if Result = Exp.Expect_Timeout then
            Text_IO.Put_Line (Ada.Command_Line.Command_Name & ":" &
                              Exe & " Heartbeat");
         else
            Text_IO.Put (Exp.Expect_Out(Pid));
            Text_IO.Flush;
         end if;
      end loop;
   exception
      when Exp.Process_Died =>
         Text_IO.Put_Line ("Exiting as Process Died: " & Exe);
         Gnat.Os_Lib.Os_Exit (0);
      when E : others =>
         Pace.Log.Ex (E);
         Gnat.Os_Lib.Os_Exit (0);
   end Run;

end Pace.Ses.Generic_Launcher;

