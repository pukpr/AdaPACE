with Wmi;
with Wkb;
with Pace.Log;
with Pace.Tcp.Http;
with Pace.Xml_Tree;
with Pace.Server.Kbase_Utilities;
with Pace.Strings; use Pace.Strings;

--  Weather Reporting Agent
--
--  Demonstrates the PACE XML-to-KBASE pipeline by fetching the NWS current-
--  observation XML for station KDAG (Death Valley, CA), converting it to
--  Prolog functors and querying the results through the GKB knowledge base.
--
--  Architecture
--  ────────────
--  1. Wmi.Create   – starts the PACE/WMI server; elaborates the Wkb package
--                    (GKB instantiation) which starts the Prolog agent and
--                    loads $PACE/kbase/weather.pro.
--
--  2. HTTP fetch   – Pace.Tcp.Http.Get retrieves the raw XML from the NWS
--                    current-observation endpoint on port 80.
--                    The request includes Host: and User-Agent: headers
--                    to satisfy anti-bot checks on the server side.
--                    Note: the NWS may redirect HTTP requests to HTTPS; if
--                    an empty response is received, check connectivity or
--                    supply XML from a local mirror / cached file.
--
--  3. XML-to-KBASE – Pace.Server.Kbase_Utilities.Xml_To_Kbase converts the
--                    full XML document into a nested Prolog functor:
--                      weather_obs(current_observations(...))
--                    and asserts it into the WKB agent via Agent.Parse.
--                    This is the same operation performed by the dispatch
--                    action wkb.assert_xml when called over HTTP:
--                      Wmi.Call("wkb.assert_xml",
--                               Wmi.P("set",Xml) + Wmi.P("functor","weather_obs"))
--
--  4. Flat facts   – Individual leaf values are extracted with
--                    Pace.Xml_Tree.Search_Xml and asserted as simple
--                    single-argument facts (station_id/1, obs_condition/1,
--                    obs_temp_f/1 …) for reliable rule-based querying.
--
--  5. Prolog query – Wkb.Agent.Query executes the weather_report/5 rule
--                    from weather.pro and returns the bound variables.
--
--  Build:  gprbuild -P weather.gpr
--  Run:    env PACE=../.. PACE_SIM=1 PACE_NODE=0 obj/weather_main
procedure Weather_Main is

   use Wkb.Rules;

   --  NWS current-observation HTTP endpoint (plain HTTP, port 80)
   NWS_Host : constant String  := "forecast.weather.gov";
   NWS_Port : constant Integer := 80;
   --  Path without leading slash: Pace.Tcp.Http.Get prepends "/" via Init.
   --  Pace.Tcp.Http.Get sends Host: and User-Agent: headers automatically.
   NWS_Item : constant String  := "xml/current_obs/KDAG.xml";

   --  Extract one XML field and assert it as a quoted Prolog atom.
   --  The value is single-quoted so that atoms beginning with an uppercase
   --  letter or containing spaces remain valid Prolog syntax.
   procedure Assert_Fact (Functor, Xml_Key, Xml : String) is
      Value : constant String :=
        Pace.Xml_Tree.Search_Xml (Xml, Xml_Key, "");
   begin
      if Value /= "" then
         Wkb.Agent.Assert (Functor & "('" & Value & "')");
      end if;
   end Assert_Fact;

