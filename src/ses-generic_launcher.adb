------------------------------------------------------------------------
-- PDT/COMPANY:         Performance Management / Global Industrial Solutions
-- SYSTEM/Subsystem:    $view: /prog/shared/modsim/ctd/ssom/ssom.ss/integ.wrk $
-- FILE NAME:           $id: ses-generic_launcher.adb,v 1.1 03/27/2003 13:44:33 pukitepa Exp $
-- HISTORY:             $History: Common $
-- STATISTICS:  $Source_lines: 0 $  $Comment_Lines: 0 $  $Total_lines: 0 $
-- DESIGN NOTES:        Provides a wrapper around P4 for launching non-native apps
-- IMPLEMENTATION NOTES:Uses argument number 1 for calls (should wrap in single quotes)
-- PORTABILITY ISSUES:  See "system" call
------------------------------------------------------------------------
with Ses.Codetest;
with Ses.Pp;
with Text_Io;
with Ada.Command_Line;
with Interfaces.C.Strings;
with Ada.Interrupts.Names;

package body Ses.Generic_Launcher is

   protected Keeper is
      procedure Signal;
      pragma Interrupt_Handler (Signal);
   end Keeper;

   protected body Keeper is
      procedure Signal is
      begin
         Text_Io.Put_Line ("Caught SIGCHILD, exiting ... ");
         Ses.Os_Exit (0);
      end Signal;
   end Keeper;

   procedure Attach is
   begin
      -- Ada.Interrupts.Attach_Handler (Keeper.Signal'Access,
      --                                Ada.Interrupts.Names.Sigchld);
      null;

   end Attach;


   procedure Run is

      Num : constant Natural := Ada.Command_Line.Argument_Count;

      -- Apex needs this array fixed
      type Arguments is array (Natural range 0 .. 50) of
                          Interfaces.C.Strings.Chars_Ptr;
      pragma Convention (C, Arguments);
      procedure Exec (App : in Interfaces.C.Strings.Chars_Ptr;
                      Args : in Arguments);
      pragma Import (C, Exec, "execvp");

      Args : Arguments;

      procedure Print_Error (Msg : in Interfaces.C.Strings.Chars_Ptr);
      pragma Import (C, Print_Error, "perror");

      Pid : Integer;
      function Fork return Integer;
      pragma Import (C, Fork, "fork");
      procedure Kill (Pid, Sig : in Integer);
      pragma Import (C, Kill, "kill");

   begin
      if Num < 1 then
         Text_Io.Put_Line
           ("Usage: " & Ada.Command_Line.Command_Name & " app [args]");
         Ses.Os_Exit (0);
      end if;

      Attach;

      for I in 1 .. Num loop
         Args (I - 1) := Interfaces.C.Strings.New_String
                           (Ada.Command_Line.Argument (I));
      end loop;
      Args (Num) := Interfaces.C.Strings.Null_Ptr;
      Pid := Fork;
      if Pid = 0 then
         Exec (Interfaces.C.Strings.New_String (Ada.Command_Line.Argument (1)),
               Args);
         Print_Error (Interfaces.C.Strings.New_String
                        ("Execution failure on " &
                         Ada.Command_Line.Argument (1)));
      end if;
      Ses.Pp.Parser;
   exception
      when Text_Io.End_Error =>
         Kill (Pid, 2); -- 9 
         Ses.Os_Exit (0);
   end Run;

end Ses.Generic_Launcher;

-- with Ses.Pp;
-- with Ses.Codetest;
-- with Text_Io;
-- with Ada.Command_Line;
-- with Ada.Exceptions;
-- with System;
-- 
-- procedure Ses.Generic_Launcher is
--    task Pp_Parser;
--    task body Pp_Parser is
--    begin
--       Ses.Pp.Parser;
--    exception
--       when Text_Io.End_Error =>
--       Text_Io.Put_Line ("exiting");
--       Ses.Os_Exit (0);
--    end Pp_Parser;
--    procedure Exec (Args : System.Address);
--    pragma Import (C, Exec, "system");
--    Program : constant String := Ada.Command_Line.Argument (1) & Ascii.Nul;
-- begin
--    Text_Io.Put_Line ("Launching " & Program);
--    Exec (Program (Program'First)'Address);
--    Text_Io.Put_Line ("Finished running " & Program);
-- exception
--    when E: others =>
--       Text_Io.Put_Line ("Error in Generic Launcher : " &
--                      Ada.Exceptions.Exception_Information (E));
--       Ses.Os_Exit (0);
-- end Ses.Generic_Launcher;
