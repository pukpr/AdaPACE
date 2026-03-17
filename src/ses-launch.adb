with Ses.Kb;
with Text_IO;
with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ses.Lib;
with System;

package body Ses.Launch is
   use Ada.Strings.Unbounded, Ses.Kb.Rules, Ses.Lib, Ses.Lib.Exp;
   Interactive : constant Boolean := not Ses.Lib.Argument ("POLLED");

   Home        : constant String := "./";
   Launch_Pro  : constant String := "launch.pro";
   Launch_Path : constant String :=
       Ses.Lib.Getenv("P4PATH", Home & Launch_Pro);

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
      Ses.Kb.Agent.Set_Post (Post'Access);
      Ses.Kb.Agent.Init ("", False, Debug);
      Ses.Kb.Agent.Load (Session_Config_File);
      Ses.Kb.Agent.Load (Launch_Path);
      Ses.Kb.Agent.Assert ("pwd ('" & Ses.Lib.Getenv ("PWD", ".") & "/')");
   exception
      when No_Match =>
         Echo ("No library:" & Launch_Path);
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

   Wild_Card_Match_Pattern : Ses.Lib.Re := Ses.Lib.Re_Pattern ("[ -~]{1,150}");

   procedure Remote_Exec
     (P                   : out Ses.Lib.Processes;
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
   begin
      for Groups in  1 .. Max_Number_Of_Processes loop
         declare
            V : Variables (1 .. 4);
         begin
            V (1) := +S (Groups);
            Ses.Kb.Agent.Query ("groups", V);
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
                  Ses.Kb.Agent.Query ("run_dummy", V);
               else
                  Ses.Kb.Agent.Query ("run", V);
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
            N := Pid;
            -- Launch each file here
            P (N) :=
               Run
                 (N,
                  To_String (Target),
                  To_String (Directory),
                  To_String (Executive) & " " & Common_Command_Args,
                  To_String (Up_String),
                  To_String (Display_Host));
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
            Pid := Ses.Lib.Last_Process_Matched;
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
      Echo ("All groups released");
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
         Ses.Os_Exit (1);
      when Exp.Process_Died =>
         Echo ("A process died during launch, N =" & Integer'Image (N));
         if N > 0 then
            Echo ("...shutting down...");
            Shutdown (P (1 .. N));
         end if;
         Echo ("Now Exiting ...");
         Ses.Os_Exit (1);
   end Remote_Exec;

   function Table_Name (Pid : in Integer) return String is
      V : Variables (1 .. 2);
   begin
      V (1) := +S (Pid);
      Ses.Kb.Agent.Query ("table", V);
      return +V (2);
   end Table_Name;

   -- Asynchronous Keyboard handler

   task Getter is
      entry Ch (Text : out Unbounded_String);
      pragma Storage_Size (1_000_000);
   end Getter;
   --------------
   -- Get_Line --
   --------------

   Buflen : constant := 500;  -- smaller values require more recursion

   function Get_Line return String is -- Apex safe call
      Buffer : String (1 .. Buflen);
      C : Character;
      Val : Integer;
      function Get_Char return Integer;
      pragma Import (C, Get_Char, "getchar");
   begin
      for Nstore in Buffer'Range loop
         Val := Get_Char;
         if Val = -1 then
            raise Text_Io.End_Error;
         end if;
         C := Character'Val (Val);
         if C = Ascii.Lf then
            return Buffer (1 .. Nstore - 1);
         else
            Buffer (Nstore) := C;
         end if;
      end loop;
      return Buffer & Get_Line;
   end Get_Line;


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
      Ses.Kb.Agent.Query ("color", M);
      Fg_Color (Process) := Color_Lookup (Colors'Value (+M (2)));
      Bg_Color (Process) := Color_Lookup (Colors'Value (+M (3)));
      Colors_On          := True;
   exception
      when No_Match =>
         null;
   end Set_Colors;

end Ses.Launch;
