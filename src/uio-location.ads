with Pace.Server.Dispatch;
with Gis.Location;

generic
   with package Location_Model is new Gis.Location (<>);
package Uio.Location is

   pragma Elaborate_Body;

   -- action request that places the vehicle at a given easting and northing and
   -- heading.  Data is in xml.
   -- Heading is in degrees by default, or radians if the cgi parameter
   -- israd=true.
   type Place_Vehicle_Utm is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Place_Vehicle_Utm);

   -- action request that places the vehicle at a given latitude and longitude and
   -- and a specific heading according to the given quaternion.  Data is in xml.
   type Place_Vehicle_LatLongQuat is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Place_Vehicle_LatLongQuat);

   -- inputs come in as xml inside the set cgi-parameter
   -- inputs : easting, northing, zone, hemisphere, roll, pitch, and yaw
   -- outputs : lat, long, height, quaternion
   -- everything is in radians
   type UtmRpy_To_LatLongQuat is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Utmrpy_To_Latlongquat);

end Uio.Location;