begin
   --  ── Step 1: Start the PACE / WMI server ──────────────────────────────
   --  Wmi.Create initialises the HTTP server and, via package elaboration,
   --  starts the Wkb (GKB) Prolog agent and loads weather.pro.
   Wmi.Create (10, 500_000);
   Pace.Log.Agent_Id;

   --  ── Step 2: Fetch NWS observation XML ────────────────────────────────
   Pace.Log.Put_Line ("Weather Agent: fetching current observation for KDAG...");

   declare
      Xml : constant String :=
        Pace.Tcp.Http.Get (Host => NWS_Host,
                           Port => NWS_Port,
                           Item => NWS_Item);
   begin
      if Xml = "" then
         Pace.Log.Put_Line
           ("ERROR: empty response from " & NWS_Host & " – "
            & "the server may require HTTPS or the station may be offline");
         return;
      end if;

      Pace.Log.Put_Line ("Received " & Trim (Xml'Length)
                         & " bytes of observation XML");

      --  ── Step 3: PACE XML-to-KBASE (nested Prolog functor) ────────────
      --
      --  Pace.Server.Kbase_Utilities.Xml_To_Kbase:
      --    • strips <?...?> processing instructions with Html.Template
      --    • parses the XML tree into a Pace.Xml_Tree.Kbase.Kb_Fact
      --    • traverses the tree to produce a hierarchical Prolog term
      --    • asserts: weather_obs(current_observations(...)) into the KB
      --
      --  The root <current_observations> element may carry XML-namespace
      --  attributes; these are included in the Prolog term verbatim.
      --  If the asserta/1 call fails due to syntax, execution continues.
      begin
         Pace.Server.Kbase_Utilities.Xml_To_Kbase
           (Wkb.Agent, S2u (Xml), "weather_obs");
         Pace.Log.Put_Line
           ("Asserted weather_obs/1 nested functor into Prolog KB");
      exception
         when others =>
            Pace.Log.Put_Line
              ("Note: nested XML-to-KBASE assertion skipped "
               & "(complex root attributes in XML document)");
      end;

      --  ── Step 4: Flat Prolog facts for rule-based querying ─────────────
      --
      --  Pace.Xml_Tree.Search_Xml extracts individual element text values
      --  from the raw XML string.  Each value is asserted as a simple
      --  single-argument fact that the weather_report/5 rule in
      --  weather.pro can match directly.
      Assert_Fact ("station_id",      "station_id",        Xml);
      Assert_Fact ("obs_location",    "location",          Xml);
      Assert_Fact ("obs_condition",   "weather",           Xml);
      Assert_Fact ("obs_temp_f",      "temp_f",            Xml);
      Assert_Fact ("obs_temp_c",      "temp_c",            Xml);
      Assert_Fact ("obs_humidity",    "relative_humidity", Xml);
      Assert_Fact ("obs_wind",        "wind_string",       Xml);
      Assert_Fact ("obs_pressure_mb", "pressure_mb",       Xml);
      Assert_Fact ("obs_visibility",  "visibility_mi",     Xml);
      Assert_Fact ("obs_dewpoint_f",  "dewpoint_f",        Xml);
      Assert_Fact ("obs_obs_time",    "observation_time",  Xml);

      Pace.Log.Put_Line ("Asserted individual weather observation facts");

      --  ── Step 5: Query the knowledge base via Prolog rules ─────────────
      --
      --  Execute the weather_report/5 rule defined in weather.pro.
      --  The rule joins the five individual facts asserted in step 4 and
      --  returns their values in Variables (1 .. 5).
      declare
         V : Variables (1 .. 5);
      begin
         Wkb.Agent.Query ("weather_report", V);
         Pace.Log.Put_Line ("");
         Pace.Log.Put_Line
           ("=== Current Observation: " & U2s (V (1)) & " ===");
         Pace.Log.Put_Line ("Condition:   " & U2s (V (2)));
         Pace.Log.Put_Line ("Temperature: " & U2s (V (3)) & " F");
         Pace.Log.Put_Line ("Humidity:    " & U2s (V (4)) & " %");
         Pace.Log.Put_Line ("Wind:        " & U2s (V (5)));
      exception
         when No_Match =>
            Pace.Log.Put_Line
              ("ERROR: weather_report/5 returned No_Match – "
               & "check that all five observation fields were present in the XML");
      end;

   end;

exception
   when E : others =>
      Pace.Log.Ex (E);
end Weather_Main;
