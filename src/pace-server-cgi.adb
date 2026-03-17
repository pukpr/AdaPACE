--with    Gnu.Pipe_Commands;
with GNAT.Expect;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Pace.Config;

function Pace.Server.Cgi (Exec : in String) return String is
--   Pipe   : Gnu.Pipe_Commands.Stream;
   Index  : Integer         := Ada.Strings.Fixed.Index (Exec, ".cgi") + 3;
   -- Topic is the stuff to the right of the cgi, separated by "/", ala Twiki
   Topic  : constant String :=
      Ada.Strings.Fixed.Delete (Exec, Exec'First, Index);
   Script : constant String := Exec (Exec'First .. Index);
   Method : constant String := Pace.Server.Get_Method;
   Query  : constant String :=
      Pace.Server.Value ("") &
      "&topic=" &
      Topic (Topic'First + 1 .. Topic'Last);
   Status : aliased Integer;
   function Get_Q return String is
   begin
      if Method = "GET" then
         return "";
      end if;
      return Query;
   end;

begin
   Ada.Environment_Variables.Set ("HTTP_USER_AGENT", "Mozilla/5.0");
   Ada.Environment_Variables.Set ("REQUEST_URI", Exec);
   Ada.Environment_Variables.Set ("REQUEST_METHOD", Method);
   Ada.Environment_Variables.Set ("SERVER_NAME", Pace.Getenv ("HOST", "localhost"));
   -- Port 5666 is setup as a generic web server mode, for hosting Twiki, etc
   Ada.Environment_Variables.Set ("SERVER_PORT", "56" & Pace.Getenv ("PACE_NODE", "66"));
   Ada.Environment_Variables.Set ("SCRIPT_NAME", Script);
   if Method = "GET" then
      Ada.Environment_Variables.Set ("QUERY_STRING", Query);
--       Pipe :=
--          Gnu.Pipe_Commands.Execute
--            ("html/" & Script,
--             Gnu.Pipe_Commands.Read_File);
   else
      -- Should we clear QUERY_STRING ?  This is globally set.
      Ada.Environment_Variables.Set ("CONTENT_LENGTH", Integer'Image (Query'Length));
--       Pipe :=
--          Gnu.Pipe_Commands.Execute
--            ("html/" & Script,
--             Gnu.Pipe_Commands.Rw_File);
--       Gnu.Pipe_Commands.Write (Pipe, Query);
--       Gnu.Pipe_Commands.Flush_Pipe (Pipe);
   end if;
   declare
      Data : constant String := -- Gnu.Pipe_Commands.Read_All (Pipe);
      GNAT.Expect.Get_Command_Output (Pace.Config.Find_File ("/html/" & Script),
                                      (1..0 => null), 
                                      Get_Q, Status'Unchecked_Access, True);
   begin
      -- This "if" is Twiki specific stuff
      if Data (Data'First) = 'S' then
         -- This could be a "Status: 302 Moved" directive
         -- Next line is "Location: http://..."
         --Pace.Server.Put_Data ("");
         Index := Ada.Strings.Fixed.Index (Data, "5666");
         -- Page (Pace.Strings.Select_Field (Data, 4));
         -- Pace.Server.Home.Page ();
         return Data (Index + 4 .. Data'Last);
      else
         Pace.Server.Put_Data ("HTTP/1.0 200 OK");
      end if;
      Pace.Display
        ("loading CGI " & Method & " " & Script & "#" & Query & " size=" &
         Integer'Image (Data'Length));
      Pace.Server.Put_Data (Text => Data, More_Follows => True, Raw => True);
   end;
   Pace.Server.Send_Data ("");
--   Gnu.Pipe_Commands.Close (Pipe);
   return "";
end Pace.Server.Cgi;
