with Pace.Ports;
with Ada.Task_Attributes;
with Pace.Log;
with Pace.Strings;
with Ada.Text_Io;
with Ada.Strings.Fixed;

with Pace.Config;
with Ada.Calendar;
with Ada.Characters.Handling;
with Gnat.Calendar;
with Ual.Utilities;
with Ada.Strings.Maps;

package body Pace.Server is

   use Pace.Strings;

   Code_Mapping : array(Response_Code'Range) of Bstr.Bounded_String := (R200 => S2b ("200 OK"),
                                                                        R204 => S2b ("204 No Content"),
                                                                        R304 => S2b ("304 Not Modified"),
                                                                        R404 => S2b ("404 Not Found"));

   package Parameters is
      ---------------------------------------------------------------
      -- PARAMETERS -- CGI lookup "http://hoohoo.ncsa.uiuc.edu/cgi/".
      ---------------------------------------------------------------

      function Get_Bin (Query : in String) return String; -- the CGI bin name

      -- This package splits the input into a set of variables that can be accessed
      -- by position or by name.
      -- An "Isindex" request is translated into a request with a single
      -- key named "isindex" with its Value as the query value.

      -- This package provides CGI Parameters two ways:
      -- 1) Associative access; provide the key name and the
      --    value associated with that key will be returned.
      -- 2) As a sequence of key-value pairs, indexed from 1 to Argument_Count.
      --    This is similar to the Ada pre-defined package Ada.Command_Line.
      -------------------------------------------------------------------
      function Is_Index (Query : in String)
                         return Boolean;  -- True if an Isindex request made.

      -------------------------------------------------------------------
      -- Access data as an associative array - given a key, return its value.
      -- The Key value is case-sensitive.
      -- If a key is not present, Value raises Constraint_Error;
      --
      function Value (Query : in String; Key : in String) return String;
      function Key_Exists (Query : in String; Key : in String) return Boolean;
      function Value_Count (Query : in String; Key : in String) return Natural;


      -- Creates a query from CGI environment variable
      function Create_Query_From_Environment return String;

      function Get_Method (Query : in String) return String; -- GET/POST

   end Parameters;

   package body Parameters is separate;

   package Task_Finder is new Ada.Task_Attributes (Session_Access, null);
   Boundary_Tag : constant String := "PACE";


   Day_Names : constant array (Gnat.Calendar.Day_Name) of String (1 .. 3) :=
     ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun");
   Month_Names : constant array (Ada.Calendar.Month_Number) of String (1 .. 3) :=
     ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
   function To_Http_Date (The_Time : Duration) return String is

      -- from RFC2616, section 3.3.1
      -- Sun, 06 Nov 1994 08:49:37 GMT  ; RFC 822, updated by RFC 1123

      use Ada.Calendar;
      use Ual.Utilities;

      function Pad (Num : Integer) return String is
         Num_Str : String := Trim (Num);
      begin
         if Num_Str'Length = 1 then
            return "0" & Num_Str;
         else
            return Num_Str;
         end if;
      end Pad;

      Year : Year_Number;
      Month : Month_Number;
      Day : Day_Number;
      Hours : Integer;
      Minutes : Integer;
      Seconds : Integer;
      Seconds_In_Day : Duration;
      Day_Of_Week : Gnat.Calendar.Day_Name := Pace.Config.Day_Of_Week (The_Time);
   begin
      Pace.Config.To_Calendar_Time(The_Time, Year, Month, Day, Seconds_In_Day);
      Dur_To_Time (Seconds_In_Day, Hours, Minutes, Seconds);
      return Day_Names (Day_Of_Week) & ", " & Pad (Day) & " " & Month_Names (Month) & " " &
        Trim (Year) & " " & Pad (Hours) & ":" & Pad (Minutes) & ":" & Pad(Seconds) & " GMT";
   end To_Http_Date;

   procedure Put_Header (Fd : in Socket_Type;
                         Content : in String;
                         Etag : Bstr.Bounded_String := S2b ("");
                         Code : Response_Code := R200) is
      Url : constant String := "url";
      Ref : constant String := "refresh";
   begin
--       if Not_Modified then
--          Put_Line (Fd, "HTTP/1.0 304 Not Modified");
--       elsif Key_Exists (Url) and then Value (Url) = "" then
--          Put_Line (Fd, "HTTP/1.0 204 No Content");
--       elseb
--          Put_Line (Fd, "HTTP/1.0 200 OK");
--       end if;
      Put_Line (Fd, "HTTP/1.0 " & B2s (Code_Mapping (Code)));
      if Code /= R304 then
         Put_Line (Fd, "Content-type: " & Content);
