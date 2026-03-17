with Hal.Ctdb;
with Hal.Geotrans;
with Pace.Log;
with Pace.Config;
with Ada.Numerics;

package body Gis.CTDB is


   Old_Water, Old_No_Go, Old_Slow_Go, Old_Road : Boolean := False;


   procedure Place_Vehicle
     (U                            : in UTM_Coordinate;
      X, Y                         : in Long_Float;
      Length, Width, Heading       : in Float;
      Elevation                    : out Float;
      Pitch, Roll                  : out Float;
      Viscosity                    : out Float) is
      
      Lat, Lon : Long_Float; -- Ignored
      Water, No_Go, Slow_Go, Road : Boolean;
      Rotation : Hal.Ctdb.Rotation_Matrix;
      
   begin
      if Is_Using_Ctdb_World then
         Hal.Ctdb.Place_Vehicle (
                     Zone => U.Zone_Num,
                     E => Long_Float (U.Easting),
                     N => Long_Float (U.Northing),
                     --  Hemisphere ????? := UTM_Coord.Hemisphere
                     Length => Long_Float(Length),
                     Width => Long_Float(Width),
                     Heading => Long_Float(Heading),
                     Latitude => Lat,
                     Longitude => Lon,
                     Z => Long_Float(Elevation),
                     Pitch => Long_Float (Pitch),
                     Roll => Long_Float (Roll),
                     Rotation => Rotation,
                     Water => Water,
                     No_Go => No_Go,
                     Slow_Go => Slow_Go,
                     Road => Road);
      else
         Hal.Ctdb.Place_Vehicle (X, Y, 
                                 Long_Float(Length), Long_Float(Width),
                                 Long_Float(Heading), 
                                 Long_Float(Elevation), 
                                 Pitch, 
                                 Roll, 
                                 Rotation, Water, No_Go, Slow_Go, Road);
      end if;
      Pace.Log.Put_Line ("pos is: " & Long_Float'Image(X) & " " & Long_Float'Image(Y), 10);
      Pace.Log.Put_Line ("pitch from ctdb is " & Float'Image (Pitch), 10);
      Pace.Log.Put_Line ("roll from ctdb is " & Float'Image (Roll), 10);
      Pace.Log.Put_Line ("elevation from ctdb is " & Float'Image (Elevation), 10);
      if Water or No_Go or Slow_Go or Road then
         if Water /= Old_Water or No_Go /= Old_No_Go or Slow_Go /= Old_Slow_Go or Road /= Old_Road then
            Pace.Log.Put_Line ("WATER=" & Boolean'Image (Water) & 
                               " NOGO=" & Boolean'Image (No_Go) & 
                               " SLOW=" & Boolean'Image (Slow_Go) & 
                               " ROAD=" & Boolean'Image (Road) );
         end if;
         if No_Go then
            Viscosity := 0.9;
         elsif Slow_Go then
            Viscosity := 0.5;
         else
            Viscosity := 0.0;
         end if;
      else
         Viscosity := 0.0;
      end if;
      Old_Water := Water;
      Old_No_Go := No_Go;
      Old_Slow_Go := Slow_Go;
      Old_Road := Road;
  
   end Place_Vehicle;



   procedure Set_Vehicle_Location_From_LL (Latitude, Longitude : in Long_Float;
                                           SW_UTM, UTM         : out UTM_Coordinate) is
      Zone : Integer;
      Lat : Long_Float := Latitude;
      Lon : Long_Float := Longitude;
      Min_Northing, Min_Easting : Long_Float;
      Hemisphere : Character;
      Hemisphere_String : String := "North";
   begin
      if abs Longitude <= Ada.Numerics.Pi and abs Latitude <= Ada.Numerics.Pi then
         null;  -- in radians
      else
         -- conversion to radians won't work for a small region in the ocean near nigeria
         Lon := Hal.Rads (Longitude);
         Lat := Hal.Rads (Latitude);
      end if;

      Hal.GeoTrans.Geo_To_UTM (
            Longitude => Lon,  -- Radians
            Latitude => Lat,  -- Radians
            Height => 0.0,
            Easting => Long_Float(UTM.Easting),
            Northing => Long_Float(UTM.Northing),
            Zone => Zone,
            Hemisphere => Hemisphere);
      --Mobility.Zone : Zone;
      UTM.Zone_Num := Zone;

      Pace.Log.Put_Line ("Geotrans converts to UTM: " & UTM.Easting'Img & UTM.Northing'Img & Zone'Img & " " & Hemisphere);
      Hal.Ctdb.UTM (
         Zone => Zone,
         Northing => Long_Float(UTM.Northing),
         Easting => Long_Float(UTM.Easting),
         Zone_Number => Zone,
         Min_Northing => Min_Northing,
         Min_Easting => Min_Easting);
      Pace.Log.Put_Line ("#SouthWest corner UTM terrain point " &
                         " Z=" & Zone'Img &
                         " N=" & Min_Northing'Img &
                         " E=" & Min_Easting'Img);

      -- Easting_Zero := Float (Min_Easting);
      SW_UTM.Easting := Float (Min_Easting);
      -- Northing_Zero := Float (Min_Northing);
      SW_UTM.Northing := Float (Min_Northing);
      -- assert zone and zone_letter to kbase
      if Hemisphere = 'N' then
         UTM.Hemisphere := North;
         SW_UTM.Hemisphere := North;
      else
         --Hemisphere_String := "South";
         UTM.Hemisphere := South;
         SW_UTM.Hemisphere := South;
      end if;
      SW_UTM.Zone_Num := Zone;
--      Kb.Agent.Assert ("zone(" & Integer'Image (Zone) & ")");
--      Kb.Agent.Assert ("hemisphere(" & '"' & Hemisphere_String & '"' & ")");
   end;


   procedure UTM
     (Latitude, Longitude : in Long_Float;
      SW_UTM, UTM         : out UTM_Coordinate) is
      
   begin
      if Is_Using_CTDB_World and (Latitude /= 0.0 or Longitude /= 0.0) then
         -- Using_CTDB_World := True;
         Set_Vehicle_Location_From_LL (Latitude  => Latitude,
                                       Longitude => Longitude,
                                       SW_UTM    => SW_UTM,
                                       UTM       => UTM);
      else
         -- get southwest corner of map
         declare
            Source, Datum : Integer;
            Zone_Letter : Character;
            North, East : Long_Float;
            Zone : Integer;
         begin
            Hal.Ctdb.UTM (Source, Datum, Zone, Zone_Letter, North, East);
            --Easting_Zero := Float (East);
            --Northing_Zero := Float (North);
            SW_UTM.Easting := Float(East);
            SW_UTM.Northing := Float(North);
            SW_UTM.Zone_Num := Zone;

            -- assert zone and zone_letter to kbase
            if Zone_Letter < 'N' then
               --Hemisphere_String := "South";
               SW_UTM.Hemisphere := Gis.South;
            else
               SW_UTM.Hemisphere := Gis.North;
            end if;
            --if Zone_Letter < 'N' then
            --   Hemisphere := "South";
            --end if;
         end;
      end if;
   end Utm;
   
begin
   if Is_Using_CTDB_World then
      -- Need to read HLA-based version which will read the "World" database
      Pace.Log.Put_Line ("Opening data for Cmd Line terrain using World CTDB access");
      Hal.CTDB.Read;
   else
      -- read ctdb file
      declare
         File : String := Pace.Config.Find_File (Pace.Getenv ("CTDB_TERRAIN_FILE", "../utils/geography/ctdb/data/FirstApp.c7l"));
      begin
         if File = "" then
            Pace.Log.Put_Line ("!!!!!!!! Couldn't find ctdb data file.  Terrain monitoring will be turned off.");
         else
            Hal.Ctdb.Read (File);
            Pace.Log.Put_Line ("done reading ctdb data file");
         end if;
      end;
   end if;   

end Gis.CTDB;
