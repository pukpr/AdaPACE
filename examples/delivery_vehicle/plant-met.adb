with Pace;
with Pace.Log;
with Pace.Server;

package body Plant.Met is

   Cloud_Cover : Float := 0.0;
   Temperature : Float := 20.0;
   Visibility : Float := 100.0;
   Wind_Speed : Float := 0.0;
   Wind_Direction : Float := 0.0;
   Terrain_Conditions : Integer := 0;
   Current_Conditions : Integer := 0;

   procedure Set_Cloud_Cover (Value : in Float) is
   begin
      Cloud_Cover := Value;
   end Set_Cloud_Cover;

   function Get_Cloud_Cover return Float is
   begin
      return Cloud_Cover;
   end Get_Cloud_Cover;

   procedure Set_Temperature (Value : in Float) is
   begin
      Temperature := Value;
   end Set_Temperature;

   function Get_Temperature return Float is
   begin
      return Temperature;
   end Get_Temperature;

   procedure Set_Visibility (Value : in Float) is
   begin
      Visibility := Value;
   end Set_Visibility;

   function Get_Visibility return Float is
   begin
      return Visibility;
   end Get_Visibility;

   procedure Set_Wind_Speed (Value : in Float) is
   begin
      Wind_Speed := Value;
   end Set_Wind_Speed;

   function Get_Wind_Speed return Float is
   begin
      return Wind_Speed;
   end Get_Wind_Speed;

   procedure Set_Wind_Direction (Value : in Float) is
   begin
      Wind_Direction := Value;
   end Set_Wind_Direction;

   function Get_Wind_Direction return Float is
   begin
      return Wind_Direction;
   end Get_Wind_Direction;

   procedure Set_Terrain_Conditions (Value : in Integer) is
   begin
      Terrain_Conditions := Value;
   end Set_Terrain_Conditions;

   function Get_Terrain_Conditions return Integer is
   begin
      return Terrain_Conditions;
   end Get_Terrain_Conditions;

   procedure Set_Current_Conditions (Value : in Integer) is
   begin
      Current_Conditions := Value;
   end Set_Current_Conditions;

   function Get_Current_Conditions return Integer is
   begin
      return Current_Conditions;
   end Get_Current_Conditions;


   --    --
--     -- This section grabs real-time NOAA data from Ft.Irwin, National
--  -- Training Center.  We are going outside the building to grab this
--  -- via an HTTP proxy
--     --
--     -- Weather conditions at Ft.Irwin (i.e. Daggett, Barstow-Daggett Airport)

--     function Separator (Subtext : in String) return String is
--     begin
--     return " - ";
--     end Separator;

--     function Expander is new Model.Template ("<", ">", Separator);

--     Line : Integer;

--     Push_Error : exception;

--     procedure Read (Val : in String) is
--     begin
--     Line := Line + 1;
--     if Line = 15 then -- latest info on Line #15 (This could change)
--        Pace.Server.Put_Content (Content => "text/plain");
--        Pace.Server.Put_Data (Expander (Val));
--     end if;
--     exception
--     when E: Gnu.Tcp.Communication_Error =>
--        raise Push_Error;
--     end Read;

--     function Url return String is
--     begin
--     return "http://www.wrh.noaa.gov"; -- National Oceanic and Atmospheric Center
--     end Url;

--     -- This uses Netscape server push to keep sending data to the browser until
--     -- connection is stopped

--     procedure Weather_Conditions is
--     begin
--     Pace.Server.Push_Content;
--     loop
--     Line := 0;
--     Model.Socket.Http.Get
--       ("10.1.55.251:3128", -- UDLP Proxy (NM01251)
--        "/cgi-bin/wrhq/GetMetar.cgi?DAG+Public+Lasvegas",
--        Read'Access, Url'Access);
--     Pace.Server.Put_Data
--       (Duration'Image (Pace.Now) &
--        " : date,time,wind(dir,speed,max),vis,weather,temp,dew,humid,bp");
--     Pace.Log.Wait (10.0);
--     end loop;
--     exception
--     when Push_Error =>
--        Pace.Display ("Weather monitoring complete");
--     end Weather_Conditions;


end Plant.Met;