--         Put_Line (Fd, "Connection: keep-alive");
         if Key_Exists (Ref) then
            Put_Line (Fd, "Refresh: " & Value (Ref));
         end if;
      end if;
      Put_Line (Fd, "Date: " & To_Http_Date (Pace.Now));
      if Default_Session.Is_Conditional_Get then
         Put_Line (Fd, "ETag: " & '"' & B2s (Etag) & '"');
      end if;
      New_Line (Fd);
   end Put_Header;


   task body Reader is
      use Pace.Ports;
   begin
      Pace.Log.Agent_Id ("PACE.SERVER" & Integer'Image (-Size));
      Task_Finder.Set_Value (Session.This);
      loop
         begin
            Session.Is_Conditional_Get := False;
            Session.Etag := S2b ("");
            Session.If_Match := S2b ("");
            Accept_Connection (Host_And_Port => Unique_Name (Web),
                               Port => Session.Port,
                               Fd => Session.Fd,
                               Client => Session.Client_Handle);
            --
            -- Reading incoming request
            --
            declare
               Header : constant String := Get_Line (Session.Fd);
               Content_Length : Integer := 0;
               Is_Post_Request : Boolean := False;

               function Check_End (Line : in String) return Boolean is
                  use Ada.Strings.Unbounded;
                  use Ada.Strings.Fixed;
                  -- http headers are case insensitive
                  Lower_Line : String := Ada.Characters.Handling.To_Lower (Line);
                  If_Match_Str : String := "if-none-match:";
               begin
                  if Select_Field (Lower_Line, 1) = "content-length:" then
                     Content_Length := Integer'Value (Select_Field (Lower_Line, 2));
                     Is_Post_Request := True;
                  elsif Select_Field (Lower_Line, 1) = If_Match_Str then
                     Session.Is_Conditional_Get := True;
                     Session.If_Match := S2b (Select_Field (Lower_Line, 2, '"'));   -- " for Xemacs Highlighting
                  elsif Select_Field (Lower_Line, 1) = "user-agent:" then
                     Session.User_Agent := S2u (Select_Field (Lower_Line, 2));
                  elsif Select_Field (Lower_Line, 1) = "host:" then
                     Session.Host := S2u (Select_Field (Lower_Line, 2));
                  elsif Lower_Line = "" then  -- done with request headers
                     if Is_Post_Request then
                        declare
                           Data : String (1 .. Content_Length);
                        begin
                           Physical_Receive (Session.Fd, Data'Address, Content_Length);
                           Session.Request :=
                             To_Unbounded_String
                             (Select_Field (Header, 1) & " " &
                              Select_Field (Header, 2) & "?" & "set=" & Data &
                              " " & Select_Field (Header, 3));
                        end;
                     else
                        -- get request
                        Session.Request := To_Unbounded_String (Decode(Header));
                     end if;
                     return True;
                  end if;
                  return False;
               end Check_End;
            begin
               Pace.Display ("<<< " & Header &
                             Integer'Image (Session.Client_Handle));
               -- while Get_Line (Session.Fd)'Length > 0 loop
               loop
                  exit when Check_End (Get_Line (Session.Fd));
               end loop;

               --
               -- Act on CGI data via dispatch on primitive op
               --
               Get_Data (Session, Pace.Server.Parameters.Get_Bin (Header));
               Pace.Display (">>> Finished HTTP" & Integer'Image (Size));
            end;
         exception
            when E: Pace.Tcp.Communication_Error =>
               Pace.Log.Ex (E, "Communication error inside server task requesting => '" &
                            Pace.Strings.U2S(Session.Request)    & "' from '" &
                            Pace.Strings.U2S(Session.User_Agent) & "' via '" &
                            Pace.Strings.U2S(Session.Host)       & "'" );
               Shutdown (Session.Fd);
               Session.FD := -1;
               Session.Content_Placed := False;
               Session.Server_Push := False;
               Pace.Display ("Reset Web Server");
            when E: others =>
               Pace.Log.Ex (E, "Unknown error inside server task, exiting");
               exit;
         end;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E, "server reader");
   end Reader;

   procedure Put_Content (Session : access Session_Type;
                          Content : in String := "text/html";
                          Code : Response_Code := R200) is
   begin
      if Session.Fd < 0 then
         return;
      elsif Content = "" then
         -- If something else, i.e. a CGI script places content
         Session.Content_Placed := True;
      elsif Session.Server_Push then
         Put_Line (Session.Fd, "--" & Boundary_Tag);
         Put_Line (Session.Fd, "Content-type: " & Content);
         New_Line (Session.Fd);
      elsif not Session.Content_Placed then
         Put_Header (Session.Fd, Content, Session.Etag, Code);
         Session.Content_Placed := True;
      end if;
   end Put_Content;

   procedure Push_Content (Session : access Session_Type) is
   begin
      if Session.Fd < 0 then
         return;
      end if;
      Put_Header (Session.Fd,
                  "multipart/x-mixed-replace;boundary=" & Boundary_Tag);
      Session.Server_Push := True;
      Session.Content_Placed := True;
   end Push_Content;

   procedure Put_Data (Session : access Session_Type;
                       Text : in String;
                       More_Follows : in Boolean := True;
                       Raw : Boolean := False) is
   begin
      if Session.Fd < 0 then
         -- This determines whether a More_Follows=False has occurred
         -- which will have shut down the connection and reset file descriptor.
         -- Otherwise, spurious Connection_Error exceptions will occur.
         return;
      elsif not Session.Content_Placed then
         Put_Content (Session);
      end if;
      Put (Session.Fd,
           Text); -- Broke this up so that don't do an extra catenation
      if not Raw then
         New_Line (Session.Fd);  -- RAW removes an extra new-line
      end if;
      if not More_Follows then
         New_Line (Session.Fd);  -- But even RAW has a new-line
         if Session.Server_Push then
            Put_Line (Session.Fd, "--" & Boundary_Tag & "--");
         end if;
         Shutdown (Session.Fd);
         Session.FD := -1;
         Session.Content_Placed := False;
         Session.Server_Push := False;
      end if;
   exception
      when E: Pace.Tcp.Communication_Error =>
         if not (More_Follows or Raw) then -- Log last error only
            Pace.Error ("Putting data", Pace.X_Info (E) & " => '" &
                         Pace.Strings.U2S(Session.Request)    & "' from '" &
                         Pace.Strings.U2S(Session.User_Agent) & "' via '" &
                         Pace.Strings.U2S(Session.Host)       & "'");
         end if;
         Session.Content_Placed := False; -- new
         Session.Server_Push := False;    -- new
   end Put_Data;


   function Active_Session (Session : access Session_Type) return Boolean is
   begin
      return Session.Content_Placed;
   end Active_Session;

   procedure Close_Session (Session : access Session_Type) is
   begin
      Session.Content_Placed := False;
      Session.Server_Push := False;
      Session.FD := -1;
   end Close_Session;

   procedure Send_Data (Session : access Session_Type; Text : in String) is
   begin
      Put_Data (Session, Text, More_Follows => False);
   end Send_Data;

   -- Default session
   The_Default_Session : Session_Access;

   procedure Set_Default_Session (Session : in Session_Access) is
   begin
      The_Default_Session := Session;
      The_Default_Session.Fd := -1;
   end Set_Default_Session;

   function Default_Session return Session_Access is
      Sa : Session_Access := Task_Finder.Value;
   begin
      if Sa = null then
         --     Pace.Display  ("WARNING: using default session from non-server task");
         return The_Default_Session;
      else
         return Sa;
      end if;
   end Default_Session;

   function Active_Session return Boolean is
   begin
      return Active_Session (Default_Session);
   end Active_Session;

   procedure Close_Session is
   begin
      Close_Session (Default_Session);
   end Close_Session;

   procedure Put_Content (Content : in String := "text/html"; Code : Response_Code := R200) is
   begin
      Put_Content (Default_Session, Content, Code);
   end Put_Content;

   procedure Send_Not_Found is
   begin
      Put_Content (Session => Default_Session,
                   Content => "text/html",
                   Code => R404);
   end Send_Not_Found;

   procedure Push_Content is
   begin
      Push_Content (Default_Session);
   end Push_Content;

   procedure Put_Data (Text : in String; -- Data to put
                       More_Follows : in Boolean := True;
                       Raw : Boolean := False) is
   begin
      Put_Data (Default_Session, Text, More_Follows, Raw);
   end Put_Data;

   procedure Send_Data (Text : in String) is
   begin
      Send_Data (Default_Session, Text);
   end Send_Data;

   use Ada.Strings.Unbounded;

   function Get_Bin (Session : access Session_Type) return String is
   begin
      return Pace.Server.Parameters.Get_Bin (To_String (Session.Request));
   end Get_Bin;

   function Is_Index (Session : access Session_Type) return Boolean is
   begin
      return Pace.Server.Parameters.Is_Index (To_String (Session.Request));
   end Is_Index;

   function Value (Session : access Session_Type; Key : in String)
                   return String is
   begin
      return Pace.Server.Parameters.Value (To_String (Session.Request), Key);
   end Value;

   function Key_Exists
     (Session : access Session_Type; Key : in String) return Boolean is
   begin
      return Pace.Server.Parameters.Key_Exists
        (To_String (Session.Request), Key);
   end Key_Exists;

   function Value_Count
     (Session : access Session_Type; Key : in String) return Natural is
   begin
      return Pace.Server.Parameters.Value_Count
        (To_String (Session.Request), Key);
   end Value_Count;

   function Get_Client (Session : access Session_Type) return Integer is
   begin
      return Session.Client_Handle;
   end Get_Client;

   procedure Set_Port (Session : access Session_Type; Port : in Integer) is
   begin
      Session.Port := Port;
   end Set_Port;

   procedure Set_Etag (Session : access Session_Type; Etag : Long_Integer) is
   begin
      Session.Etag := S2b (Pace.Strings.Trim (Etag));
   end Set_Etag;

   function Get_Bin return String is
   begin
      return Get_Bin (Default_Session);
   end Get_Bin;

   function Is_Index return Boolean is
   begin
      return Is_Index (Default_Session);
   end Is_Index;

   function Value (Key : in String) return String is
   begin
      return Value (Default_Session, Key);
   end Value;

   function Key_Exists (Key : in String) return Boolean is
   begin
      return Key_Exists (Default_Session, Key);
   end Key_Exists;

   function Value_Count (Key : in String) return Natural is
   begin
      return Value_Count (Default_Session, Key);
   end Value_Count;

   function Get_Client return Integer is
   begin
      return Get_Client (Default_Session);
   end Get_Client;

   function Get_Method (Session : access Session_Type) return String is
   begin
      return Pace.Server.Parameters.Get_Method (To_String (Session.Request));
   end;

   function Get_Method return String is
   begin
      return Get_Method (Default_Session);
   end;

   package body Keys is

      function Value (Key : in String; Default : in String) return String is
      begin
         if Key_Exists (Key) then
            return Value (Key);
         else
            return Default;
         end if;
      exception
         when others =>
            Pace.Display ("Server String Key unknown: " & Key);
            return Default;
      end Value;

      function Value (Key : in String; Default : in Integer) return Integer is
      begin
         if Key_Exists (Key) then
            return Integer'Value (Value (Key));
         else
            return Default;
         end if;
      exception
         when others =>
            Pace.Display ("Server Integer Key malformed: " & Key);
            return Default;
      end Value;

      function Value (Key : in String; Default : in Float) return Float is
      begin
         if Key_Exists (Key) then
            return Float'Value (Value (Key));
         else
            return Default;
         end if;
      exception
         when others =>
            Pace.Display ("Server Float Key malformed: " & Key);
            return Default;
      end Value;

   end Keys;

   function Check_Extension
     (Name : in String; Extension : in String) return Boolean is
      Len : Integer := Extension'Length;
   begin
      if Extension (Extension'Last) = '/' then
         return Ada.Strings.Fixed.Index (Name, Extension) /= 0;
      else
         return Name'Length > Len and then
           Name (Name'Last - Len + 1 .. Name'Last) = Extension;
      end if;
   end Check_Extension;


   package body Atom is
      protected Data is
         procedure Set (Obj : in Item);
         function Get return Item;
      private
         My : Item;
      end Data;

      protected body Data is
         procedure Set (Obj : in Item) is
         begin
            My := Obj;
         end Set;
         function Get return Item is
         begin
            return My;
         end Get;
      end Data;

      procedure Set (Obj : in Item) is
      begin
         Data.Set (Obj);
      end Set;
      function Get return Item is
      begin
         return Data.Get;
      end Get;

   end Atom;

   Plus_To_Space : constant Ada.Strings.Maps.Character_Mapping := 
      Ada.Strings.Maps.To_Mapping ("+", " ");

   function Decode (S : String) return String is
      Result : String (S'Range);
      K      : Positive := S'First;
      J      : Positive := Result'First;
   begin
      while K <= S'Last loop
         if K + 2 <= S'Last
           and then  S (K) = '%'
           and then Ada.Characters.Handling.Is_Hexadecimal_Digit (S (K + 1))
           and then Ada.Characters.Handling.Is_Hexadecimal_Digit (S (K + 2))
         then
            --  Here we have '%HH' which is an encoded character where 'HH' is
            --  the character number in hexadecimal.
 
            Result (J) := Character'Val
              (Natural'Value ("16#" & S (K + 1 .. K + 2) & '#'));
            K := K + 3;
 
         else
            Result (J) := S (K);
            K := K + 1;
         end if;
 
         J := J + 1;
      end loop;
      Ada.Strings.Fixed.Translate (Result, Mapping => Plus_To_Space);

      return Result (Result'First .. J - 1);
   end Decode;

   ------------------------------------------------------------------------------
   -- $id: pace-server.adb,v 1.7 05/12/2003 22:17:01 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Server;
