with Text_Io;
--P-- with   Gnu.Pipe_Commands;
with Pace.Tcp.Http;
with Ada.Strings.Unbounded;
with Pace.Server.Dispatch;
with Pace.Server;
with Pace.Config;
with Pace.Log;
with GNAT.Expect;

package body Pace.Ses.P2X is

   Run_A2x : constant Boolean := Pace.Getenv ("PACE_A2X", "0") = "1";
   A2x_Exec : constant String := Pace.Config.Find_File ("test_tools/a2x.sh");
   --P--      File : Gnu.Pipe_Commands.Stream;
   Proc : GNAT.Expect.Process_Descriptor;

   procedure Write_Flush (Str : String) is
   begin
      --P--   Gnu.Pipe_Commands.Write (File, Str);
      --P--   Gnu.Pipe_Commands.Flush_Pipe (File);
      GNAT.Expect.Send (Proc, Str);
   end;

   procedure Process_Command (Str : String) is
      Len : constant Integer := Str'Length;

      P4_Marker : constant String := Pace.Ses.Output_Marker; -- "__ p4 __";

      -- Basic commands
      T : constant Character := Character'Val (20);                  -- ^T
      Autorepeat : constant String := T & Character'Val (1);     -- ^A
      Button : constant String := T & Character'Val (2);     -- ^B
      Control : constant String := T & Character'Val (3);     -- ^C
      Displace : constant String := T & Character'Val (4);     -- ^D
      Exit_Now : constant String := T & Character'Val (5);     -- ^E
      Fxn_Macro : constant String := T & Character'Val (6);     -- ^F
      Grid : constant String := T & Character'Val (7);     -- ^G
      If_Test : constant String := T & Character'Val (9);     -- ^I
      Jump : constant String := T & Character'Val (10);    -- ^J
      Locate : constant String := T & Character'Val (12);    -- ^L
      Meta : constant String := T & Character'Val (13);    -- ^M
      Print_Debug : constant String := T & Character'Val (16);    -- ^P
      Quit_Move : constant String := T & Character'Val (17);    -- ^Q
      Remote_Display : constant String := T & Character'Val (18);    -- ^R
      Shift : constant String := T & Character'Val (19);    -- ^S
      T_Escape : constant String := T & T;                    -- ^T
      Undo_File : constant String := T & Character'Val (21);    -- ^U
      View_Echo : constant String := T & Character'Val (22);    -- ^V
      Warp : constant String := T & Character'Val (23);    -- ^W
      Yield : constant String := T & Character'Val (25);    -- ^Y
      Zzz : constant String := T & Character'Val (26);    -- ^Z

      -- Constructed commands
      Position : constant String := Warp & 'S';
      Display : constant String := Remote_Display & 'D';

      Alt_F10 : constant Character := Character'Val (21);

      procedure Send (Str : in String) is
      begin
         --Pipe.Write (File, Str);
         --Pipe.Flush_Pipe (File);
         -- Send (Process, Str);
         Write_Flush (Str);
         Text_Io.Put_Line (P4_Marker);
      end Send;

      procedure Query_Window (Name : in String) is
         Test : constant String := If_Test & "i0n";
         If_True : constant String := T & If_Test & "t0" & T & View_Echo;
         Else_False : constant String :=
           " = true" & Ascii.Lf & P4_Marker & Ascii.Lf &
             T & If_Test & "l0" & T & View_Echo;
         Finish : constant String := " = false" & Ascii.Lf & P4_Marker &
                                       Ascii.Lf & T & If_Test & "n0" & T;
      begin
         --Pipe.Write (File, Test & Name & If_True & Name &
         --                    Else_False & Name & Finish);
         --Pipe.Flush_Pipe (File);
         Write_Flush (Test & Name & If_True & Name & Else_False & Name & Finish);
      end Query_Window;

      procedure Pp_Catcher (Name : in String) is
      begin
         if Name = ".codetest__timing" then
            Text_Io.Put_Line (Name & " = -1660616702");
         elsif Name = ".codetest__synchpoint" then
            Text_Io.Put_Line (Name & " = 0.0");
         else
            Text_Io.Put_Line (Name & " = 0");
         end if;
         Text_Io.Put_Line (P4_Marker);
      end Pp_Catcher;


      function Get_Cmd return String is
      begin
         for I in 2 .. Len loop
            if Str (I) /= ' ' then
               return Str (I .. Len);
            end if;
         end loop;
         return Str (Str'First + 1 .. Len);
      end Get_Cmd;

      use Ada.Strings.Unbounded;
      Host_Url : Unbounded_String;

   begin

      if not Run_A2x then
         Text_Io.Put_Line ("P2X not invoked");
         Text_Io.Put_Line (P4_Marker);
         return;
      end if;

      case Str (Str'First) is
         --
         --  Main commands
         --
         when 'a' =>
            Send (Meta & Get_Cmd & T);
         when 'b' =>
            Send (Button & " " & Get_Cmd & T);
         when 'd' =>
            Send (Display & Get_Cmd & T);
         when 'f' =>
            Send (Ascii.Esc & Alt_F10);
         when 'h' =>
            Host_Url := To_Unbounded_String (Get_Cmd);
         when 'm' =>
            Send (Displace & " " & Get_Cmd & T);
         when 'p' =>
            Send (Position & " " & Get_Cmd & T);
         when 's' =>
            Send (Zzz & " " & Get_Cmd & T);
         when 't' =>
            Send (Get_Cmd);
         when 'x' =>
            Send (Exit_Now);
            GNAT.Expect.Close (Proc);
         when 'q' =>
            Query_Window (Get_Cmd);
         when 'u' =>
            Pace.Tcp.Http.Get (To_String (Host_Url), Get_Cmd);
         when 'w' =>
            delay (Duration'Value (Get_Cmd));
            --
            -- CodeTest and Peek/Poke interface stuff
            --
         when '.' | '0' .. '9' =>
            Pp_Catcher (Str (Str'First .. Len));
         when Ascii.Eot =>
            GNAT.Expect.Close (Proc);
            raise Text_Io.End_Error;
         when others =>
            null;
      end case;
   end Process_Command;


   -- changes display
   type Set_Display is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Set_Display);
   procedure Inout (Obj : in out Set_Display) is
      Command : String := "d " & Pace.Server.Keys.Value ("set", "");
   begin
      Process_Command (Command);
      Pace.Server.Put_Data ("setting display");
   end Inout;

   -- pushes and releases the mouse
   type Push is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Push);
   procedure Inout (Obj : in out Push) is
      Command : String := "b 1";
   begin
      Process_Command (Command);
      Pace.Log.Wait (0.1);
      Process_Command (Command);
   end Inout;

   -- presses the mouse button
   type Press is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Press);
   procedure Inout (Obj : in out Press) is
      Command : String := "b 1";
   begin
      Process_Command (Command);
   end Inout;

   -- releases the mouse button
   type Release is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Release);
   procedure Inout (Obj : in out Release) is
      Command : String := "b 1";
   begin
      Process_Command (Command);
   end Inout;

   -- places the mouse cursor
   type Place is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Place);
   procedure Inout (Obj : in out Place) is
      Command : String := "p " & Pace.Server.Keys.Value ("set", "");
   begin
      Process_Command (Command);
   end Inout;

   -- relatively moves the mouse cursor
   type Move is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Move);
   procedure Inout (Obj : in out Move) is
      Command : String := "m " & Pace.Server.Keys.Value ("set", "");
   begin
      Process_Command (Command);
   end Inout;

   -- sends keyboard pushes
   type Keyboard is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Keyboard);
   procedure Inout (Obj : in out Keyboard) is
      Command : String := "t " & Pace.Server.Keys.Value ("set", "");
   begin
      Process_Command (Command);
      Pace.Server.Put_Data ("pressing a key");
   end Inout;

   -- sends quit
   type Quit is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Quit);
   procedure Inout (Obj : in out Quit) is
      Command : String := "x";
   begin
      Process_Command (Command);
      Pace.Server.Put_Data ("exiting a2x");
   end Inout;

   use Pace.Server.Dispatch;
begin
   Save_Action (Set_Display'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (Push'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (Press'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (Release'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (Place'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (Move'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (Keyboard'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (Quit'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   --P--  File := Gnu.Pipe_Commands.Execute (A2x_Exec, Gnu.Pipe_Commands.Write_File);
   if Run_A2x then
      GNAT.Expect.Non_Blocking_Spawn (Proc, A2x_Exec, (1..0 => null), Err_To_Out => False);
   else
      Pace.Log.Put_Line ("Note: P2X disabled (no spawned A2X process)");
   end if;
   -- $Id: ses-p2x.adb,v 1.9 2006/04/19 18:22:14 ludwiglj Exp $
end Pace.Ses.P2X;
