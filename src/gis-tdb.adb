with Pace;
with Pace.Tcp.Http;
with Pace.Xml;
with Pace.Strings;
with Ada.Numerics.Elementary_Functions;
with Pace.Log;
with Hal.Terrain_Elevation.DTED;

package body Gis.TDB is
   use Ada.Numerics.Elementary_Functions;

   Server : constant String := Pace.Getenv ("TDB", "localhost");
   Port : constant Integer := Pace.Getenv ("TDB_Port", 5650);
   Variant : constant String := Pace.Getenv ("TDB_Variant", "TDB");
   
   function Is_Using_TDB return Boolean is
   begin
      return Server /= "";
   end Is_Using_TDB;
   
   
   function ToF (S : String) return Float is
   begin
      begin
         return Float'Value (S);
      exception
         when others =>
            return Float(Integer'Value(S));
      end;
   exception
      when others =>
         Pace.Log.Put_Line ("! Format error on numeric conversion: " & S);
         return 0.0;
   end ToF;          


-----------------OTF-----------------
--      Elev_Cmd : constant String :=
--         "get_height.terrain_query?xml=<coord+coord_sys=""utm_cs"">" &
--                                        "<e>406059</e>" &
--                                        "<n>3596300</n>" &
--                                        "<zone>13</zone>" &
--                                        "<hemisphere>n</hemisphere>" &
--                                       "</coord>";
--
--      Norm_Cmd : constant String :=
--         "get_normal.terrain_query?xml=<coord+coord_sys=""utm_cs"">" &
--                                        "<e>406059</e>" &
--                                        "<n>3596300</n>" &
--                                        "<zone>13</zone>" &
--                                        "<hemisphere>n</hemisphere>" &
--                                       "</coord>";
--      Pace.Log.Put_Line (Elev_Cmd);
--      declare
--         S : constant String :=  Pace.Tcp.Http.Get
--             (Host => Server,
--              Port => Port,
--              Item => Elev_Cmd,
--              Header_Discard => False);
--      begin
--         Elevation := ToF (Pace.Xml.Search_Xml(S, "height"));
--      end;
--
--      Pace.Log.Put_Line (Norm_Cmd);
--      declare
--         S : constant String :=  Pace.Tcp.Http.Binary_Get
--             (Host => Server,
--              Port => Port,
--              Item => Norm_Cmd,
--              Header_Discard => False);
--         S : constant String :=  Pace.Tcp.Http.Get
--             (Host => Server,
--              Port => Port,
--              Item => Norm_Cmd);
--         Triplet : constant String := Pace.Xml.Search_Xml(S, "normal");
--         N1, N2, N3 : Float;
--      begin
--         N1 := ToF(Pace.Strings.Select_Field(Triplet, 1));
--         N2 := ToF(Pace.Strings.Select_Field(Triplet, 2));
--         N3 := ToF(Pace.Strings.Select_Field(Triplet, 3));
--         Roll := arccos(-N1*sin(Heading) + N2*cos(Heading));
--         Pitch := arccos(N1*cos(Heading) + N2*sin(Heading));
--      end;
--      Viscosity := 0.0;
-----------------End OTF-----------------
   
   procedure Place_Vehicle
     (U                      : in UTM_Coordinate;
      Length, Width, Heading : in Float;
      Elevation              : out Float;
      Pitch, Roll            : out Float;
      Viscosity              : out Float) is

   begin
      if Is_Using_TDB then
         declare      
            use Pace.XML;

            Place_Cmd : constant String := 
               "GIS." & Variant & ".SERVER.PLACE?set=" & 
                         T("xml", 
                           T("easting", U.Easting) &
                           T("northing", U.Northing) &
                           T("zone", U.Zone_Num) &
                           T("hemisphere", Hemisphere_Type'Image(U.Hemisphere)) &
                           T("heading", Heading)
                         );
         begin
            Pace.Log.Put_Line ("GETTING ORIENTATION");
            Pace.Log.Put_Line (Place_Cmd);
            declare
               S : constant String :=  Pace.Tcp.Http.Get
                   (Host => Server,
                    Port => Port,
                    Item => Place_Cmd);
            begin
               Pace.Log.Put_Line ("RESULT:" & S);
               Elevation := ToF (Pace.Xml.Search_Xml(S, "elevation"));
               Pitch := ToF (Pace.Xml.Search_Xml(S, "pitch"));
               Roll := ToF (Pace.Xml.Search_Xml(S, "roll"));
               Viscosity := ToF (Pace.Xml.Search_Xml(S, "viscosity"));
            end;
            Pace.Log.Put_Line ("E" & Elevation'Img);
            Pace.Log.Put_Line ("P" & Pitch'Img);
            Pace.Log.Put_Line ("R" & Roll'Img);
            Pace.Log.Put_Line ("V" & Viscosity'Img);
         end;
      else
         Hal.Terrain_Elevation.DTED.Get_Terrain_Data
           (Easting => U.Easting,
            Northing => U.Northing,
            Zone_Number => U.Zone_Num,
            Zone_Letter => Hemisphere_Type'Image(U.Hemisphere)(1),
            Heading => Heading,
            Altitude => Elevation,
            Pitch => Pitch,
            Roll => Roll);
         Viscosity := 0.0;
      end if;
   exception
      when E : others =>
         Elevation := 0.0;
         Pitch := 0.0;
         Roll := 0.0;
         Viscosity := 0.0;
         Pace.Log.Ex (E);
   end;

   procedure UTM  -- Returns lower left of data 
     (Latitude, Longitude : in Long_Float;
      SW_UTM, UTM         : out UTM_Coordinate) is
      H : Character;
   begin   
      if Is_Using_TDB then
         declare
            use Pace.XML;

            UTM_Cmd : constant String := 
               "GIS." & Variant & ".SERVER.AT_UTM?set=" & T("xml", 
                                          T("latitude", Latitude) &
                                          T("longitude", Longitude));
         begin
            SW_UTM.Easting := 0.0;
            SW_UTM.Northing := 0.0;
            SW_UTM.Zone_Num := 0;
            SW_UTM.Hemisphere := Gis.North;
            UTM := SW_UTM;

            Pace.Log.Put_Line ("GETTING UTM");
            Pace.Log.Put_Line (UTM_Cmd);
            declare
               S : constant String :=  Pace.Tcp.Http.Get
                   (Host => Server,
                    Port => Port,
                    Item => UTM_Cmd);
            begin
               Pace.Log.Put_Line ("RESULT:" & S);
               SW_UTM.Easting := ToF (Pace.Xml.Search_Xml(S, "easting"));
               SW_UTM.Northing := ToF (Pace.Xml.Search_Xml(S, "northing"));
               SW_UTM.Zone_Num := Integer'Value (Pace.Xml.Search_Xml(S, "zone"));
               SW_UTM.Hemisphere := Hemisphere_Type'Value (Pace.Xml.Search_Xml(S, "hemisphere"));
               UTM.Easting := ToF (Pace.Xml.Search_Xml(S, "e"));
               UTM.Northing := ToF (Pace.Xml.Search_Xml(S, "n"));
               UTM.Zone_Num := Integer'Value (Pace.Xml.Search_Xml(S, "z"));
               UTM.Hemisphere := Hemisphere_Type'Value (Pace.Xml.Search_Xml(S, "h"));
            end;
         end;
      else
         Hal.Terrain_Elevation.DTED.UTM (Latitude => Latitude, 
                                         Longitude => Longitude,
                                         SW_East => SW_UTM.Easting,
                                         SW_North => SW_UTM.Northing,
                                         Easting => UTM.Easting,
                                         Northing => UTM.Northing,
                                         Zone_Number => SW_UTM.Zone_Num,
                                         Hemisphere => H);
         if Hemi_Code(North) = H then
            SW_UTM.Hemisphere := North;
         else
            SW_UTM.Hemisphere := South;
         end if;
      end if;
   
   exception
      when E : others =>
         Pace.Log.Ex (E);
   end;


end Gis.TDB;
 
