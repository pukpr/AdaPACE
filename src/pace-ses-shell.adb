with Gnat.Expect;
with Gnat.Os_Lib;
with Gnat.Regpat;
with Pace.Server.Dispatch;
with Pace.Server.Html;
with Pace.Server.Xml;
with System;
with Text_IO;
with Pace.Log;
with Pace.TCP;

package body Pace.Ses.Shell is
   package Exp renames Gnat.Expect;

   Sh     : constant String := Getenv ("P4SHELL", "sh");
   Sh_Opt : constant String := Getenv ("P4SHELLOPT", "-c");
   Filter : constant Boolean := Getenv ("P4SHELLFILTER", "0") = "1";
   Batch : constant Boolean := Getenv ("P4SHELLBATCH", "0") = "1";

   procedure Output_Filter 
      (Descriptor : Exp.Process_Descriptor'Class;
       Str        : String;
       User_Data  : System.Address) is
   begin
      Text_IO.Put_Line (Text_IO.Standard_Error, "P4D ||"  & Str);
   end;

   procedure Quit (Pid : in out Exp.Process_Descriptor) is
      Clean_Exit : constant Boolean := Getenv ("_EXIT", "0") = "1";
   begin
      Exp.Send (Pid, ASCII.EOT & "");
      Text_IO.Put_Line (Text_IO.Standard_Error, "Sending EOT");
      while Clean_Exit loop
         -- Wait until the app tells us that it has quit
         declare
            Result : Exp.Expect_Match;
            Match  : Gnat.Regpat.Match_Array (0 .. 1);
         begin
            Exp.Expect (Pid, Result, " ", Match, 100);
         exception
            when others =>
               Text_IO.Put_Line (Text_IO.Standard_Error, "Gracefully exited app {_EXIT=1}");
               Exp.Close (Pid);
               return;
         end;
      end loop;
      -- Don't wait for app to respond that it has shut down, just close it
      Text_IO.Put_Line (Text_IO.Standard_Error, "Sending SIGTERM {_EXIT=0}");
      Exp.Send_Signal (Pid, 15);
      -- Hope that it will shut down eventually
   exception
      when others =>
         Exp.Close (Pid);
         Text_IO.Put_Line
           (Text_IO.Standard_Error,
            "Trying to quit process which is already dead?");
   end Quit;


   function Run (Exec, Match : in String) return Exp.Process_Descriptor is
      Zero_Params : Gnat.Os_Lib.Argument_List (1 .. 0);
      Params : Gnat.Os_Lib.Argument_List (1 .. 2);
      Pid : Exp.Process_Descriptor;

      Result : Exp.Expect_Match;
      use type Exp.Expect_Match;
      FT : Text_IO.File_Type;
   begin
      Params (1) := new String'(Sh_Opt);
      Params (2) := new String'(Exec);
      
      -- if we use a batch file here then we must be careful about reentrancy
      Text_IO.Create (FT, Text_IO.Out_File, "go.bat");
      Text_IO.Put_Line (FT, Exec);
      Text_IO.Close (FT);

      Pace.Log.Put_Line ("P4D || SPAWN");
      if Batch then
         Exp.Non_Blocking_Spawn
           (Pid, --.Descriptor.all,
            "go.bat",
            Zero_Params,
            Err_To_Out  => True,
            Buffer_Size => 5_000);
      else
         Exp.Non_Blocking_Spawn
           (Pid, --.Descriptor.all,
            Sh,
            Params,
            Err_To_Out  => True,
            Buffer_Size => 5_000);
      end if;
      
      if Filter then
         Exp.Add_Filter (Pid, Output_Filter'Access);
      end if;
      
      Pace.Log.Put_Line ("P4D || EXPECT");
      loop
         Exp.Expect (Pid, Result, "[ -~]{1,150}", 1_000); -- 10_000 = 10 seconds
         if Result = Exp.Expect_Timeout then
            --Pace.Log.Put_Line ("P4D || .. TIMED OUT");
            Pace.Server.Put_Data (Ses.Output_Marker);
            null;
         else
            Pace.Server.Put_Data (Exp.Expect_Out(Pid));
         end if;
         -- this may need to be a ping task and determines if the session is still opem
         exit when not Pace.Server.Active_Session;
         
      end loop;
      
      return Pid;
   exception
      when E : others =>
         Pace.Log.Ex (E);
         return Pid;
   end Run;


   type Launch_Program is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Launch_Program);
   procedure Inout (Obj : in out Launch_Program) is
      Pid : Exp.Process_Descriptor;
      Set : constant String := Pace.Server.Value(""); 
   begin
      -- 1. get line from Post data
      -- 2. Run returns PID
      -- loop
      --    get line from Post data
      --    send data if needed 
      Pid := Run (Set, "P4 is ready");
      Pace.Log.Put_Line ("Commanding EXIT : " & Set);
      Quit (Pid);
      Pace.Server.Close_Session; -- to avoid spurious errors
   end Inout;


   use Pace.Server.Dispatch;
begin
   Save_Action (Launch_Program'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
end Pace.Ses.Shell;


