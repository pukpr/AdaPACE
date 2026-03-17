with Pace.Strings;
with Pace.Tcp.Http;
with Pace.Log.System;
with Pace.Server.Dispatch;
with Pace.Server.Home;
--with Ses.Codetest;
with Ses.Pp;
with Text_Io;

package body Uio.Server is

   Node : constant Integer := Pace.Getenv ("PACE_NODE", 0);
   Port : constant Integer := Pace.Getenv ("PACE_PORT_WEB", 5600) + Node;
   Sim_On : constant Boolean := 0 < Pace.Getenv ("PACE_SIM", 0);
   Loopback : constant Boolean := 1 = Pace.Getenv ("PACE_LOOPBACK", 1);


   function "+" (L, R : in String) return String is
   begin
      return L & "&" & R;
   end "+";

   function P (Key, Value : in String) return String is
   begin
      return Key & "=" & Value;
   end P;

   function P (Key : in String; Value : in Integer) return String is
   begin
      return P (Key, Pace.Strings.Trim (Value));
   end P;

   function P (Key : in String; Value : in Float) return String is
   begin
      return P (Key, Pace.Strings.Trim (Value));
   end P;

   function Url (Host : in String; Port : in Integer; Query : in String)
                return String is
   begin
--      return Pace.Tcp.Http.Get (Host, Port, Query);
      return Pace.Tcp.Http.Binary_Get (Host => "localhost",
                                      Port => Port,
                                      Item => Query,
                                      Header_Discard => True);
   end Url;

   function Url (Query : in String; Params : in String := "") return String is
   begin
      return Url ("localhost", Port, Query & "?" & Params);
   end Url;

   procedure Null_Display (Text : in String) is
   begin
      null;
   end Null_Display;

   procedure Cmd (Text : in String; Quit : out Boolean) is
      Saved_Display : Pace.Log.Display_Proc;
      use type Pace.Log.Display_Proc;
   begin
      if Text (Text'First) in 'A' .. 'z' then
         Saved_Display := Pace.Log.Get_Display;
         if Saved_Display = null then
            Pace.Log.Set_Display (Null_Display'Access);
         end if;
         if Loopback then
            Text_Io.Put_Line (Url ("localhost", Port, Text));
         else
            Text_Io.Put_Line (Pace.Server.Dispatch.Dispatch_To_Action (Text));
         end if;
         if Saved_Display = null then
            Pace.Log.Set_Display (Saved_Display);
         end if;
      end if;
      Quit := Text = "quit";
   end Cmd;

   task type Parser_Task (Ss : Integer) is
      pragma Storage_Size (Ss);
   end Parser_Task;
   type Parser_Access is access Parser_Task;
   task body Parser_Task is
   begin
      Ses.Pp.Parser (Cmd'Access);
      Pace.Log.Os_Exit (0);
   exception
      when Text_Io.End_Error =>
         -- To ALL Maintainers:
         -- This is where clean up stuff should go
         --
         Pace.Log.Os_Exit (0);
   end Parser_Task;

   procedure Create (Number_Of_Readers : in Integer := 10;
                     Storage_Size_Per_Reader : in Integer := 100_000;
                     P4_On : in Boolean := True) is
      Pa : Parser_Access;
      Num_Tasks : Integer := Number_Of_Readers;
   begin
      if Sim_On then
         Num_Tasks := 0;
      end if;
      Pace.Server.Home.Create (Number_Of_Readers => Num_Tasks,
                               Storage_Size_Per_Reader =>
                                 Storage_Size_Per_Reader);
      if P4_On and not Sim_On then
         Pa := new Parser_Task (Storage_Size_Per_Reader);
      end if;
   end Create;

   procedure Call (Query : in String; Params : in String := "") is
      Result : constant String :=
        Pace.Server.Dispatch.Dispatch_To_Action (Query & "?" & Params);
   begin
      if Result /= "" then
         Pace.Log.Put_Line ("#query#" & Result);
      end if;
   end Call;

   -- $Id: uio-server.adb,v 1.14 2006/04/14 23:14:16 pukitepa Exp $
end Uio.Server;
