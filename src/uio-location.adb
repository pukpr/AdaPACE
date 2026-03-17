with Gkb.Database;
with Pace.Log;
with Pace.Server.Xml;
with Hal.Geotrans;
with Hal.Rotations;
with Ual.Utilities;
with Pace.Xml;
with Pace.Strings;

package body Uio.Location is

   use Pace.Strings;
   use Pace.Server.Dispatch;
   use Pace.Xml;

   procedure Inout (Obj : in out Place_Vehicle_Utm) is
      Msg : Location_Model.Relocate;
      Xml : Pace.Xml.Doc_Type := Parse (U2s (Obj.Set));
   begin
      Msg.Easting := Float'Value (Search_Xml (Xml, "easting"));
      Msg.Northing := Float'Value (Search_Xml (Xml, "northing"));
      Msg.Heading := Float'Value (Search_Xml (Xml, "heading"));
      if Pace.Server.Keys.Value ("israd", "false") = "false" then
         Msg.Heading := Hal.Rads (Msg.Heading);
      end if;
      Pace.Dispatching.Inout (Msg);
      if Msg.Success then
         Pace.Server.Put_Data ("Vehicle moved to the specified location.  Trip reset.  Odometer...");
      else
         Pace.Server.Put_data ("Either the given easting or northing is less than the southeast corner of the map!");
      end if;
   exception
      when E : others =>
         Pace.Log.Ex (E);
         Pace.Server.Put_Data ("Exception occurred. See fault manager. Possibly the easting, northing, or heading had a constraint error when being cast to a float.");
   end Inout;

   procedure Inout (Obj : in out Place_Vehicle_LatLongQuat) is
      Latitude, Longitude : Float;
      Dummy1, Dummy2 : Float;

      Zone : Integer;
      Hemi : Character;
      Msg : Location_Model.Relocate;
      Xml : Pace.Xml.Doc_Type := Parse (U2s (Obj.Set));
   begin
      -- Inputs
      --    Quat : W, X, Y, Z
      --    WGS  : Latitude, Longitude
      -- Outputs
      --    UTM  : Easting, Northing
      --    Euler : Yaw
      -- Ignore
      --    Euler : Pitch, Roll
      --    UTM : Height, Zone, Hemisphere
      Latitude := Float'Value (Search_Xml (Xml, "latitude"));
      Longitude := Float'Value (Search_Xml (Xml, "longitude"));
      Hal.Rotations.To_Euler (W => Float'Value (Search_Xml (Xml, "w")),  -- In
                              X => Float'Value (Search_Xml (Xml, "x")),  -- In
                              Y => Float'Value (Search_Xml (Xml, "y")),  -- In
                              Z => Float'Value (Search_Xml (Xml, "z")),  -- In
                              Yaw => Msg.Heading,   -- Out
                              Pitch => Dummy1, -- Out
                              Roll => Dummy2,  -- Out

                              Latitude => Latitude, -- In
                              Longitude => Longitude); -- In

      if Pace.Server.Keys.Value ("israd", "false") = "false" then
         Msg.Heading := Hal.Rads (Msg.Heading);
      end if;

--       Gis.Wgs84_To_Cartesian(Latitude => , -- In
--                              Longitude => ,
--                              Altitude =>,
--                              X =>,  -- Out
--                              Y => ,
--                              Z => );
--       R := Sqrt(X*X + Y*Y + Z*Z);

      Hal.Geotrans.Geo_To_UTM (
                               Longitude => Long_Float (Longitude), -- In
                               Latitude => Long_Float (Latitude),
                               Height => 0.0,    -- H(SeaLevel) or R(CenterOFEarth)
                               Easting  => Long_Float (Msg.Easting),  -- Out
                               Northing => Long_Float (Msg.Northing), -- Out
                               Zone => Zone,
                               Hemisphere => Hemi);

      Pace.Dispatching.Inout (Msg);

      if Msg.Success then
         Pace.Server.Put_Data ("Vehicle moved to the specified location.  Trip reset.  Odometer...");
      else
         Pace.Server.Put_data ("Either the given easting or northing is less than the southeast corner of the map!");
      end if;

   exception
      when E : others =>
         Pace.Log.Ex (E);
         Pace.Server.Put_Data ("Exception occurred. See fault manager. Possibly one of the parameters had a constraint error when being cast to a float.");
   end Inout;

   procedure Inout (Obj : in out Utmrpy_To_Latlongquat) is
      use Pace.Server.Xml;
      Xml : Pace.Xml.Doc_Type := Parse (U2s (Obj.Set));
      Easting, Northing, Yaw, Pitch, Roll : Float;
      Zone : Integer;
      Hemisphere : Character;
      Latitude, Longitude, Height : Long_Float;
      W, X, Y, Z : Float;
      Hs : constant String := Search_Xml (Xml, "hemisphere");
   begin
      Easting := Float'Value (Search_Xml (Xml, "easting"));
      Northing := Float'Value (Search_Xml (Xml, "northing"));
      Yaw := Float'Value (Search_Xml (Xml, "yaw"));
      Pitch := Float'Value (Search_Xml (Xml, "pitch"));
      Roll := Float'Value (Search_Xml (Xml, "roll"));
      Zone := Integer'Value (Search_Xml (Xml, "zone"));
      Hemisphere := Hs (Hs'First);

      Hal.Geotrans.Utm_To_Geo (Long_Float (Easting),
                               Long_Float (Northing),
                               Zone,
                               Hemisphere,
                               Longitude,
                               Latitude,
                               Height);

      Hal.Rotations.To_Quaternion (Yaw, Pitch, Roll, W, X, Y, Z, Float (Latitude), Float (Longitude));

      Obj.Set := S2u (Item ("coordinate",
                            Item ("latitude", Float (Latitude)) &
                            Item ("longitude", Float (Longitude)) &
                            Item ("height", Float (Height)) &
                            Item ("w", W) &
                            Item ("x", X) &
                            Item ("y", Y) &
                            Item ("z", Z)));
      Pace.Server.Xml.Put_Content;
      Pace.Server.Put_Data (U2s (Obj.Set));
   exception
      when E : others =>
         Pace.Log.Ex (E);
         Pace.Server.Put_Data ("Exception occurred. See fault manager. Possibly the easting, northing, or heading had a constraint error when being cast to a float.");
   end Inout;

begin
   Save_Action (Place_Vehicle_Utm'(Pace.Msg with Set => Default));
   Save_Action (Place_Vehicle_LatLongQuat'(Pace.Msg with Set => Default));
   Save_Action (Utmrpy_To_Latlongquat'(Pace.Msg with Set => Default));
end Uio.Location;
