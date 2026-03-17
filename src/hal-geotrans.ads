
with Pace.Semaphore;
package Hal.GeoTrans is
   pragma Elaborate_Body;
   -- UTM is meters
   -- Lat/Long in radians
   -- Height values are ignored or return 0.0

   Geotrans_Error : exception;
   M : aliased Pace.Semaphore.Mutex;

   procedure UTM_To_Geo (
         Easting, Northing : in Long_Float;
         Zone : in Integer;
         hemisphere : in Character := 'N';
         Longitude, Latitude, Height : out Long_Float);

   procedure Geo_To_UTM (
         Longitude, Latitude, Height : in Long_Float;
         Easting, Northing : out Long_Float;
         Zone : out Integer;
         hemisphere : out Character);

   -- $Id: hal-geotrans.ads,v 1.1 2004/09/01 14:14:49 pukitepa Exp $
end;
