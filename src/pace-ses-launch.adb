with Pace.Ses.Kb;
with Text_IO;
with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Pace.Ses.Lib;
with System;
with Pace.Command_Line;
with Pace.Log;

package body Pace.Ses.Launch is
   use Ada.Strings.Unbounded, Pace.Ses.Kb.Rules, Pace.Ses.Lib, Pace.Ses.Lib.Exp;
   Interactive : constant Boolean := not Pace.Command_Line.Has_Argument ("POLLED");
   CN : constant String := Pace.Command_Line.Path;

   Home        : constant String := CN & "../../ssom/test_tools/";
   Launch_Pro  : constant String := "p4_launch.pro";
   Launch_Path : constant String := Getenv ("P4PATH", Home) & "/";

   P : Processes (1 .. Max_Number_Of_Processes);

   type Colors is (
      Black,
      Red,
      Green,
      Yellow,
      Blue,
      Magenta,
      Cyan,
      White);
   Color_Lookup : constant array (Colors) of Character              :=
     (Black   => '0',
      Red     => '1',
      Green   => '2',
      Yellow  => '3',
      Blue    => '4',
      Magenta => '5',
      Cyan    => '6',
      White   => '7');
   Fg_Color     : array (0 .. Max_Number_Of_Processes) of Character :=
     (others => Color_Lookup (White));
   Bg_Color     : array (0 .. Max_Number_Of_Processes) of Character :=
     (others => Color_Lookup (Black));
   Colors_On    : Boolean                                           := False;

   procedure Console (Text : in String; Pid : in Integer := 0) is
      use Ada.Strings;
   begin
      if Colors_On then
         Text_IO.Put_Line
           (Text_IO.Standard_Error,
            ASCII.ESC &
            "[3" &
            Fg_Color (Pid) &
            ";4" &
            Bg_Color (Pid) &
            "m" &
            Text &
            ASCII.ESC &
            "[3" &
            Fg_Color (0) &
            ";4" &
            Bg_Color (0) &
            "m");
      else
         Text_IO.Put_Line (Text_IO.Standard_Error, Text);
      end if;
   end Console;


   Startup_CB : Startup_Callback := null;
   procedure Register_Startup_Callback (CB : in Startup_Callback) is
   begin
      Startup_CB := CB;
   end;

   protected Poster is
      procedure Put (Str : in String);
      function Get return Unbounded_String;
      function Ready return Boolean;
   private
      Ustr : Unbounded_String := Null_Unbounded_String;
   end Poster;

   protected body Poster is
      procedure Put (Str : in String) is
      begin
         if Str = "" then
            Ustr := Null_Unbounded_String;
         else
            Ustr := To_Unbounded_String (Str);
         end if;
      end Put;
      function Get return Unbounded_String is
      begin
         return Ustr;
      end Get;
      function Ready return Boolean is
      begin
         return Ustr /= Null_Unbounded_String;
      end Ready;
   end Poster;

   procedure Post (Str : in String) is
   begin
      Poster.Put (Str); -- Echo ("POST:" & Str);
   end Post;

   procedure Load
     (Session_Config_File : in String;
      Debug               : in Boolean := False)
   is
   begin
      Pace.Ses.Kb.Agent.Set_Post (Post'Access);
      Pace.Ses.Kb.Agent.Init ("", False, Debug);
      Pace.Ses.Kb.Agent.Assert ("p4path ('" & Launch_Path & "/')");
      Pace.Ses.Kb.Agent.Assert ("pwd ('" & Getenv ("PWD", ".") & "/')");
      Pace.Ses.Kb.Agent.Assert ("p4shell ('" & Getenv ("P4SHELL", "ssh") & "')");
      Pace.Ses.Kb.Agent.Load (Session_Config_File);
      Pace.Ses.Kb.Agent.Load (Launch_Path & Launch_Pro);
   exception
      when No_Match =>
         Echo ("No library:" & Launch_Path & Launch_Pro);
   end Load;

   Locked : Boolean := False;

   procedure Pid_Filter
     (Descriptor : Process_Descriptor'Class;
      Str        : String;
      User_Data  : System.Address := System.Null_Address)
   is
      Pid : constant Run_Id := Run_Id (Descriptor);
   begin
      if not Locked then
         if Str(Str'Last) = ASCII.LF then
            Console
              ("--" & Integer'Image (Get_Index (Pid)) & " -- " & Str(Str'First .. Str'Last-1) & " --",
               Pid => Get_Index (Pid));
         else
            Console
              ("--" & Integer'Image (Get_Index (Pid)) & " -- " & Str & " --",
               Pid => Get_Index (Pid));
         end if;
      end if;
   end Pid_Filter;

   Wild_Card_Match_Pattern : Pace.Ses.Lib.Re := Pace.Ses.Lib.Re_Pattern ("[ -~]{1,150}");

   procedure Remote_Exec
     (P                   : out Pace.Ses.Lib.Processes;
      N                   : out Natural;
      Common_Command_Args : in String := "";
      Dummy_Launch        : Boolean   := False)
   is
      Lower, Higher                                         : Integer;
      Target, Directory, Executive, Up_String, Display_Host : Unbounded_String;
      Wait_Time                                             : Duration;
      Result                                                : Expect_Match;
      Process_Up                                            : Integer;
      Trace                                                 : Boolean;
      Pid                                                   : Integer;
      Shell                                                 : Unbounded_String;
      function Remove_Quotes (S : in String) return String is
      begin
         if S(S'First) = '"' and S(S'Last) = '"' then
            return S(S'First+1 .. S'Last-1);
         else
            return S;
         end if;
      end Remove_Quotes;
   begin
      N := 0;
      for Groups in  1 .. Max_Number_Of_Processes loop
         declare
            V : Variables (1 .. 4);
         begin
            V (1) := +S (Groups);
            Pace.Ses.Kb.Agent.Query ("groups", V);
            Lower     := Integer'Value (+V (2));
            Higher    := Integer'Value (+V (3));
            Wait_Time := Duration'Value (+V (4));
         exception
            when No_Match =>
               exit;
         end;
         Echo
           ("Launching Group" &
            Integer'Image (Groups) &
            " ... after waiting" &
            Duration'Image (Wait_Time));
         delay Wait_Time;
         for Pid in  Lower .. Higher loop
            declare
               V : Variables (1 .. 7);
            begin
               V (1) := +S (Pid);
               if Dummy_Launch then
                  Pace.Ses.Kb.Agent.Query ("run_dummy", V);
               else
                  Pace.Ses.Kb.Agent.Query ("run", V);
               end if;
               Target       := V (2);
               Directory    := V (3);
               Executive    := V (4);
               Up_String    := V (5);
               Display_Host := V (6);
               Trace        := Boolean'Value (To_String (V (7)));
            exception
               when No_Match =>
                  exit;
            end;
            declare
               V : Variables (1 .. 2);
            begin
               V (1) := Target;
               Pace.Ses.Kb.Agent.Query ("launching_shell", V);
               Shell := V (2);
            exception
               when No_Match =>
                  Shell := +(Default_Shell);
            end;
            N := Pid;
            -- Launch each file here
            P (N) :=
               Run
                 (N,
                  Remove_Quotes(To_String (Target)),
                  To_String (Directory),
                  To_String (Executive) & " " & Common_Command_Args,
                  To_String (Up_String),
                  To_String (Display_Host),
                  To_String (Shell));
            if Trace then
               Add_Filter (P (N).Descriptor.all, Pid_Filter'Access);
            end if;
         end loop;
         Echo
           ("Expecting" &
            Integer'Image (Lower) &
            " .." &
            Integer'Image (Higher));
         loop
            Reset_Last_Process_Matched (0);
            -- Set Lower to 1 on the following if we want to capture 
            -- simultaneous outputs from previous launches
            Expect (Result, P (1 .. Higher), 10000);
            Pid := Pace.Ses.Lib.Last_Process_Matched;
            case Result is
               when Expect_Timeout =>
                  Echo ("Still waiting for processes to launch ...");
               when others =>
                  if Pid = 0 then -- Callback not called, data left in buffer
                     Pid := Integer (Result);
                  end if;
                  if Pid < Lower then  -- Print out old stuff that may get missed
                     if Trace then
                        null;
                     else
                        Console
                          ("++" &
                           Integer'Image (Pid) &
                           " ++ " &
                           Exp.Expect_Out_Match (P (Pid).Descriptor.all),
                           Pid => Pid);
                     end if;
                  else
                     if Trace then
                        Console
                          ("<<" &
                           Integer'Image (Pid) &
                           " >> <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>",
                           Pid => Pid);
                     else
                        Console
                          ("<<" &
                           Integer'Image (Pid) &
                           " >> " &
                           Exp.Expect_Out (P (Pid).Descriptor.all),
                           Pid => Pid);
                     end if;
                     Process_Up := Drawers_Ready;
                     Echo ("Process #" & Integer'Image (Pid) & " ready");
                     exit when Process_Up < 0;
                  end if;
            end case;
         end loop;
         Echo ("Group" & Integer'Image (Groups) & " released");
         -- Set these to wild-card matches to allow capture
         for Pid in Lower .. Higher loop
            P (Pid).Regexp := Wild_Card_Match_Pattern;
         end loop;
      end loop;
      if N = 0 then
         Echo ("No processes configured to launch, check the session config");
      else
         Echo ("All groups released");
      end if;
      -- Startup_Callback
      if Startup_CB /= null then
         Startup_CB.all;
      end if;
      Locked := Interactive;
   exception
      when Exp.Invalid_Process =>
         Echo ("Invalid process during launch, N =" & Integer'Image (N));
         if N > 0 then
            Echo ("...shutting down...");
            Shutdown (P (1 .. N));
         end if;
         Echo ("Now Exiting ...");
         Pace.Log.Os_Exit (1);
      when Exp.Process_Died =>
         Echo ("A process died during launch, N =" & Integer'Image (N));
         if N > 0 then
            Echo ("...shutting down...");
            Shutdown (P (1 .. N));
         end if;
         Echo ("Now Exiting ...");
         Pace.Log.Os_Exit (1);
   end Remote_Exec;

   -- Asynchronous Keyboard handler

   task Getter is
      entry Ch (Text : out Unbounded_String);
      pragma Storage_Size (1_000_000);
   end Getter;


   task body Getter is
      Str : Unbounded_String;
   begin
      loop
         begin
            declare
               S : constant String := Text_IO.Get_Line; --  Ada 2005
            begin
               accept Ch (Text : out Unbounded_String) do
                  if S = "" then
                     Text := To_Unbounded_String (" ");
                  else
                     Text := To_Unbounded_String (S);
                  end if;
               end Ch;
            end;
         exception
            when Text_IO.End_Error =>
               delay 0.1;
         end;
      end loop;
   end Getter;

   function Get_String return Ada.Strings.Unbounded.Unbounded_String is
      Str : Unbounded_String;
   begin
      select
         Getter.Ch (Str);
         return Str;
      else
         if Poster.Ready then
            Str := Poster.Get;
            Poster.Put ("");
            return Str; -- Null_Unbounded_String;
         else
            return Null_Unbounded_String;
         end if;
      end select;
   end Get_String;

   procedure Set_Colors (Process : in Integer) is
      --      use Ses.KB.Rules;
      M : Variables (1 .. 3);
   begin
      M (1) := +Integer'Image (Process);
      Pace.Ses.Kb.Agent.Query ("color", M);
      Fg_Color (Process) := Color_Lookup (Colors'Value (+M (2)));
      Bg_Color (Process) := Color_Lookup (Colors'Value (+M (3)));
      Colors_On          := True;
   exception
      when No_Match =>
         null;
   end Set_Colors;

end Pace.Ses.Launch;
