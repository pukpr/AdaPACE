with Pace.Server.Dispatch;
with Pace.Strings;
with Pace.Server.Xml;
with Pace.Xml;
with Dom.Core;
with Dom.Core.Nodes;
with Pace.Log;

package body Gis.CTDB.Server is

   use Pace.Strings;
   use Pace.Server.Xml;
   use Pace.Xml;
   
   type Place is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Place);

   type At_Utm is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out At_Utm);

   use Pace.Server.Dispatch;

   procedure Inout (Obj : in out Place) is
      Doc : Doc_Type := Parse (U2s(Obj.Set));
      N, E, Head : Float;
      Z : Integer;
      El, P, R, V : Float;
      Hemisphere : Gis.Hemisphere_Type;
   begin
      N := Float'Value (Search_Xml (Doc, "northing", "0.0"));
      E := Float'Value (Search_Xml (Doc, "easting", "0.0"));
      Z := Integer'Value (Search_Xml (Doc, "zone", "0"));
      Head := Float'Value (Search_Xml (Doc, "heading", "0"));
      Hemisphere := Hemisphere_Type'Value (Search_Xml (Doc, "hemisphere", "NORTH"));
      
      Place_Vehicle 
      (U => (N, E, Z, Hemisphere),  -- CTDB doesn't actually use Hemisphere but pass it along
       X => 0.0, Y => 0.0,
       Length => 1.0,
       Width => 1.0,
       Heading => Head,
       Elevation => El,
       Pitch => P, 
       Roll => R,
       Viscosity => V);
      
      Obj.Set := S2u(Item("pose", Item("elevation", El)
       & Item("pitch", P)
       & Item("roll", R)
       & Item("viscosity", V)));
      Pace.Server.Put_Data (U2S(Obj.Set));
      -- Dom.Core.Nodes.Free (Doc);
   end Inout;

   procedure Inout (Obj : in out At_Utm) is
      Doc : Doc_Type := Parse (U2s(Obj.Set));
      Lat, Lon : Long_Float;
      U_Ex, U : UTM_Coordinate;
      
   begin
      Lat := Long_Float'Value (Search_Xml (Doc, "latitude", "0.0"));
      Lon := Long_Float'Value (Search_Xml (Doc, "longitude", "0.0"));
      
      Pace.Log.Put_Line ("LAT=" & Lat'Img);
      Pace.Log.Put_Line ("LON=" & Lon'Img);
      Utm 
      (Latitude => Lat,
       Longitude => Lon,
       SW_UTM => U_Ex,
       UTM => U);
      
      Obj.Set := S2u(Item("map", 
         Item("sw",
           Item("easting", U_Ex.Easting)
         & Item("northing", U_Ex.Northing)
         & Item("zone", U_Ex.Zone_Num)
         & Item("hemisphere", Hemisphere_Type'Image(U_Ex.Hemisphere))) &
         Item("location",   
           Item("e", U.Easting)
         & Item("n", U.Northing)
         & Item("z", U.Zone_Num)
         & Item("h", Hemisphere_Type'Image(U.Hemisphere))) 
         ));
      Pace.Server.Put_Data (U2S(Obj.Set));
   end Inout;

begin
   Save_Action (Place'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (At_Utm'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
end Gis.CTDB.Server;
