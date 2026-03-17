with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Exceptions;
with Ses.Codetest.Idb;
with Ses.Kb;
with Ses.Launch;
with Ses.Lib;
with Ses.Codetest.Lib;
with Text_IO;
with Ada.Integer_Text_IO;
with Ses.Symbols;
with Gnat.Regpat;
with Calendar;

package body Ses.P4 is
   use Ses.Lib;
   subtype Process_Range is Integer range
      1 .. Ses.Launch.Max_Number_Of_Processes;
   P                       : Processes (Process_Range);
   T                       : Ses.Codetest.Lib.Tables (Process_Range);
   Lows                    : array (Process_Range) of Integer;
   Highs                   : array (Process_Range) of Integer;
   N                       : Natural          := 0;
   Ct_Num                  : Natural          := 0;
   Table_Size              : constant String  :=
      Ses.Lib.Getenv ("CT_TABLE_SIZE", "5000");
   Table                   : Ses.Codetest.Idb.Index_Lookup (
      1 .. Integer'Value (Table_Size));
   Wait_On                 : constant Boolean :=
      Ses.Lib.Argument (Ses.Codetest.Pipe_Mode);
   Debug_On                : constant Boolean :=
      not Ses.Lib.Argument ("NO_SESSION_DEBUG");
   Monitor_Off             : constant Boolean :=
      Ses.Lib.Argument ("MONITOR_OFF");
   Testing                 : constant Boolean := Ses.Lib.Argument ("TESTING");
   Checking                : constant Boolean :=
      Ses.Lib.Argument ("CHECK") or Ses.Lib.Getenv ("P4CHECK", "0") = "1";
   Commanding                : constant Boolean :=
      Ses.Lib.Argument ("CMDS") or Ses.Lib.Getenv ("P4CMDS", "0") = "1";
   Get_Symbols             : constant Boolean := Ses.Lib.Argument ("SYMBOLS");
   Session_Pro             : constant String  :=
      Ses.Lib.Argument ("-pro", "session.pro");
   Interactive             : constant Boolean :=
      not Ses.Lib.Argument ("POLLED");
   Help                    : constant Boolean := Ses.Lib.Argument ("HELP");
   Print_Idb               : constant Boolean :=
      Ses.Lib.Argument ("PRINT_IDB");
   Expect_Timeout          : Integer          := 10_000;
   Poll_Period             : Duration         := 0.001;
   Wild_Card_Match_Pattern : Ses.Lib.Re       :=
      Ses.Lib.Re_Pattern ("[ -~]{1,150}");  -- RTCOE has 132 characters
   P4_Pattern              : Ses.Lib.Re       :=
      Ses.Lib.Re_Pattern (Ses.Output_Marker & "\n");
   Verbose_Name            : Boolean          :=
      Ses.Lib.Argument ("VERBOSE_NAME");
   Time_Stamp              : Boolean          :=
      Ses.Lib.Argument ("TIME_STAMP");
   Terminate_If_Process_Dies : Boolean        := Ses.Lib.Getenv ("P4_TERMINATE_IF_PROCESS_DIES", "0") = "1";

   ------------
   -- Query
   ------------
   procedure Query (Functor : in String) is
      -- use Gnu.Rule_Processor.Db;
      use Ses.Kb.Rules;
   -- V : Variables (1..0);
   begin
      Ses.Kb.Agent.Parse (Functor);
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
     Ses.Launch.Console;

   ----------------
   -- Get_Pid_Name
   ----------------
   function Get_Pid_Name (Pid : Integer) return String is
      function Show_Time (Text : in String) return String is
         Y : Calendar.Year_Number;
         M : Calendar.Month_Number;
         D : Calendar.Day_Number;
         S : Calendar.Day_Duration;
      --          function Trim (S : in String) return String is
      --        begin
      --           return Ada.Strings.Fixed.Trim (S, Ada.Strings.Left);
      --        end;
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
                   Ses.Lib.Get_Name (Ses.Lib.Run_Id (P (Pid).Descriptor.all)));
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
               Cmd_Address : constant String :=
                  Ses.Symbols.Get_Address (Pid, Cmd);
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
                  Ses.Output_Marker,
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
                        Ses.Lib.Select_Field (Cmd_Address, 1);
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
                       (Remove_Dot (Ses.Lib.Select_Field (Cmd, 1)) &
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
      Nf  : constant Integer := Ses.Lib.Count_Fields (Text);
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
            Pid := Integer'Value (Ses.Lib.Select_Field (Text, 1));
         exception
            when Constraint_Error =>
               Query (Text);
               Echo (Ses.Output_Marker);
               return;
         end;
         if Pid = 0 then
            if Nf = 1 then
               Echo
                 (Ses.Codetest.Lib.Peek_Image
                     (P (1 .. Ct_Num),
                      T (1 .. Ct_Num),
                      Wait_On));
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
            Echo
              (Ses.Codetest.Lib.Peek_Image (P (Pid), T (Pid).all, Wait_On));
         else
            Send_Text (Text, Pid);
         end if;
      end if;
      Echo (Ses.Output_Marker);
   exception
      when E : others =>
         Echo ("try again ... " & Ada.Exceptions.Exception_Information (E));
         if Pid > N then
            Echo ("Process identifier exceeds range of session");
         end if;
         Echo (Ses.Output_Marker);
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
               Ses.Output_Marker,
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

   ------------
   -- Read_IDB
   ------------
   procedure Read_Idb is
      Ct_Idb : constant String := Ses.Lib.Argument ("-idb", "codetest");
   begin
      Ses.Codetest.Idb.Read_Idb (Table, Ct_Idb);
      for I in  Table'Range loop
         declare
            Str : constant String := Ses.Codetest.Idb.Get (Table, I);
         begin
            Text_IO.Put (Integer'Image (I) & " ");
            Ada.Integer_Text_IO.Put (I, Base => 16);
            Text_IO.Put_Line (" " & Str);
            exit when Str (1) = '#';
         end;
      end loop;
   end Read_Idb;

   ------------------
   -- Set_Poll_Period
   ------------------
   procedure Set_Poll_Period is
      use Ses.Kb.Rules;
      M : Variables (1 .. 1);
   begin
      Ses.Kb.Agent.Query ("poll_period", M);
      Poll_Period := Duration (Float'Value (+M (1)));
   exception
      when No_Match =>
         Echo
           ("Using default for Poll Period:" & Duration'Image (Poll_Period));
   end Set_Poll_Period;

   ----------------------
   -- Set_Expect_Timeout
   ----------------------
   procedure Set_Expect_Timeout is
      use Ses.Kb.Rules;
      M : Variables (1 .. 1);
   begin
      Ses.Kb.Agent.Query ("expect_timeout", M);
      Expect_Timeout := Integer'Value (+M (1));
   exception
      when No_Match =>
         Echo
           ("Using default for Expect timeout:" &
            Integer'Image (Expect_Timeout));
   end Set_Expect_Timeout;

   -------------------------------
   -- Set_Codetest_Scope_Variables
   -------------------------------
   procedure Set_Codetest_Scope_Variables (Process : in Process_Range) is
      use Ses.Kb.Rules;
      M : Variables (1 .. 3);
   begin
      M (1) := +Integer'Image (Process);
      Ses.Kb.Agent.Query ("scope_vars", M);
      Lows (Process)  := Integer'Value (+M (2));
      Highs (Process) := Integer'Value (+M (3));
   exception
      when No_Match =>
         Echo
           ("Using entire range for CodeTest Scope #" &
            Integer'Image (Process));
   end Set_Codetest_Scope_Variables;

   -------------------------------
   -- Set_Codetest_Table
   -------------------------------
   procedure Set_Codetest_Table (Process : in Process_Range) is
   begin
      Ses.Codetest.Idb.Read_Idb (Table, Ses.Launch.Table_Name (Process));
      T (Process) := new Ses.Codetest.Idb.Index_Lookup'(Table);
      --   exception
      --      when Ses.Kb.Rules.No_Match =>
      --         Echo ("No CodeTest IDB name found for #" &
      --               Integer'Image (Process)); -- exit;
   end Set_Codetest_Table;

   procedure Check_Options is
   begin
      if Help then
         Echo (
"Interactive mode : 1st field must be integer PID (else a query to profile)");
         Echo (
"         syntax  : PID ([.sym] | [.sym] [val] | [16#addr# type[:val]] | [command string])"
);
         Echo
           ("PID=-1000 => shutdown all, PID=negative => shutdown N .. N-PID+1")
;
         Ses.Os_Exit (0);
      elsif Print_Idb then
         Read_Idb;
         Ses.Os_Exit (0);
      else
         Ses.Launch.Load (Session_Pro, Debug_On);
         if Testing then
            Query ("test");
         elsif Get_Symbols then
            Query ("get_var");
            Ses.Os_Exit (0);
         elsif Checking then
            Query ("get_var");
            Query ("test");
            Ses.Os_Exit (0);
         elsif Commanding then
            Query ("commands");
            Ses.Os_Exit (0);
         end if;
      end if;
   end Check_Options;

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

      Set_Poll_Period;
      Set_Expect_Timeout;

      Ct_Num := Ses.Symbols.Init;

      -- Table_Lookup
      for I in  1 .. Ct_Num loop
         Set_Codetest_Table (Process => I);
         Set_Codetest_Scope_Variables (Process => I);
         Ses.Launch.Set_Colors (Process => I);
      end loop;
      Ses.Launch.Set_Colors (Process => 0);

      if Wait_On then
         Ses.Launch.Remote_Exec
           (P,
            N,
            Common_Command_Args => Ses.Codetest.Pipe_Mode,
            Dummy_Launch        => Testing);
      else
         Ses.Launch.Remote_Exec
           (P,
            N,
            Common_Command_Args => "",
            Dummy_Launch        => Testing);
      end if;

      for I in  1 .. Ct_Num loop
         Ses.Codetest.Lib.Poke_Scope (P (I), Lows (I), Highs (I));
      end loop;

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
               Str := Ses.Launch.Get_String;
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
                  Echo (Ses.Output_Marker);
            end;
         end loop;
      else
         loop
            delay Poll_Period;
            Console
              (Ses.Codetest.Lib.Peek_Image
                  (P (1 .. Ct_Num),
                   T (1 .. Ct_Num),
                   Wait_On));
         end loop;
      end if;

      Echo ("Shutting down" & Integer'Image (N) & " active processes");
      Shutdown (P (1 .. N));
      Echo ("Exiting");
      Ses.Os_Exit (0);

   exception
      when E : others =>
         Console ("P4: " & Ada.Exceptions.Exception_Information (E));
         Console ("Did shutdown complete? " & Boolean'Image (N = 0));
         if N > 0 then
            Console ("...shutting down...");
            Shutdown (P (1 .. N));
         end if;
         Console ("Now Exiting ...");
         Ses.Os_Exit (1);
   end Start_Session;

end Ses.P4;
