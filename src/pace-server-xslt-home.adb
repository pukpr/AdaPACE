with Pace.Ports;
with Pace.Tcp.Http;
with Interfaces.C.Strings;
with Pace.Command_Line;
with Pace.Config;

package body Pace.Server.Xslt.Home is

   -- if set to true then default is to translate on server side unless
   -- client is specified by translate cgi parameter
   Default_Server_Translate : Boolean := False;

   Node : constant Integer := Pace.Get;
   Forward_Port : constant Integer :=
     Pace.Ports.Unique_Port (Service => Pace.Ports.Web, Node => Node) - 100;

   type Proxy is new Pace.Server.Session_Type with null record;
   procedure Get_Data (Obj : access Proxy; Text : in String);

   Parser_Session : Pace.Server.Session_Access;
   Parser_Task : Pace.Server.Reader_Access;

   procedure Create (Number_Of_Readers : in Integer;
                     Storage_Size_Per_Reader : in Integer) is
   begin
      for I in 1 .. Number_Of_Readers loop
         Parser_Session := new Proxy;
         Parser_Task := new Pace.Server.Reader
                              (Parser_Session, Storage_Size_Per_Reader - I);
      end loop;
      Pace.Server.Set_Default_Session (new Proxy);
   end Create;


   function Parse (Bin, Cgi : in String) return String is
   begin
      if Cgi = "" then
         return Bin;
      else
         return Bin & "?" & Cgi;
      end if;
   end Parse;

   -- runs Xml_Buffer (which should be pure xml) through Gnu's xslt
   -- translator (libxslt) and returns the result
   function Translate_Xml (Xml_Buffer : in String) return String is
      use Interfaces.C.Strings;
      Xml_Input_Doc : Doc;
      Xml_Output_Doc : Doc;
      Style_Doc : Style;
      Xml_Str : aliased Chars_Ptr;
      Len : aliased Integer;
      Style_Sheet_Path : String := Pace.Config.Find_File ("/html/" & Pace.Server.Keys.Value ("style", "") & Ascii.Nul);
   begin
      pragma Debug (Pace.Display("attempting to parse: " & Xml_Buffer));
      pragma Debug (Pace.Display ("-----------------"));
      Xml_Input_Doc := Xmlparsememory (Xml_Buffer, Xml_Buffer'Length);
      pragma Debug (Pace.Display
                      ("style sheet path is :" & Style_Sheet_Path));
      Style_Doc := Xsltparsestylesheetfile (Style_Sheet_Path);
      Xml_Output_Doc := Xsltapplystylesheet (Style_Doc, Xml_Input_Doc);
      Xsltsaveresulttostring (Xml_Str'Access, Len'Access,
                              Xml_Output_Doc, Style_Doc);
      declare
         Result : constant String := Value (Xml_Str);
      begin
         Xsltfreestylesheet (Style_Doc);
         Xmlfreedoc (Xml_Input_Doc);
         Xmlfreedoc (Xml_Output_Doc);
         return Result;
      end;
   end Translate_Xml;

   -- determines whether translation should be done on server or client side

   function Do_Server_Translate return Boolean is
   begin
      if Default_Server_Translate then
         -- default to server side unless translate=client
         if Pace.Server.Key_Exists ("translate") and then
            Pace.Server.Value ("translate") /= "client" then
            return True;
         else
            return False;
         end if;
      elsif Pace.Server.Key_Exists ("translate") and then
            Pace.Server.Value ("translate") = "server" then
         return True;
      else
         return False;
      end if;
   end Do_Server_Translate;

   procedure Get_Data (Obj : access Proxy; Text : in String) is
      Query : constant String := Parse (Text, Pace.Server.Value (""));
   begin
      if Do_Server_Translate then
         pragma Debug (Pace.Display ("before binary_Get"));
         declare
            -- getting response without the header
            D : constant String :=
              Pace.Tcp.Http.Binary_Get (Host => "localhost",
                                        Port => Forward_Port,
                                        Item => Query,
                                        Header_Discard => True);
         begin
            pragma Debug (Pace.Display ("made it past binary_Get"));
            -- send the header
            Pace.Server.Put_Content ("text/html");
            -- send the translation of the xml
            Pace.Server.Send_Data (Translate_Xml (D));
         end;
      else
         declare
            -- getting the response with the header
            D : constant String :=
              Pace.Tcp.Http.Binary_Get
                (Host => "localhost", Port => Forward_Port, Item => Query);
            Session : Session_Access := Default_Session;
         begin
            -- setting this to true so send_data doesn't add in a header
            Session.Content_Placed := True;
            -- sending data (which already has the header with it)
            Pace.Server.Send_Data (D);
         end;
      end if;
   exception
      when E: Pace.Server.Communication_Error =>
         Pace.Error (Pace.X_Info (E));
      when E: others =>
         Pace.Error (Pace.X_Info (E));
         Pace.Server.Send_Data ("Exception raised on web request " &
                                Text & " : " & Pace.X_Info (E));
   end Get_Data;


begin
   if Pace.Command_Line.Argument ("-translate") = "server" then
      Pace.Display ("found -translate and it equals server!");
      Default_Server_Translate := True;
   end if;
   Pace.Display ("translate argument is :" &
                      Pace.Command_Line.Argument ("-translate"));
------------------------------------------------------------------------------
-- $id: pace-server-xslt-home.adb,v 1.5 03/18/2003 14:39:51 ludwiglj Exp $
------------------------------------------------------------------------------
end Pace.Server.Xslt.Home;


