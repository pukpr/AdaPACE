with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Pace.Ses.Kb;
with Pace.Ses.Launch;
with Pace.Ses.Lib;
with Text_IO;
with Gnat.Regpat;
with Calendar;
with Pace.Log;
with Pace.Command_Line;
with Pace.Strings;
with GNAT.Ctrl_C;

package body Pace.Ses.P4 is
   use Pace.Ses.Lib;
   subtype Process_Range is Integer range
      1 .. Pace.Ses.Launch.Max_Number_Of_Processes;
   P                       : Processes (Process_Range);
   N                       : Natural          := 0;
   Ct_Num                  : Natural          := 0;
   Debug_On                : constant Boolean :=
      not Pace.Command_Line.Has_Argument ("NO_SESSION_DEBUG");
   Monitor_Off             : constant Boolean :=
      Pace.Command_Line.Has_Argument ("MONITOR_OFF");
   Testing                 : constant Boolean := Pace.Command_Line.Has_Argument ("TESTING");
   Checking                : constant Boolean :=
      Pace.Command_Line.Has_Argument ("CHECK") or Getenv ("P4CHECK", "0") = "1";
   Commanding                : constant Boolean :=
      Pace.Command_Line.Has_Argument ("CMDS") or Getenv ("P4CMDS", "0") = "1";
   Session_Pro             : constant String  :=
      Pace.Command_Line.Argument ("-pro", "session.pro");
   Interactive             : constant Boolean :=
      not Pace.Command_Line.Has_Argument ("POLLED");
   Help                    : constant Boolean := Pace.Command_Line.Has_Argument ("HELP");
   Expect_Timeout          : Integer          := 10_000;
   Poll_Period             : Duration         := 1.0;
   Wild_Card_Match_Pattern : Pace.Ses.Lib.Re  :=
      Pace.Ses.Lib.Re_Pattern ("[ -~]{1,150}");  -- RTCOE has 132 characters
   P4_Pattern              : Pace.Ses.Lib.Re  :=
      Pace.Ses.Lib.Re_Pattern (Pace.Ses.Output_Marker & "\n");
   Verbose_Name            : Boolean          :=
      Pace.Command_Line.Has_Argument ("VERBOSE_NAME");
   Time_Stamp              : Boolean          :=
      Pace.Command_Line.Has_Argument ("TIME_STAMP");
   Colors              : Boolean          :=
      Pace.Command_Line.Has_Argument ("COLORS");
   Terminate_If_Process_Dies : Boolean        := Getenv ("P4_TERMINATE_IF_PROCESS_DIES", "0") = "1";

   ------------
   -- Query
   ------------
   procedure Query (Functor : in String) is
      -- use Gnu.Rule_Processor.Db;
      use Pace.Ses.Kb.Rules;
   -- V : Variables (1..0);
   begin
      Pace.Ses.Kb.Agent.Parse (Functor);
   exception
      when No_Match =>
         Echo ("No match");
   end Query;

   -------------
   -- Remove_Dot
   -------------
   function Remove_Dot (Str : String) return String is
   begin
      if Str'Length > 1 and then Str (Str'First) = '.' then
         return Str (Str'First + 1 .. Str'Last);
      else
         return Str;
      end if;
   end Remove_Dot;

   -------------
   -- Console
   -------------
   procedure Console (Text : in String; Pid : in Integer := 0) renames
     Pace.Ses.Launch.Console;

   ----------------
   -- Get_Pid_Name
   ----------------
   function Get_Pid_Name (Pid : Integer) return String is
      function Show_Time (Text : in String) return String is
         Y : Calendar.Year_Number;
         M : Calendar.Month_Number;
         D : Calendar.Day_Number;
         S : Calendar.Day_Duration;
      begin
         Calendar.Split (Calendar.Clock, Y, M, D, S);
         if Time_Stamp then
            return (Text &
                    " @" &
            --           Trim (Calendar.Month_Number'Image (M)) & "/" &
            --           Trim (Calendar.Day_Number'Image (D)) & "/" &
            --           Trim (Calendar.Year_Number'Image (Y)) & "/" &
            --           Trim (Calendar.Day_Duration'Image (S)));
                    Calendar.Day_Duration'Image (S));
         else
            return Text;
         end if;
      end Show_Time;
   begin
      if Verbose_Name then
         return Show_Time
                  (Integer'Image (Pid) &
                   " " &
                   Pace.Ses.Lib.Get_Name (Pace.Ses.Lib.Run_Id (P (Pid).Descriptor.all)));
      else
         return Show_Time (Integer'Image (Pid));
      end if;
   end Get_Pid_Name;

   ----------------
   -- Send_Text
   ----------------
   procedure Send_Text (Text : in String; Pid : in Process_Range) is
      use type Exp.Expect_Match;
      Result : Exp.Expect_Match;
   begin
      for I in  Text'Range loop
         if Text (I) = ' ' then  -- reach the space
            declare
               Cmd         : constant String := Text (I + 1 .. Text'Last);
               Cmd_Address : constant String := Cmd;
            begin
               Console ("##" & Get_Pid_Name (Pid) & " ## " & Cmd, Pid);
               if Cmd_Address = ".." then
                  Exp.Send (P (Pid).Descriptor.all, "");
               else
                  Exp.Send (P (Pid).Descriptor.all, Cmd_Address);
               end if;
               Exp.Expect
                 (P (Pid).Descriptor.all,
                  Result,
                  Pace.Ses.Output_Marker,
                  Expect_Timeout);
               -- P4_Pattern.all, Expect_Timeout);
               if Result = Exp.Expect_Timeout then
                  Echo ("Timed out : " & Text);
               else
                  Console
                    ("##" &
                     Get_Pid_Name (Pid) &
                     " ## " &
                     Exp.Expect_Out (P (Pid).Descriptor.all),
                     Pid);
                  declare
                     Sym      : constant String :=
                        Pace.Strings.Select_Field (Cmd_Address, 1);
                     Str      : constant String :=
                        Exp.Expect_Out (P (Pid).Descriptor.all);
                     Output   : constant String :=
                        Str (
                        Str'First .. Str'Last - Ses.Output_Marker'Length - 1);
                     Reg_Expr : constant String := Sym & "([ :]*= [ -~]+)";
                     Matches  : Gnat.Regpat.Match_Array (0 .. 1);
                  begin
                     Echo (Integer'Image (Pid) & " => "); -- & Output
                     Gnat.Regpat.Match (Reg_Expr, Output, Matches);
                     Echo
                       (Remove_Dot (Pace.Strings.Select_Field (Cmd, 1)) &
                        Output (Matches (1).First .. Matches (1).Last));
                  exception
                     when others =>
                        Echo (Output);
                  end;
               end if;
            end;
            return;
         end if;
      end loop;
      Echo ("Input not understood => " & Text);
   end Send_Text;

   ----------------------
   -- Interactive_Session
   ----------------------
   procedure Interactive_Session (Text : in String) is
      Nf  : constant Integer := Pace.Strings.Count_Fields (Text);
      Pid : Integer;
   begin
      Echo (Text);
      if Text'Length = 0 or Text = " " then
         Query ("test");
      elsif Text = "verbose_toggle" then
         Verbose_Name := not Verbose_Name;
      elsif Text = "timestamp_toggle" then
         Time_Stamp := not Time_Stamp;
      else
         begin
            Pid := Integer'Value (Pace.Strings.Select_Field (Text, 1));
         exception
            when Constraint_Error =>
               Query (Text);
               Echo (Pace.Ses.Output_Marker);
               return;
         end;
         if Pid = 0 then
            if Nf = 1 then
               -- Echo ("Codetest peek on range: unimplemented");
               for I in  1 .. Ct_Num loop
                  Pid := I;
                  Send_Text ("0 ..", Pid);
               end loop;
            else
               for I in  1 .. Ct_Num loop
                  Pid := I;
                  Send_Text (Text, Pid);
               end loop;
            end if;
         elsif Pid < 0 then
            for I in  1 .. -Pid loop
               exit when N = 0;
               Echo ("Shutting down" & Integer'Image (N));
               Quit (P (N));
               Echo ("Shutdown" & Integer'Image (N));
               N := N - 1;
               if Ct_Num > N then
                  Ct_Num := N;
               end if;
            end loop;
         elsif Nf = 1 then
            -- Echo ("Codetest peek: unimplemented");
            Send_Text ("0 ..", Pid);
         else
            Send_Text (Text, Pid);
         end if;
      end if;
      Echo (Pace.Ses.Output_Marker);
   exception
      when E : others =>
         Echo ("try again ... " & Ada.Exceptions.Exception_Information (E));
         if Pid > N then
            Echo ("Process identifier exceeds range of session");
         end if;
         Echo (Pace.Ses.Output_Marker);
   end Interactive_Session;

   ---------------
   -- Check_Health
   ---------------
   procedure Check_Health is
      Result : Exp.Expect_Match;
      Good   : Integer := 0;
   begin
      for Pid in  1 .. Ct_Num loop
         begin
            Exp.Send (P (Pid).Descriptor.all, "");
            Exp.Expect
              (P (Pid).Descriptor.all,
               Result,
               Pace.Ses.Output_Marker,
               Expect_Timeout);
            --P4_Pattern.all, Expect_Timeout);
            Console
              ("!!" &
               Get_Pid_Name (Pid) &
               " !! " &
               Exp.Expect_Out (P (Pid).Descriptor.all),
               Pid);
            Echo ("Process #" & Integer'Image (Pid) & " is OK");
            Good := Good + 1;
         exception
            when others =>
               Echo ("Process #" & Integer'Image (Pid) & " is dead");
               -- Must have some way of skipping apps no longer alive
               -- If we turn monitoring mode off, then running with
               -- potentially dead process and no diagnostics
               if Monitor_Off then
                  null;
                  -- At one time we modified Gnat.Expect to skip over dead
                  -- processes by changing the process data structure as
                  -- follows:
                  -- P (Pid).Alive := False;
               end if;
         end;
      end loop;
      if Good = 0 then
         Echo ("All processes are dead, exiting...");
         raise Exp.Invalid_Process;
      end if;
   end Check_Health;


   ----------------------
   -- Set_Expect_Timeout
   ----------------------
   procedure Set_Expect_Timeout is
      use Pace.Ses.Kb.Rules;
      M : Variables (1 .. 1);
   begin
      Pace.Ses.Kb.Agent.Query ("expect_timeout", M);
      Expect_Timeout := Integer'Value (+M (1));
   exception
      when No_Match =>
         Echo
           ("Using default for Expect timeout:" &
            Integer'Image (Expect_Timeout));
   end Set_Expect_Timeout;


   procedure Check_Options is
   begin
      if Help then
         Echo ("Interactive: 1st field integer PID (else a query to profile)");
         Echo ("  syntax  : PID ([16#addr#|*sym type[:val]] | [command cb])");
         Echo ("PID=-1000 => shutdown all, PID=-N => shutdown N .. N-PID+1");
         Pace.Log.Os_Exit (0);
      else
         Pace.Ses.Launch.Load (Session_Pro, Debug_On);
         if Testing then
            Query ("test");
         elsif Checking then
            Query ("test");
            Pace.Log.Os_Exit (0);
         elsif Commanding then
            Query ("commands");
            Pace.Log.Os_Exit (0);
         end if;
      end if;
   end Check_Options;


   function Init_Procs return Integer is
      use Pace.Ses.Kb.Rules;
   begin
      for Pid in 1..Pace.Ses.Launch.Max_Number_Of_Processes loop
         Pace.Ses.Lib.Echo ("Processing " & Integer'Image (Pid));
         declare
            V : Variables (1 .. 5);
         begin
            V (1) := +S (Pid);
            Pace.Ses.Kb.Agent.Query ("proc", V);
         exception
            when No_Match =>
               return Pid - 1;
         end;
      end loop;
      return 0;
   end Init_Procs;

   ------------------
   -- Start_Session
   ------------------
   procedure Start_Session is
      --      Txt : String (1 .. 1000);
      --      Len : Integer;
      type Circular is mod 50;
      Counter : Circular := 0;
   begin  ---- P4 main program ----
      Check_Options;
      Echo ("Entering P4");

      Set_Expect_Timeout;

      Ct_Num := Init_Procs;
      if Colors then
         for I in  1 .. Ct_Num loop
            Pace.Ses.Launch.Set_Colors (Process => I);
         end loop;
         Pace.Ses.Launch.Set_Colors (Process => 0);
      end if;

      Pace.Ses.Launch.Remote_Exec
         (P,
          N,
          Common_Command_Args => "",
          Dummy_Launch        => Testing);

      if Interactive then
         for I in  1 .. N loop
            P (I).Regexp := Wild_Card_Match_Pattern;
         end loop;
         Echo ("Entering interactive session");
         Echo ("P4> ", New_Line => False);
         loop
            Counter := Counter + 1;
            exit when N = 0;
            declare
               use Ada.Strings.Unbounded;
               use type Exp.Expect_Match;
               Str    : Unbounded_String;
               Result : Exp.Expect_Match;
               Pid    : Integer;
            begin
               Reset_Last_Process_Matched (0);
               if Counter = 0 then
                  Exp.Expect (Result, P (1 .. N), 10);  -- Wait a little
               else
                  Exp.Expect (Result, P (1 .. N), 0);  -- Immediate
               end if;
               if Result = Exp.Expect_Timeout then
                  null;
               else
                  Pid := Last_Process_Matched;
                  if Pid = 0 then -- Callback not called, data left in buffer
                     Pid := Integer (Result);
                  end if;
                  --  Echo (Exp.Expect_Out_Match(P(Pid).Descriptor.all));
                  Console
                    ("||" &
                     Get_Pid_Name (Pid) &
                     " || " &
                     Exp.Expect_Out_Match (P (Pid).Descriptor.all),
                     Pid);
               end if;
               Str := Pace.Ses.Launch.Get_String;
               if Str = Null_Unbounded_String then
                  null;
               else
                  Interactive_Session (To_String (Str));
                  Echo ("P4> ", New_Line => False);
               end if;
            exception
               when Exp.Process_Died =>
                  if Terminate_If_Process_Dies then
                     Echo ("Detected process died, in quasi-monitoring mode.");
                     Shutdown (P (1 .. N));
                     Echo ("Operating in Terminate_If_Process_Dies mode.  Now exiting ...");
                     exit;
                  else
                     Echo ("Detected process died, in quasi-monitoring mode.");
                     Check_Health;
                     if not Monitor_Off then
                        delay 5.0;
                     end if;
                  end if;
               when Tasking_Error =>
                  Echo ("Text Termination detected ... shutting down");
                  Shutdown (P (1 .. N));
                  Echo ("Now exiting ...");
                  exit;
               when Text_IO.End_Error =>
                  Echo ("End of Text detected ... shutting down");
                  Shutdown (P (1 .. N));
                  Echo ("Now exiting ...");
                  exit;
               when E : others =>
                  Echo
                    ("try again ... " &
                     Ada.Exceptions.Exception_Information (E));
                  if Pid > N then
                     Echo ("Process identifier exceeds range of session");
                  end if;
                  Echo (Pace.Ses.Output_Marker);
            end;
         end loop;
      else
         loop
            delay Poll_Period;
            Echo ("Code test peek range polled: not implememented");
         end loop;
      end if;

      Echo ("Shutting down" & Integer'Image (N) & " active processes");
      Shutdown (P (1 .. N));
      Echo ("Exiting");
      Pace.Log.Os_Exit (0);

   exception
      when E : others =>
         Console ("P4: " & Ada.Exceptions.Exception_Information (E));
         Console ("Did shutdown complete? " & Boolean'Image (N = 0));
         if N > 0 then
            Console ("...shutting down...");
            Shutdown (P (1 .. N));
         end if;
         Console ("Now Exiting ...");
         Pace.Log.Os_Exit (1);
   end Start_Session;


   procedure Quit_Session (Text : in String) is
   begin
      Console (Text & " trying to exit ...");
      loop
         exit when N = 0;
         Echo (Text & " Shutting down" & Integer'Image (N));
         Quit (P (N));
         Echo (Text & " Shutdown" & Integer'Image (N));
         N := N - 1;
         if Ct_Num > N then
            Ct_Num := N;
         end if;
      end loop;
      Echo (Pace.Ses.Output_Marker);
      Console (Text & " now Exiting ...");
      Pace.Log.Os_Exit (1);
   end Quit_Session;

   procedure End_Session is
   begin
      Quit_Session ("External commanded");
   end End_Session;

   procedure Caught_Control_C is
   begin
      Quit_Session ("Ctrl-C handler");
   end Caught_Control_C;

begin
   GNAT.Ctrl_C.Install_Handler (Caught_Control_C'Access);
end Pace.Ses.P4;
