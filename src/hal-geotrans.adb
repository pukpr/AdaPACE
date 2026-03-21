with Pace.Log;
with Pace.Config;
with Interfaces.C.Strings;
with Ada.Environment_Variables;
with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics;

package body Hal.GeoTrans is

   function ID is new Pace.Log.Unit_ID;

   -- WGS84 Ellipsoid constants
   A_WGS84 : constant Long_Float := 6378137.0;
   F_WGS84 : constant Long_Float := 1.0 / 298.257223563;
   E2 : constant Long_Float := 2.0 * F_WGS84 - F_WGS84 * F_WGS84;
   EP2 : constant Long_Float := E2 / (1.0 - E2);
   K0 : constant Long_Float := 0.9996;
   FE : constant Long_Float := 500000.0;

   UTM_NO_ERROR              : constant := 16#0000#;
   UTM_LAT_ERROR             : constant := 16#0001#;
   UTM_LON_ERROR             : constant := 16#0002#;
   UTM_EASTING_ERROR         : constant := 16#0004#;
   UTM_NORTHING_ERROR        : constant := 16#0008#;
   UTM_ZONE_ERROR            : constant := 16#0010#;
   UTM_HEMISPHERE_ERROR      : constant := 16#0020#;
   UTM_ZONE_OVERRIDE_ERROR   : constant := 16#0040#;
   UTM_A_ERROR               : constant := 16#0080#;
   UTM_INV_F_ERROR           : constant := 16#0100#;


   procedure Check_Error (Code : in Long_Integer) is
   begin
      case Code is
         when UTM_NO_ERROR              =>
            return;
         when UTM_LAT_ERROR             =>
            Pace.Log.Put_Line ("Geotrans Latitude Error (hint: must be a value in Radians)");
         when UTM_LON_ERROR             =>
            Pace.Log.Put_Line ("Geotrans Longitude Error (hint: must be a value in Radians)");
         when UTM_EASTING_ERROR         =>
            Pace.Log.Put_Line ("Geotrans Easting Error");
         when UTM_NORTHING_ERROR        =>
            Pace.Log.Put_Line ("Geotrans Northing Error");
         when UTM_ZONE_ERROR            =>
            Pace.Log.Put_Line ("Geotrans Zone Error");
         when UTM_HEMISPHERE_ERROR      =>
            Pace.Log.Put_Line ("Geotrans Hemisphere Error");
         when UTM_ZONE_OVERRIDE_ERROR   =>
            Pace.Log.Put_Line ("Geotrans Zone Override Error");
         when UTM_A_ERROR               =>
            Pace.Log.Put_Line ("Geotrans UTM_A Error");
         when UTM_INV_F_ERROR           =>
            Pace.Log.Put_Line ("Geotrans UTM_INV_F Error");
         when others =>
            Pace.Log.Put_Line ("Geotrans Unknown Error, check on units as Geotrans requires Radians, not Degrees");
      end case;
      raise Geotrans_Error;
   end;

   function Initialize_Engine return Long_Integer is
   begin
      return 0;
   end;

   function Convert_UTM_To_Geodetic (Zone       : in Long_Integer;
                                     Hemisphere : in Character;
                                     Easting    : in Long_Float;
                                     Northing   : in Long_Float;
                                     Latitude   : access Long_Float;
                                     Longitude  : access Long_Float) return Long_Integer is
      X : constant Long_Float := Easting - FE;
      Y : Long_Float := Northing;
      
      E1 : constant Long_Float := (1.0 - sqrt(1.0 - E2)) / (1.0 + sqrt(1.0 - E2));
      M : Long_Float;
      Mu : Long_Float;
      Phi1 : Long_Float;
      
      C1, T1, N1, R1, D : Long_Float;
      
      -- Footpoint latitude coefficients
      J1 : constant Long_Float := (3.0 * E1 / 2.0 - 27.0 * E1**3 / 32.0);
      J2 : constant Long_Float := (21.0 * E1**2 / 16.0 - 55.0 * E1**4 / 32.0);
      J3 : constant Long_Float := (151.0 * E1**3 / 96.0);
      J4 : constant Long_Float := (1097.0 * E1**4 / 512.0);

   begin
      if Hemisphere = 'S' or Hemisphere = 's' then
         Y := Y - 10000000.0;
      end if;

      M := Y / K0;
      Mu := M / (A_WGS84 * (1.0 - E2 / 4.0 - 3.0 * E2**2 / 64.0 - 5.0 * E2**3 / 256.0));
      
      Phi1 := Mu + J1 * sin(2.0 * Mu) + J2 * sin(4.0 * Mu) + J3 * sin(6.0 * Mu) + J4 * sin(8.0 * Mu);
      
      C1 := EP2 * cos(Phi1)**2;
      T1 := tan(Phi1)**2;
      N1 := A_WGS84 / sqrt(1.0 - E2 * sin(Phi1)**2);
      R1 := A_WGS84 * (1.0 - E2) / (1.0 - E2 * sin(Phi1)**2)**1.5;
      D := X / (N1 * K0);
      
      Latitude.all := Phi1 - (N1 * tan(Phi1) / R1) * (D**2 / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * C1**2 - 9.0 * EP2) * D**4 / 24.0
                      + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * T1**2 - 252.0 * EP2 - 3.0 * C1**2) * D**6 / 720.0);
      
      Longitude.all := (D - (1.0 + 2.0 * T1 + C1) * D**3 / 6.0 + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * C1**2 + 8.0 * EP2 + 24.0 * T1**2) * D**5 / 120.0) / cos(Phi1);
      
      -- Central meridian
      Longitude.all := Longitude.all + ((Long_Float(Zone) - 1.0) * 6.0 - 180.0 + 3.0) * Ada.Numerics.Pi / 180.0;

      return 0;
   end;

   function Convert_Geodetic_To_UTM (Latitude   : in Long_Float;
                                     Longitude  : in Long_Float;
                                     Zone       : access Long_Integer;
                                     Hemisphere : access Character;
                                     Easting    : access Long_Float;
                                     Northing   : access Long_Float) return Long_Integer  is
      Lat : constant Long_Float := Latitude;
      Lon : constant Long_Float := Longitude;
      Lon_Deg : constant Long_Float := Lon * 180.0 / Ada.Numerics.Pi;
      
      Z : constant Long_Integer := Long_Integer(Long_Float'Floor((Lon_Deg + 180.0) / 6.0)) + 1;
      Lon0 : constant Long_Float := ((Long_Float(Z) - 1.0) * 6.0 - 180.0 + 3.0) * Ada.Numerics.Pi / 180.0;
      
      N, T, C, A, M : Long_Float;
   begin
      Zone.all := Z;
      if Lat >= 0.0 then
         Hemisphere.all := 'N';
      else
         Hemisphere.all := 'S';
      end if;
      
      N := A_WGS84 / sqrt(1.0 - E2 * sin(Lat)**2);
      T := tan(Lat)**2;
      C := EP2 * cos(Lat)**2;
      A := (Lon - Lon0) * cos(Lat);
      
      M := A_WGS84 * ((1.0 - E2/4.0 - 3.0*E2**2/64.0 - 5.0*E2**3/256.0)*Lat 
           - (3.0*E2/8.0 + 3.0*E2**4/32.0 + 45.0*E2**3/1024.0)*sin(2.0*Lat)
           + (15.0*E2**2/256.0 + 45.0*E2**3/1024.0)*sin(4.0*Lat)
           - (35.0*E2**3/3072.0)*sin(6.0*Lat));
           
      Easting.all := K0 * N * (A + (1.0 - T + C) * A**3 / 6.0 + (5.0 - 18.0 * T + T**2 + 72.0 * C - 58.0 * EP2) * A**5 / 120.0) + FE;
      Northing.all := K0 * (M + N * tan(Lat) * (A**2 / 2.0 + (5.0 - T + 9.0 * C + 4.0 * C**2) * A**4 / 24.0 + (61.0 - 58.0 * T + T**2 + 600.0 * C - 330.0 * EP2) * A**6 / 720.0));
      
      if Hemisphere.all = 'S' then
         Northing.all := Northing.all + 10000000.0;
      end if;

      return 0;
   end;


   procedure UTM_To_Geo (
         Easting, Northing : in Long_Float;
         Zone : in Integer;
         hemisphere : in Character := 'N';
         Longitude, Latitude, Height : out Long_Float) is
      L : Pace.Semaphore.Lock(M'Access);
      Ret : Long_Integer;
      Lo, La : aliased Long_Float;
   begin
      Ret := Convert_UTM_To_Geodetic (Zone => Long_Integer(Zone),
                                      Hemisphere => hemisphere,
                                      Easting => Easting,
                                      Northing => Northing,
                                      Latitude => La'Access,
                                      Longitude => Lo'Access);
      Check_Error (Ret);
      Height := 0.0;
      Longitude := Lo;
      Latitude := La;
   end;

   procedure Geo_To_UTM (
         Longitude, Latitude, Height : in Long_Float;
         Easting, Northing : out Long_Float;
         Zone : out Integer;
         hemisphere : out Character) is
      L : Pace.Semaphore.Lock(M'Access);
      Z : aliased Long_Integer;
      H : aliased Character;
      E, N : aliased Long_Float;
      Ret : Long_Integer;
   begin
      -- ignore height
      if abs Longitude > 2.0*Ada.Numerics.Pi and
         abs Latitude > 2.0*Ada.Numerics.Pi then
         Pace.Log.Put_Line ("Geotrans Lat/Lon out of range in Radians?");
      end if;
      Ret := Convert_Geodetic_To_UTM (Latitude => Latitude,
                                      Longitude => Longitude,
                                      Zone => Z'access,
                                      Hemisphere => H'Access,
                                      Easting => E'Access,
                                      Northing => N'Access);
      Check_Error (Ret);
      Zone := Integer (Z);
      Hemisphere := H;
      Easting := E;
      Northing := N;
   end;

   The_Path : constant String := Pace.Config.Find_File ("/maps/");

begin
   Ada.Environment_Variables.Set ("ELLIPSOID_DATA", The_Path);
   Ada.Environment_Variables.Set ("DATUM_DATA", The_Path);
   Ada.Environment_Variables.Set ("GEOID_DATA", The_Path);
   Check_Error (Initialize_Engine);

end Hal.GeoTrans;
