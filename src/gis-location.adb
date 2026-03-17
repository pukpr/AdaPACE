with Gkb.Database;
with Pace.Log;
with Pace.Semaphore;
with Pace.Server;
with Pace.Config;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Hal.Ve;
with Hal.Sms;
with Hal;
with Gis.Tdb;
with Hal.Geotrans;
with Pace.Command_Line;

package body Gis.Location is

   function Id is new Pace.Log.Unit_Id;
   function Name return String renames Pace.Log.Name;

   package Db is new Kb.Database;

   Northing_Initial, Easting_Initial : Float;
   Northing_Zero, Easting_Zero : Float;

   Initialized : Boolean := False;
   Zone : Integer := 1;
   Hemisphere : Hemisphere_Type;
   Run_Test_Loop : Boolean := Pace.Getenv ("GIS_TEST_LOOP", 0) = 1;

   Pace_Node : String := Pace.Getenv ("PACE_NODE", "0");

   function Get_Pos_From_Sw_Corner (Easting : Float; Northing : Float) return Hal.Position is
      Result : Hal.Position;
   begin
      Result := (Easting - Easting_Zero, 0.0, Northing - Northing_Zero);
      return Result;
   end Get_Pos_From_Sw_Corner;

   function Get_Vehicle_Pos_From_Sw_Corner (North, East, Altitude : Float) return Hal.Position is
      Result : Hal.Position;
   begin
      Result := (East + Easting_initial - Easting_Zero, Altitude, North + Northing_Initial - Northing_Zero);
      return Result;
   end Get_Vehicle_Pos_From_Sw_Corner;

   -- from lower left corner of map!
   function Get_Vehicle_Pos_From_Sw_Corner return Hal.Position is
   begin
      return Get_Vehicle_Pos_From_Sw_Corner (Mobility.North, Mobility.East, Mobility.Altitude);
   end Get_Vehicle_Pos_From_Sw_Corner;

   -- it is assumed that TDB is being used unless the following env var is set to 0
   Using_Tdb : Boolean := Pace.Getenv ("USING_TDB", 0) = 1;

   function Is_Using_Tdb return Boolean is
   begin
      return Using_Tdb;
   end Is_Using_Tdb;

   function Get_Sw_Corner_Easting return Float is
   begin
      return Easting_Zero;
   end Get_Sw_Corner_Easting;

   function Get_Sw_Corner_Northing return Float is
   begin
      return Northing_Zero;
   end Get_Sw_Corner_Northing;

   procedure Set_Initial (SW_UTM : UTM_Coordinate) is
   begin
      Easting_Zero := SW_UTM.Easting;
      Northing_Zero := SW_UTM.Northing;
      Zone := SW_UTM.Zone_Num;
      Mobility.Zone := Zone;
      Kb.Agent.Assert ("zone(" & Integer'Image (Zone) & ")");
      Hemisphere := SW_UTM.Hemisphere;
      Kb.Agent.Assert ("hemisphere(" & '"' & Hemisphere_Type'Image(SW_UTM.Hemisphere) & '"' & ")");
   end;

   procedure Set_Vehicle_Location_From_LL (Latitude : in Long_Float;
                                          Longitude : in Long_Float) is
      SW_UTM, UTM : UTM_Coordinate;
   begin
      -- This only works with CTDB World at the moment, since that is world-wide
      if Is_Using_Tdb then
         Gis.TDB.UTM (Latitude, Longitude, SW_UTM, UTM);
         Set_Initial (SW_UTM);
         Easting_Initial := UTM.Easting;
         Northing_Initial := UTM.Northing;
      end if;
   end;

   procedure Set_Current_Reference_Location is
      use Kb.Rules;
      Latitude : Long_Float := Long_Float'Value(Pace.Getenv("HLA_LAT", "0.0"));
      Longitude : Long_Float := Long_Float'Value(Pace.Getenv("HLA_LONG", "0.0"));
      Hemi : Character;
      SW_UTM, UTM : UTM_Coordinate;
   begin

      -- if latitude + longitude is 0.0 then go with default location in kbase, otherwise
      -- go with the env vars
      if Latitude = 0.0 and Longitude = 0.0 then
         Northing_Initial := Db.Get ("northing", Pace_Node);
         Easting_Initial := Db.Get ("easting", Pace_Node);
         Zone := Db.Get ("zone");
         Hemisphere := Hemisphere_Type'Value (Db.Get("hemisphere"));
      else
         if abs Longitude <= Ada.Numerics.Pi and abs Latitude <= Ada.Numerics.Pi then
            null;  -- in radians
         else
            -- conversion to radians won't work for a small region in the ocean near nigeria
            Longitude := Hal.Rads (Longitude);
            Latitude := Hal.Rads (Latitude);
         end if;
         Hal.Geotrans.Geo_To_UTM (Longitude => Longitude, -- In
                                  Latitude => Latitude,
                                  Height => 0.0, -- H(SeaLevel) or R(CenterOFEarth)
                                  Easting  => Long_Float (Easting_Initial),  -- Out
                                  Northing => Long_Float (Northing_Initial), -- Out
                                  Zone => Zone,
                                  Hemisphere => Hemi);
         if Hemi = 'N' then
            Hemisphere := North;
         else
            Hemisphere := South;
         end if;
      end if;

      -- Post-conditions
      -----------------------
      -- Northing_Initial set
      -- Easting_Initial set
      -- Zone set
      -- Hemisphere set

      if Is_Using_Tdb then
         Gis.TDB.Utm (Latitude, Longitude, SW_UTM, UTM);
         Set_Initial (SW_UTM);
      else
         -- if not using ctdb then need southwest corner of map from kbase
         Easting_Zero := Db.Get ("southwest_easting");
         Northing_Zero := Db.Get ("southwest_northing");
         -- zone and hemisphere should already be in kbase
      end if;

      -- Post-conditions
      -----------------------
      -- Easting_Zero set
      -- Northing_Zero set

      Pace.Log.Put_Line ("easting_initial:" & Easting_Initial'Img);
      Pace.Log.Put_Line ("northing_initial:" & Northing_Initial'Img);
      Pace.Log.Put_Line ("easting_zero:" & Easting_Zero'Img);
      Pace.Log.Put_Line ("northing_zero:" & Northing_Zero'Img);
      Pace.Log.Put_Line ("zone:" & Zone'Img);
      Pace.Log.Put_Line ("hemisphere:" & Hemisphere'Img);

   exception
      when No_Match =>
         Pace.Log.Put_Line ("UTM reference locations missing from kbase");
      when E : others =>
         Pace.Log.Ex (E);
   end Set_Current_Reference_Location;

   function Get_Location return Utm_Coordinate is
      Result : Utm_Coordinate;
   begin
      -- We should use the local North and East since these are updated via a notify
      Result.Easting := Mobility.East + Easting_Initial;
      Result.Northing := Mobility.North + Northing_Initial;
      Result.Zone_Num := Zone;
      Result.Hemisphere := Hemisphere;
      return Result;
   end Get_Location;

   procedure Output (Obj : out Get_Data) is
      Msg : Mobility.Get_Trans_Status;
   begin
      Pace.Dispatching.Output (Msg);
      Obj.Coordinate := Get_Location;
      Obj.Altitude := Mobility.Altitude;
      Obj.Heading := Mobility.Heading;
      Obj.Speed := Msg.Speed;
      Obj.Pitch := Mobility.Pitch;
      Obj.Roll := Mobility.Roll;
      Obj.Odometer := Msg.Odometer;
      --Obj.Latitude := Mobility.Latitude;
      --Obj.Longitude := Mobility.Longitude;
   end Output;

   procedure Inout (Obj : in out Track_Heading) is
      Msg : Get_Data;
      X_Diff, Y_Diff : Float;
      use Ada.Numerics.Elementary_Functions;
      use Ada.Numerics;
   begin
      Output (Msg); -- get local data
      X_Diff := Obj.Target_Northing - Msg.Coordinate.Northing;
      Y_Diff := Obj.Target_Easting - Msg.Coordinate.Easting;

      Obj.Distance := Sqrt (X_Diff * X_Diff + Y_Diff * Y_Diff);
      if X_Diff = 0.0 and Y_Diff = 0.0 then
         Obj.Heading := Msg.Heading;
      else
         Obj.Heading := Arctan (Y_Diff, X_Diff);
      end if;

      -- set the heading difference.. should never be greater than 180..
      -- if handles the circular wrap-around problem
      if abs (Obj.Heading - Msg.Heading) > Pi then
         Obj.Heading_Difference := 2.0 * Pi - abs (Obj.Heading - Msg.Heading);
      else
         Obj.Heading_Difference := abs (Obj.Heading - Msg.Heading);
      end if;

      if Integer (Msg.Speed) = 0 then
         Obj.Time := Duration'Last;
      else
         Obj.Time := Duration (Obj.Distance / abs Msg.Speed);
      end if;

      Pace.Log.Trace (Msg);

   end Inout;

   task Agent is pragma Task_Name (Name);
      entry Input (Obj : in Init);
   end Agent;
   task body Agent is
      P, Old_P : Hal.Position := (Float'Last, Float'Last, Float'Last);
      R, Old_R : Hal.Orientation := (Float'Last, Float'Last, Float'Last);

      procedure Test_Loop is
         Phi : Float := 0.0;
         Radius : constant Float := 100.0;
         Delta_Phi : constant Float := 0.005;
         use Ada.Numerics.Elementary_Functions;
      begin
         loop
            P := Get_Vehicle_Pos_From_Sw_Corner (Radius*Sin(Phi), Radius*Cos(Phi), 0.0);
            R := (0.0, Phi, 0.0);
            Hal.Ve.Set ("", P, R, Pace_Node);
            Pace.Log.Wait (Duration (Mobility.Tran.Dt));
            -- speed = Radius * Delta_Phi / Dt
            Phi := Phi + 0.005;
         end loop;
      end;

      North, East, Altitude : Float;
      Heading, Pitch, Roll : Float;
   begin
      Pace.Log.Agent_Id (Id);

      accept Input (Obj : in Init) do
         Initialized := True;
         Pace.Log.Trace (Obj);
      end Input;

      declare
         Msg : Vehicle_Initialized;
      begin
         Msg.Ack := False;
         Pace.Dispatching.Input (Msg);
      end;

      if Run_Test_Loop then
         Test_Loop;
      end if;

      loop
         declare
            Msg : Mobility.Update_Six_Dof;
         begin
            Pace.Dispatching.Inout (Msg);
            North := Msg.North;
            East := Msg.East;
            Altitude := Msg.Altitude;
            Heading := Msg.Heading;
            Pitch := Msg.Pitch;
            Roll := Msg.Roll;
         end;
         --
         --             ^ Y=North
         --             |
         --             |
         --      Z(up)  +----> X=East   
         --
         if Is_Using_TDB then
            -- Set vehicle position directly based on terrain database + clamping
            --
            R := (Pitch, Roll, -Heading); -- Yaw is X into Y but compass heading reversed
            -- Use actual geographical coordinates
            P := (East + Easting_Initial, North + Northing_Initial, Altitude);
            Hal.Sms.Set (Pace_Node, P, R); -- Vehicle is named Pace_Node
         else
            -- Let VE do everything (legacy)
            --
            R := (Pitch, -Heading, -Roll);
            -- Use relative coordinates
            P := Get_Vehicle_Pos_From_Sw_Corner (North, East, Altitude);
            Hal.Ve.Set ("", P, R, Pace_Node);
         end if;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Init) is
   begin
      if not Initialized then
         Agent.Input (Obj);
      end if;
   end Input;

   procedure Inout (Obj : in out Relocate) is
      L : Pace.Semaphore.Lock (Mobility.Location_Mutex'Access);
   begin
      -- May be able to go less than zero?
      if Obj.Easting > Easting_Zero and Obj.Northing > Northing_Zero then
         Mobility.East := Obj.Easting - Easting_Initial;
         Mobility.North := Obj.Northing - Northing_Initial;
         Mobility.Heading := Obj.Heading;
         declare
            Msg : Mobility.Reset_Trip;
         begin
            Pace.Dispatching.Input (Msg);
         end;
         Obj.Success := True;
      else
         Obj.Success := False;
      end if;
      --Pace.Log.Trace (0bj);
   end Inout;

begin
   Set_Current_Reference_Location;
end Gis.Location;
