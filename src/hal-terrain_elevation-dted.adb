with Ada.Numerics.Elementary_Functions;
with Hal.Ordering;
with Pace.Config;
with Pace.Log;
with Text_IO;
with Hal.Geotrans;
with Pace.Strings;

package body Hal.Terrain_Elevation.DTED is

   DTED_Level : constant Integer := Pace.Getenv ("DTED_LEVEL", 2);
   DLon : Integer := Pace.Getenv ("DTED_LON", -107);
   DLat : Integer := Pace.Getenv ("DTED_LAT", 32);
   
   function Endian_Convert_Int is new Hal.Ordering (Integer);
   function Endian_Convert_Int_16 is new Hal.Ordering (
      Interfaces.Integer_16,
      2);
   function Endian_Convert_Flt is new Hal.Ordering (Float);

   Spacing  : constant := 92.6889259;  -- This varies depending on Latitude, close enough to calculate pitch and roll
   Scaler   : constant Float := 1.0 + 2.0*Float(DTED_Level-1);

   East_Spacing  : Float := Spacing / Scaler;  -- divide by 3 if Level 2
   North_Spacing : Float := Spacing / Scaler;
   
   SWE, SWN : Long_Float;
   Zone : Integer;
   Hemisphere : Character;

   package DD is new Dted_Data (Level => DTED_Level);

   procedure Read_Dted_File (Name : in String) is
      D_File : DD.Io.File_Type;
      Max : constant Integer := DD.Maximum;
   begin
      DD.Io.Open (D_File, DD.Io.In_File, Name);
      -- If file is there then allocate memory
      DD.The_Grid := new DD.Data_Set;
      DD.Io.Read (D_File, DD.The_Grid.all);
      DD.Io.Close (D_File);
      Pace.Log.Put_Line ("Finished DTED Map, Elevations");
      Text_IO.Put_Line ("SW=" & Endian_Convert_Int_16(DD.The_Grid.Data_Records (0).Post_Data(0))'Img);
      Text_IO.Put_Line ("NW=" & Endian_Convert_Int_16(DD.The_Grid.Data_Records (0).Post_Data(Max))'Img);
      Text_IO.Put_Line ("SE=" & Endian_Convert_Int_16(DD.The_Grid.Data_Records (Max).Post_Data(0))'Img);
      Text_IO.Put_Line ("NE=" & Endian_Convert_Int_16(DD.The_Grid.Data_Records (Max).Post_Data(Max))'Img);
      Text_IO.Put_Line ("MP=" & Endian_Convert_Int_16(DD.The_Grid.Data_Records (Max/2).Post_Data(Max/2))'Img);

      Geotrans.Geo_To_UTM (Longitude => Hal.Rads(Long_Float (DLon)),
                           Latitude => Hal.Rads(Long_Float (DLat)), 
                           Height => 0.0,
                           Easting => SWE,
                           Northing => SWN,
                           Zone => Zone,
                           Hemisphere => Hemisphere);
      Text_IO.Put_Line ("H Z:" & Hemisphere & Zone'Img);
   exception
      when E : DD.Io.End_Error =>
         DD.Io.Close (D_File);
         Pace.Log.Ex (E, "End DTED Map");
      when E : others =>
         if DD.Io.Is_Open (D_File) then
            DD.Io.Close (D_File);
         end if;
         Pace.Log.Ex (E, "DTED File Read Error on " & Name);
   end Read_Dted_File;

   procedure Get_Post_Data
     (Easting, Northing : in Float;
      P0, Px, Py        : out Float)
   is
      A, B : Integer;
   begin
      A  := Integer(Easting * Float(DD.Maximum));
      B  := Integer(Northing * Float(DD.Maximum));
      P0 :=
        Float (Endian_Convert_Int_16
                  (DD.The_Grid.Data_Records (A).Post_Data (B)));
      Px :=
        Float (Endian_Convert_Int_16
                  (DD.The_Grid.Data_Records (A + 1).Post_Data (B)));
      Py :=
        Float (Endian_Convert_Int_16
                  (DD.The_Grid.Data_Records (A).Post_Data (B + 1)));
   exception
      when E : others =>
         P0 := 0.0;
         Px := 0.0;
         Py := 0.0;
         Pace.Log.Ex (E, "Error reading DTED map data for E=" & Easting'Img & " N=" & Northing'Img);
   end Get_Post_Data;

   procedure Get_LL
     (Easting, Northing : in Float;
      Zone_Number       : in Integer;
      Zone_Letter       : in Character;
      FLon, FLat        : out Float) is
      Latitude, Longitude, Height : Long_Float;
   begin
      Geotrans.UTM_To_Geo (Easting => Long_Float (Easting), 
                           Northing => Long_Float (Northing),
                           Zone => Zone_Number,
                           Hemisphere => Zone_Letter,
                           Longitude => Longitude, 
                           Latitude => Latitude, 
                           Height => Height);
      FLon := Float(Hal.Degs(Longitude) - Long_Float(DLon));  -- Take fraction over
      FLat := Float(Hal.Degs(Latitude)  - Long_Float(DLat));  -- Take fraction over 
   end;


   procedure UTM  -- Returns lower left of data 
     (Latitude, Longitude : in Long_Float;
      SW_East, SW_North   : out Float;
      Easting, Northing   : out Float;
      Zone_Number         : out Integer;
      Hemisphere          : out Character) is
   begin
      Geotrans.Geo_To_UTM (Longitude => Longitude,
                           Latitude => Latitude, 
                           Height => 0.0,
                           Easting => Long_Float(Easting),
                           Northing => Long_Float(Northing),
                           Zone => Zone_Number,
                           Hemisphere => Hemisphere);
      SW_East := Float(SWE);
      SW_North := Float(SWN);
   end UTM;


   procedure Get_Pitch_and_Roll
     (P0, Px, Py  : in Float;
      Heading     : in Float;
      Pitch, Roll : out Float)
   is
      use Ada.Numerics;
      use Ada.Numerics.Elementary_Functions;
      Pa, Pb, Denom : Float;
      Numerator     : Float;
   begin
      Pa := Float (Px - P0) / North_Spacing;
      Pb := Float (Py - P0) / East_Spacing;

      Denom := Sqrt ((Pa * Pa) + (Pb * Pb) + 1.0);

      -- Find the Pitch
      Numerator := Pa * Cos (Heading) + Pb * Sin (Heading);
      Pitch     := -(Arccos (Numerator / Denom) - Pi / 2.0);

      -- Find the Roll
      Numerator := Pa * Sin (Heading) - Pb * Cos (Heading);
      Roll      := Arccos (Numerator / Denom) - Pi / 2.0;
   end Get_Pitch_and_Roll;

   ----------------------
   -- Get_Terrain_Data --
   ----------------------

   procedure Get_Terrain_Data
     (Easting, Northing : in Float;
      Zone_Number       : in Integer;
      Zone_Letter       : in Character;
      Heading           : in Float;
      Altitude          : out Float;
      Pitch, Roll       : out Float)
   is
      P0, Px, Py : Float;
      FLon, FLat : Float;
   begin
      Get_LL (Easting, Northing, Zone_Number, Zone_Letter, FLon, FLat);
      Get_Post_Data (FLon, FLat, P0, Px, Py);
      Get_Pitch_and_Roll (P0, Px, Py, Heading, Pitch, Roll);
      Altitude := P0;
   end Get_Terrain_Data;

   function Get_Altitude
     (Easting, Northing : in Float;
      Zone_Number       : in Integer;
      Zone_Letter       : in Character)
      return              Float
   is
      P0, Px, Py : Float;
      FLon, FLat : Float;
   begin
      Get_LL (Easting, Northing, Zone_Number, Zone_Letter, FLon, FLat);
      Get_Post_Data (FLon, FLat, P0, Px, Py);
      return P0;
   end Get_Altitude;

--     procedure Load_Defaults is
--        use Kb.Rules;
--        V : Variables (1 .. 5);
--     begin
--        Kb.Agent.Query ("dted_default", V);
--        Read_Dted_File (Name => Pace.Config.Find_File (+V (1)));
--        East_Spacing := Float'Value (+V (4));
--        North_Spacing := Float'Value (+V (5));
--     exception
--        when Not_Found =>
--           Read_Dted_File (Name => Pace.Config.Find_File ("/maps/dted/w116/n35.dt1"));
--     end Load_Defaults;

   function Construct (Lon, Lat : in Integer;
                       Level : in Integer) return String is
      use Pace.Strings;
   begin
      if Lon < 0 then
         return "maps/dted/W" & Trim(-Lon) & "/N" & Trim(Lat) & ".dt" & Trim(Level);
      else
         return "maps/dted/E" & Trim(Lon) & "/N" & Trim(Lat) & ".dt" & Trim(Level);
      end if;      
   end Construct;

--    procedure Load_Defaults (File : in String) is
--    begin
--       Read_Dted_File (Name => Pace.Config.Find_File (File));
--    end Load_Defaults;

   
begin
   -- Read Default DTED, should use KBase
   -- Read_Dted_File (Name => Pace.Config.Find_File ("/maps/dted/w117/n35.dt1"));
   -- Read_Dted_File (Name => Pace.Config.Find_File ("/maps/dted/W107/N32.dt2"));
   Read_Dted_File (Name => Pace.Config.Find_File (Construct(DLon,DLat,DTED_Level)));
end Hal.Terrain_Elevation.DTED;
