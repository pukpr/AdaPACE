with Pace.Strings;
with Gis.Location;
with Gis.Unit_Tracker;

generic
   with function Get_Location return Gis.Utm_Coordinate;
   Side : Gis.Unit_Tracker.Side_Enum;
   Unit_Id : Pace.Strings.Bstr.Bounded_String;
   Broadcast_Interval : Duration := 3.0;
package Gis.Unit_Multicaster is

   pragma Elaborate_Body;

end Gis.Unit_Multicaster;
