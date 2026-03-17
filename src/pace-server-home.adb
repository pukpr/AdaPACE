with Ada.Strings.Unbounded;
with Pace.Server.Html;
with Pace.Server.Name;
with Pace.Server.Xml;
with Pace.Server.Dispatch;
with Pace.Server.Cgi;
with Pace.Xml;
with Pace.Client;
with Pace.Strings;

package body Pace.Server.Home is

   use Pace.Strings;

   Parser_Session : Pace.Server.Session_Access;
   Parser_Task    : Pace.Server.Reader_Access;

   use Ada.Strings.Unbounded;

   Home_Page : Unbounded_String := To_Unbounded_String ("index.html");

   procedure Create
     (Number_Of_Readers       : in Integer;
      Storage_Size_Per_Reader : in Integer)
   is
   begin
      for I in  1 .. Number_Of_Readers loop
         Parser_Session := new Basic;
         Parser_Task    :=
           new Pace.Server.Reader
           (Parser_Session,
            Storage_Size_Per_Reader - I);
      end loop;
      Pace.Server.Set_Default_Session (new Basic);
   end Create;

   procedure Set_Home_Page (Home : in String) is
   begin
      Home_Page := To_Unbounded_String (Home);
   end Set_Home_Page;

   function Substitute is new Pace.Server.Html.Template (
      "<?set ",
      "?>",
      Pace.Server.Dispatch.Dispatch_To_Action);

   Url : constant String := "url";
   Subscribe : constant String := "subscribe";

   procedure Page (Exec : in String) is

      function Check_Extension (Extension : in String) return Boolean is
      begin
         return Pace.Server.Check_Extension (Exec, Extension);
      end Check_Extension;

      use Pace.Server.Xml;
   begin
      if Check_Extension (".cgi") or Check_Extension (".cgi/") then
         --
         -- Exec CGI Program
         --
         Pace.Server.Put_Content (Content => ""); -- Let CGI do it
         declare
            Cgi_Exec : constant String := Pace.Server.Cgi (Exec);
         begin
            if Cgi_Exec /= "" then
               -- Gets redirected to a new CGI exec
               Page (Cgi_Exec);
            end if;
         end;
      elsif Check_Extension (".gif") then
         --
         -- Load GIF
         --
         Pace.Display ("loading GIF " & Pace.Server.Value (""));
         Pace.Server.Put_Content (Content => "image/gif");
         Pace.Server.Send_Data (Pace.Server.Html.Read_File (Exec));
      elsif Check_Extension (".png") then
         --
         -- Load PNG
         --
         Pace.Display ("loading PNG " & Pace.Server.Value (""));
         Pace.Server.Put_Content (Content => "image/png");
         Pace.Server.Send_Data (Pace.Server.Html.Read_File (Exec));
      elsif Check_Extension (".jpeg") or Check_Extension (".jpg") then
         --
         -- Load JPEG
         --
         Pace.Display ("loading JPEG");
         Pace.Server.Put_Content (Content => "image/jpeg");
         Pace.Server.Send_Data (Pace.Server.Html.Read_File (Exec));
      elsif Check_Extension (".xbm") then
         --
         -- Load XBM
         --
         Pace.Display ("loading XBM");
         Pace.Server.Put_Content (Content => "image/x-xbitmap");
         Pace.Server.Send_Data (Pace.Server.Html.Read_File (Exec));
      elsif Check_Extension (".ico") then
         --
         -- Load ICO
         --
         Pace.Display ("loading ICO");
         Pace.Server.Put_Content (Content => "image/x-icon");
         Pace.Server.Send_Data (Pace.Server.Html.Read_File (Exec));
      elsif Check_Extension (".class") or Check_Extension (".jar") then
         --
         -- Load Java
         --
         Pace.Display ("loading Java class");
         Pace.Server.Send_Data (Pace.Server.Html.Read_File (Exec));
      elsif Check_Extension (".wrl") or Check_Extension (".vrml") then
         --
         -- Load Java
         --
         Pace.Display ("loading VRML file");
         Pace.Server.Put_Content (Content => "x-world/x-vrml");
         Pace.Server.Send_Data
           (Substitute (Pace.Server.Html.Read_File (Exec)));
      elsif Check_Extension (".css") then
         --
         -- Load Cascading Style Sheet
         --
         Pace.Display ("loading CSS file");
         Pace.Server.Put_Content (Content => "text/css");
         Pace.Server.Send_Data
           (Substitute (Pace.Server.Html.Read_File (Exec)));
      elsif Check_Extension (".rgb") then
         --
         -- Load SGI RGB
         --
         Pace.Display ("loading RGB");
         Pace.Server.Put_Content (Content => "image/rgb");
         Pace.Server.Send_Data (Pace.Server.Html.Read_File (Exec));
      elsif Check_Extension (".js") then
         --
         -- Load JavaScript
         --
         Pace.Server.Put_Content (Content => "text/javascript");
         Pace.Server.Send_Data
           (Substitute (Pace.Server.Html.Read_File (Exec)));
      elsif Check_Extension (".swf") then
         --
         -- Load FLASH
         --
         Pace.Display ("loading SWF");
         Pace.Server.Put_Content (Content => "application/x-shockwave-flash");
         Pace.Server.Send_Data (Pace.Server.Html.Read_File (Exec));
      elsif Check_Extension (".xml") then
         --
         -- Load XML Page
         --
         Pace.Server.Xml.Put_Content (Default_Stylesheet => "");
         Pace.Server.Send_Data
           (Substitute (Pace.Server.Html.Read_File (Exec)));
      elsif Check_Extension (".xsl") then
         --
         -- Load Extensible Style Sheet
         --
         Pace.Server.Put_Content (Content => "text/xml");
         Pace.Server.Send_Data
           (Substitute (Pace.Server.Html.Read_File (Exec)));
      elsif Check_Extension (".html") or Check_Extension (".htm") then
         --
         -- Load Page
         --
         Pace.Server.Send_Data
           (Substitute (Pace.Server.Html.Read_File (Exec)));
      elsif Pace.Server.Key_Exists (Subscribe) then
         Pace.Server.Xml.Put_Content;
         if Pace.Client.Has_Action (Exec) then
            declare
               use Pace.Xml;
               Subscribe_Xml : String := Pace.Server.Keys.Value (Subscribe, "");
               Host : String := Search_Xml (Subscribe_Xml, "host");
               Port : String := Search_Xml (Subscribe_Xml, "port");
            begin
               Pace.Client.Subscribe_To_Action (Exec, Host, Port);
               Pace.Server.Send_Data (Pace.Server.Xml.Item ("subscribe_success", "TRUE"));
            exception
               when E : Pace.Server.Communication_Error =>
                  Pace.Error (Pace.X_Info (E));
                  Pace.Server.Send_Data (Pace.Server.Xml.Item ("subscribe_success", "FALSE"));
            end;
            -- trigger initial push!!??!!??
         else
            Pace.Server.Send_Data (Pace.Server.Xml.Item ("subscribe_success", "FALSE"));
         end if;
      elsif Pace.Server.Dispatch.Dispatch_To_Action (Exec) then
         --
         -- Anything get registered in the server tag dispatching table?
         --
         Pace.Display ("Dispatched to " & Exec);

         if Pace.Server.Key_Exists (Url)
           and then Pace.Server.Value (Url) /= ""
         then
            -- Route to a different page if URL CGI parameter set
            Page (Pace.Server.Html.Get_Path (Exec, Pace.Server.Value (Url)));
         else
            Pace.Server.Send_Data ("");
         end if;
      elsif Exec = "" or Exec = "/" then
         --
         -- Load Home Page
         --
         Pace.Server.Send_Data
           (Pace.Server.Html.Read_File (To_String (Home_Page)));
      else
         -- 404 Not Found Response
         Pace.Server.Put_Content ("text/html", R404);
         Pace.Server.Send_Data (Pace.Server.Xml.Item ("html",
                               Pace.Server.Xml.Item ("body", "HTTP 404 Response: Request Not Found")));
      end if;

   exception
      when E : Pace.Server.Communication_Error =>
         Pace.Error (Pace.X_Info (E));
      when E : others =>
         Pace.Error (Pace.X_Info (E));
         Pace.Server.Send_Data
           ("Exception raised on web request " &
            Exec &
            " : " &
            Pace.X_Info (E));
   end Page;

   procedure Get_Data (Obj : access Basic; Text : in String) is
   begin
      -- test
      --Send_Data ( Obj,Pace.Server.Html.Read_File ("index.html"));
      Page (Text);
   end Get_Data;

   type Include is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Include);
   for Include'External_Tag use "INCLUDE";

   use Pace.Server.Dispatch;

   procedure Inout (Obj : in out Include) is
   begin
      Obj.Set :=
        S2u (Substitute (Html.Read_File (Html.Get_Path (Get_Bin, U2s (Obj.Set)))));
   end Inout;

begin

   Save_Action (Include'(Pace.Msg with Set => S2u ("(template replace)")));

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-server-home.adb,v 1.12 02/28/2003 21:11:10 ludwiglj Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Server.Home;
