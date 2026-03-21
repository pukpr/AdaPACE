with Pace.Log;
with Pace.Config;
with Interfaces.C.Strings;
with Ada.Environment_Variables;
with Ada.Numerics;

package body Hal.GeoTrans is

   function ID is new Pace.Log.Unit_ID;

   --pragma Linker_Options ("-lm");

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

--   procedure Geotrans_Init (Path : in Interfaces.C.Strings.Chars_Ptr);
--   pragma Import (Cpp, Geotrans_Init, "_Z13geotrans_initPKc");

   function Initialize_Engine return Long_Integer is
   begin
      return 0;
   end;
--   pragma Import (Cpp, Initialize_Engine, "Initialize_Engine");

   function Convert_UTM_To_Geodetic (Zone       : in Long_Integer;
                                     Hemisphere : in Character;
                                     Easting    : in Long_Float;
                                     Northing   : in Long_Float;
                                     Latitude   : access Long_Float;
                                     Longitude  : access Long_Float) return Long_Integer is
   begin
      Latitude.all := 0.7;
      Longitude.all := 0.7;
      return 0;
   end;
                                  
   --pragma Import (Cpp, Convert_UTM_To_Geodetic, "Convert_UTM_To_Geodetic");


   function Convert_Geodetic_To_UTM (Latitude   : in Long_Float;
                                     Longitude  : in Long_Float;
                                     Zone       : access Long_Integer;
                                     Hemisphere : access Character;
                                     Easting    : access Long_Float;
                                     Northing   : access Long_Float) return Long_Integer  is
   begin
      return 0;
   end;
   --pragma Import (Cpp, Convert_Geodetic_To_UTM, "Convert_Geodetic_To_UTM");


   procedure UTM_To_Geo (
         Easting, Northing : in Long_Float;
         Zone : in Integer;
         hemisphere : in Character := 'N';
         Longitude, Latitude, Height : out Long_Float) is
      L : Pace.Semaphore.Lock(M'Access);
      Ret : Long_Integer;
      Lo, La : aliased Long_Float;
   begin
      --Text_IO.Put_Line ("~~~I~~~" & Pace.Image & Easting'Img & Northing'Img);
      Ret := Convert_UTM_To_Geodetic (Zone => Long_Integer(Zone),
                                      Hemisphere => hemisphere,
                                      Easting => Easting,
                                      Northing => Northing,
                                      Latitude => La'Access,
                                      Longitude => Lo'Access);
      --Text_IO.Put_Line ("~~~O~~~" & Pace.Image & Easting'Img & Northing'Img);
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
   ---- A variant of Geotrans for CTDB only needs the following line:
   -- Geotrans_Init (Interfaces.C.Strings.New_String(The_Path));

   ---- This variant of Geotrans needs env vars set:
   Ada.Environment_Variables.Set ("ELLIPSOID_DATA", The_Path);
   Ada.Environment_Variables.Set ("DATUM_DATA", The_Path);
   Ada.Environment_Variables.Set ("GEOID_DATA", The_Path);
   Check_Error (Initialize_Engine);

   -- $Id: hal-geotrans.adb,v 1.7 2006/04/14 23:14:11 pukitepa Exp $
end;
