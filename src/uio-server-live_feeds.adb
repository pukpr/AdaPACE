with Pace.Tcp.Http;
with Pace;
with Pace.Log;
with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Pace.Server.Html;

package body Uio.Server.Live_Feeds is

   -- This section grabs real-time NOAA data from Ft.Irwin, National
   -- Training Center.  We are going outside the building to grab this
   -- via an HTTP proxy -- Commercial Systems Provider proxy (NM01251)
   --
   -- Weather conditions at Ft.Irwin (i.e. Daggett, Barstow-Daggett Airport)
   
   Proxy_URL : constant String := Pace.Getenv("PROXY_URL", "10.1.55.251:3128");
   Station : constant String := Pace.Getenv("WEATHER_STATION", "KDAG.xml");

   type Get_Weather is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Weather);

   procedure Read (Val : in String) is
   begin
      -- Line-by-line read of XML
      Pace.Log.Put_Line(Val, 9);
   end Read;

   function Url return String is
   begin
      return "http://www.weather.gov"; -- National Weather Service
   end Url;

   function Meta (Subtext : in String) return String is
   begin
      return "";  -- Just remove the meta tag at the top
   end Meta;

   function Expander is new Pace.Server.Html.Template ("<?", "?>", Meta);

   -- This can use server push to keep sending data to the browser until
   -- connection is stopped

   procedure Weather_Conditions is
      Default_Stylesheet : String := "/eng/show_all.xsl";
   begin
-- FIX: if XML, push_content does not seem to work
--  Pace.Server.Push_Content;
--  loop
      -- Pace.Server.Put_Content (Content => "text/html");
      Pace.Server.Xml.Put_Content (Default_Stylesheet => Default_Stylesheet);
      Pace.Server.Put_Data ( Expander(
         Pace.Tcp.Http.Get (Proxy_Url, 
                           "/data/current_obs/" & Station,
                           Read'Access, Url'Access)));
--    Pace.Log.Wait (5.0);
--  end loop;
   end Weather_Conditions;

   use Pace.Server.Dispatch;

   procedure Inout (Obj : in out Get_Weather) is
   begin
      Weather_Conditions;
   end Inout;

-------


   type Dummy is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Dummy);
   procedure Inout (Obj : in out Dummy) is
   begin
      null;
   end Inout;

begin

   Save_Action (Get_Weather'(Pace.Msg with Set => Default));
   Save_Action (Dummy'(Pace.Msg with Set => Default));

-- $Id: uio-server-live_feeds.adb,v 1.4 2006/04/14 23:14:16 pukitepa Exp $
end Uio.Server.Live_Feeds;

