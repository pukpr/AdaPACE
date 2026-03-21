with Ada.Strings.Unbounded;
with Pbm;
with Mob;
with Acu;
with Ada.Numerics.Elementary_Functions;
with Pace.Strings; use Pace.Strings;
with Gnu.Jif;
with Nav.Location;
with Pace.Log;
with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Uio.Kbase;
with Vkb.Db;
with Nav.Route_Following;
with Uio.Timekeeper;

package body Uio.Dbw is

   use Pace.Server.Dispatch;

   package Asu renames Ada.Strings.Unbounded;

   type Accelerate is new Action with null record;
   procedure Inout (Obj : in out Accelerate);
   procedure Inout (Obj : in out Accelerate) is
      Msg : Acu.Vehicle.Accelerator_Control;
   begin
      Msg.Rate := Float'Value (+Obj.Set);
      Pace.Dispatching.Input (Msg);
      Pace.Log.Trace (Obj);
   end Inout;

   type Steer is new Action with null record;
   procedure Inout (Obj : in out Steer);
   procedure Inout (Obj : in out Steer) is
      Msg : Acu.Vehicle.Steering_Control;
   begin
      Msg.Rate := Float'Value (+Obj.Set);
      Pace.Dispatching.Input (Msg);
      Pace.Log.Trace (Obj);
   end Inout;

   Current_Gear : Mob.Drive_Mode_Type := Mob.Neutral;

   type Gear is new Action with null record;
   procedure Inout (Obj : in out Gear);
   procedure Inout (Obj : in out Gear) is
      Msg : Acu.Vehicle.Transmission_Control;
   begin
      Current_Gear := Mob.Drive_Mode_Type'Value (+Obj.Set);
      Msg.Mode := Current_Gear; -- Acu.Drive_Mode_Type'Value (+Obj.Set);
      Pace.Dispatching.Input (Msg);
      Pace.Server.Put_Data ("Gear: " &
                            Mob.Drive_Mode_Type'Image (Current_Gear));
      Pace.Log.Trace (Obj);
   end Inout;

   Current_Engine_On : Boolean := False;

   procedure Inout (Obj : in out Start_Engine) is
   begin
      if Current_Engine_On then
         Pace.Server.Put_Data ("Engine is already running");
      else
         Current_Engine_On := True;
         declare
            Msg : Uio.Timekeeper.Reset_Time;
         begin
            Pace.Dispatching.Input (Msg);
         end;
         declare
            Msg : Acu.Vehicle.Start_Engine;
         begin
            Pace.Dispatching.Input (Msg);
         end;
         declare
            Msg : Nav.Location.Init;
         begin
            Pace.Dispatching.Input (Msg);
         end;
         Pace.Server.Put_Data ("Started engine and initialized clock");
      end if;
      Pace.Log.Trace (Obj);
   end Inout;

   Pitch_Roll_Threshold : Float;
   function Get_Loc_Xml return String is
      use Ada.Numerics.Elementary_Functions;
      use Asu;
      use Pace.Server.Xml;
      Msg : Nav.Location.Get_Data;
      Waypoint_Msg : Nav.Route_Following.Get_Current_Waypoint;
      Str : Unbounded_String;
   begin
      Pace.Dispatching.Output (Msg);
      Pace.Dispatching.Output (Waypoint_Msg);
      Append (Str, Item ("easting", Msg.Coordinate.Easting) &
                     Item ("northing", Msg.Coordinate.Northing) &
                     Item ("zone", Msg.Coordinate.Zone_Num) &
                     Item ("hemisphere", Msg.Coordinate.Hemisphere'Img) &
                     Item ("heading", Msg.Heading) &
                     Item ("pitch", Msg.Pitch) & Item ("roll", Msg.Roll) &
                     Item ("pitch_roll_threshold", Pitch_Roll_Threshold) &
                     Item ("sin_heading", Sin (Msg.Heading)) &
                     Item ("cos_heading", Cos (Msg.Heading)) &
                     Item ("way_heading", Msg.Heading +
                                            Waypoint_Msg.Corrected_Heading) &
                     Item ("sin_way_heading",
                           Sin (Msg.Heading + Waypoint_Msg.Corrected_Heading)) &
                     Item ("cos_way_heading",
                           Cos (Msg.Heading + Waypoint_Msg.Corrected_Heading)) &
                     Item ("speed", abs (Msg.Speed * Pbm.Ms_To_Kph_Factor)));
      return Item (Element => "location", Value => To_String (Str));
   end Get_Loc_Xml;

   type Get_Location is new Action with null record;
   procedure Inout (Obj : in out Get_Location);
   procedure Inout (Obj : in out Get_Location) is
      use Pace.Server.Xml, Pace.Server.Dispatch;
      -- can be overriden using the style cgi parameter.  if no stylesheet
      -- is wanted then set style parameter to empty string
      Default_Stylesheet : String := "/eng/move/nav-location.xsl";
   begin
      Put_Content (Default_Stylesheet);
      Obj.Set := +Get_Loc_Xml;
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

--    procedure Output (Obj : out Get_Location_Xml) is
--       use Pace.Server.Xml;
--    begin
--       Obj.Location_Xml := Asu.To_Unbounded_String (Get_Loc_Xml);
--       Pace.Log.Trace (Obj);
--    end Output;


   function Calculate_Fuel_Percentage return Integer is
      Msg : Acu.Vehicle.Get_Fuel_Status;
      Total_Fuel : Float;
   begin
      Pace.Dispatching.Output (Msg);
      Total_Fuel := Msg.Fuel_Cell_Fuel_Levels (1) +
                      Msg.Fuel_Cell_Fuel_Levels (2) +
                      Msg.Fuel_Cell_Fuel_Levels (3);
      return Integer (100.0 * Total_Fuel / 3.0);
   end Calculate_Fuel_Percentage;

   type Get_Fuel is new Action with null record;
   procedure Inout (Obj : in out Get_Fuel);
   procedure Inout (Obj : in out Get_Fuel) is
      use Pace.Server.Xml;
   begin
      Obj.Set := +(Integer'Image (Calculate_Fuel_Percentage));
      Pace.Log.Trace (Obj);
   end Inout;

   function Create_Trans_Status_Xml return String is
      use Pace.Server.Xml;
      use Asu;
      Msg : Acu.Vehicle.Get_Trans_Status;
      Xml : Asu.Unbounded_String;
   begin
      Pace.Dispatching.Output (Msg);
      Xml := +Begin_Doc ("trans_status");
      Append (Xml, Item ("gear", Mob.Drive_Mode_Type'Image (Msg.Drive_Mode)) &
                     End_Doc ("trans_status"));
      return Asu.To_String (Xml);
   end Create_Trans_Status_Xml;

   type Get_Trans_Status is new Action with null record;
   procedure Inout (Obj : in out Get_Trans_Status);
   procedure Inout (Obj : in out Get_Trans_Status) is
   begin
      Pace.Server.Xml.Put_Content ("");
      Pace.Server.Put_Data (Create_Trans_Status_Xml);
      Pace.Log.Trace (Obj);
   end Inout;

   function Create_Engine_Status_Xml return String is
      use Pace.Server.Xml;
      use Asu;
      Msg : Acu.Vehicle.Get_Engine_Status;
      Xml : Asu.Unbounded_String;
   begin
      Pace.Dispatching.Output (Msg);
      if Msg.Engine_Running then
         Xml := +Begin_Doc ("engine_status", "running='running'");
      else
         Xml := +Begin_Doc ("engine_status", "running='not running'");
      end if;
      Append (Xml, Item ("engine_running", Boolean'Image (Msg.Engine_Running)) &
                     Item ("coolant_temperature",
                           Integer (100.0 * Msg.Engine_Coolant_Temperature)) &
                     Item ("coolant_level",
                           Integer (100.0 * Msg.Engine_Coolant_Level)) &
                     Item ("oil_level", Integer
                                          (100.0 * Msg.Engine_Oil_Level)) &
                     Item ("oil_temperature",
                           Integer (100.0 * Msg.Engine_Oil_Temperature)) &
                     Item ("rpm", Integer (100.0 * Msg.Engine_Rpm /
                                           Acu.Eng.Max_Rpm)) &
                     End_Doc ("engine_status"));
      return Asu.To_String (Xml);
   end Create_Engine_Status_Xml;

   type Get_Engine_Status is new Action with null record;
   procedure Inout (Obj : in out Get_Engine_Status);
   procedure Inout (Obj : in out Get_Engine_Status) is
      Default_Stylesheet : String := "/eng/move/driving-engine_status.xsl";
   begin
      Pace.Server.Xml.Put_Content (Default_Stylesheet);
      Pace.Server.Put_Data (Create_Engine_Status_Xml);
      Pace.Log.Trace (Obj);
   end Inout;


   function Create_Move_Status_Xml return String is
      Xml : Asu.Unbounded_String;
      use Asu;
      use Pace.Server.Xml;
   begin
      Xml := +Begin_Doc ("move_status");

      declare
         Msg : Acu.Vehicle.Get_Trans_Status;
      begin
         Pace.Dispatching.Output (Msg);
         Append (Xml, Item ("odometer", Msg.Odometer) &
                      Item ("trip", Msg.Tripmeter) &
                      Item ("speed", Integer (Msg.Speed *
                                              Pbm.Ms_To_Kph_Factor)));
      end;

      declare
         Msg : Nav.Location.Get_Data;
      begin
         Pace.Dispatching.Output (Msg);
         Append (Xml, Item ("heading", Msg.Heading));
      end;

      declare
         Msg : Acu.Vehicle.Get_Fuel_Status;
      begin
         Pace.Dispatching.Output (Msg);
         Append (Xml, Item ("fuel", Calculate_Fuel_Percentage));
      end;

      declare
         Msg : Acu.Vehicle.Get_Battery_Status;
      begin
         Pace.Dispatching.Output (Msg);
         Append (Xml, Item ("battery", Integer (100.0 * Msg.Battery_Charge)));
      end;

      Append (Xml, End_Doc ("move_status"));
      return Asu.To_String (Xml);
   end Create_Move_Status_Xml;

   -- includes heading, speed, fuel, odometer, battery charge
   type Get_Move_Status is new Action with null record;
   procedure Inout (Obj : in out Get_Move_Status);
   procedure Inout (Obj : in out Get_Move_Status) is
      Default_Stylesheet : String := "/eng/move/driving-gauges.xsl";
   begin
      Pace.Server.Xml.Put_Content (Default_Stylesheet);
      Pace.Server.Put_Data (Create_Move_Status_Xml);
      Pace.Log.Trace (Obj);
   end Inout;

--    procedure Output (Obj : out Get_All_Gauges_Xml) is
--       use Pace.Server.Xml;
--       use Asu;
--    begin
--       Obj.All_Gauges_Xml := Asu.To_Unbounded_String
--                               (Begin_Doc ("gauges") & Create_Engine_Status_Xml &
--                                Create_Move_Status_Xml & End_Doc ("gauges"));
--       Pace.Log.Trace (Obj);
--    end Output;

   -- puts xml data for all gauges related to driving
   procedure Inout (Obj : in out Get_All_Gauges) is
      use Pace.Server.Xml;
      Default_Stylesheet : String := "/eng/move/driving-gauges.xsl";
   begin
      Put_Content (Default_Stylesheet);
--       Pace.Server.Put_Data (Begin_Doc ("gauges"));
--       declare
--          Msg : Get_Engine_Status;
--       begin
--          Pace.Dispatching.Inout (Msg);
--       end;
--       declare
--          Msg : Get_Move_Status;
--       begin
--          Pace.Dispatching.Inout (Msg);
--       end;
--       Pace.Server.Put_Data (End_Doc ("gauges"));
      Obj.Set := +Item ("gauges",
                        Create_Engine_Status_Xml & Create_Move_Status_Xml);
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

   type Get_Rpm is new Action with null record;
   procedure Inout (Obj : in out Get_Rpm);
   procedure Inout (Obj : in out Get_Rpm) is
      Msg : Acu.Vehicle.Get_Engine_Status;
      Rpm : Integer;
   begin
      Pace.Dispatching.Output (Msg);
      Rpm := Integer (100.0 * Msg.Engine_Rpm / Acu.Eng.Max_Rpm);
      Obj.Set := +(Integer'Image (Rpm));
      Pace.Log.Trace (Obj);
   end Inout;

   -- a template replace
   type Get_Battery_Charge is new Action with null record;
   procedure Inout (Obj : in out Get_Battery_Charge);
   procedure Inout (Obj : in out Get_Battery_Charge) is
      Msg : Acu.Vehicle.Get_Battery_Status;
      Battery_Charge : Integer;
   begin
      Pace.Dispatching.Output (Msg);
      Battery_Charge := Integer (100.0 * Msg.Battery_Charge);
      Obj.Set := +(Integer'Image (Battery_Charge));
      Pace.Log.Trace (Obj);
   end Inout;

   type Get_Speed is new Action with null record;
   procedure Inout (Obj : in out Get_Speed);
   procedure Inout (Obj : in out Get_Speed) is
      Msg : Nav.Location.Get_Data;
      Speed : Integer;
   begin
      Pace.Dispatching.Output (Msg);
      Speed := Integer (100.0 * abs (Msg.Speed) / Acu.Phys.Max_Velocity);
      Obj.Set := +(Integer'Image (Speed));
      Pace.Log.Trace (Obj);
   end Inout;

   type Get_Main_Page is new Action with null record;
   procedure Inout (Obj : in out Get_Main_Page);
   procedure Inout (Obj : in out Get_Main_Page) is
   begin
      Uio.Kbase.Get_File (Obj);
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

   procedure Draw_Compass (Heading : in Float; Finish : in Boolean) is
      use Uio.Kbase;
      G : constant Img.Rgb := (0, 255, 0);
      B : constant Img.Rgb := (0, 0, 255);
      R : constant Img.Rgb := (255, 0, 0);
      Pic : Stored_Image (100, 100);
      Green : Img.Color := Image_Color_Allocate (Pic, G);
      Blue : Img.Color := Image_Color_Allocate (Pic, B);
      -- Red : Img.Color := Image_Color_Allocate(Pic, R);
      use Ada.Numerics.Elementary_Functions;
      X, Y : Float;
   begin
      Image_Color_Transparent (Pic, Green);
      X := 50.0 * (1.0 + Sin (Heading));
      Y := 50.0 * (1.0 - Cos (Heading));
      Image_Line (Pic, (50, 50), (Integer (X), Integer (Y)), Blue);
      Uio.Kbase.Serve_Image (Pic, Finish);
   end Draw_Compass;

   type Compass is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Compass);

   procedure Inout (Obj : in out Compass) is
      Heading : Float;
   begin
      Pace.Server.Push_Content;
      Pace.Log.Trace (Obj);
      loop
         declare
            Msg : Nav.Location.Get_Data;
         begin
            Pace.Dispatching.Output (Msg);
            Heading := Msg.Heading;
         end;
         Draw_Compass (Heading => Heading, Finish => False);
         pace.log.wait(1.0);
      end loop;
   end Inout;

   package Map is
      use Uio.Kbase;
      G : constant Img.Rgb := (0, 255, 0);
      B : constant Img.Rgb := (0, 0, 255);
      R : constant Img.Rgb := (255, 0, 0);
      Pic : Stored_Image (100, 100);
      Green : Img.Color := Image_Color_Allocate (Pic, G);
      Blue : Img.Color := Image_Color_Allocate (Pic, B);
   end Map;

   procedure Draw_Map (X, Y : in Float; Finish : in Boolean) is
      use Uio.Kbase;
      E, N : Integer;
   begin
      E := 50 + Integer (Y / 100.0);
      N := 50 - Integer (X / 100.0); -- Up is negative on coordinate system
      Image_Set_Pixel (Map.Pic, (E, N), Map.Blue);
      Uio.Kbase.Serve_Image (Map.Pic, Finish);
   end Draw_Map;

   type Grid_Location is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Grid_Location);
   procedure Inout (Obj : in out Grid_Location) is
      X, Y : Float;
      use Uio.Kbase;
   begin
      Pace.Server.Push_Content;
      Pace.Log.Trace (Obj);
      loop
         X := Acu.North;
         Y := Acu.East;
         Draw_Map (X => X, Y => Y, Finish => False);
         pace.log.wait(1.0);
      end loop;
   end Inout;

   Joystick_Steering : Float := 0.0;
   Joystick_Acceleration : Float := 0.0;

   type Joystick is new Action with null record;
   procedure Inout (Obj : in out Joystick);
   procedure Inout (Obj : in out Joystick) is
   begin
      declare
         Msg : Acu.Vehicle.Steering_Control;
      begin
         Msg.Rate := Pace.Server.Keys.Value ("x", 1.0);
         Joystick_Steering := Msg.Rate;
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Acu.Vehicle.Accelerator_Control;
      begin
         Msg.Rate := Pace.Server.Keys.Value ("y", 1.0);
         Joystick_Acceleration := Msg.Rate;
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Inout;

   type Get_Joystick_Acceleration is new Action with null record;
   procedure Inout (Obj : in out Get_Joystick_Acceleration);
   procedure Inout (Obj : in out Get_Joystick_Acceleration) is
   begin
      Obj.Set := +Trim (Joystick_Acceleration);
      Pace.Log.Trace (Obj);
   end Inout;

   type Get_Joystick_Steering is new Action with null record;
   procedure Inout (Obj : in out Get_Joystick_Steering);
   procedure Inout (Obj : in out Get_Joystick_Steering) is
   begin
      Obj.Set := +Trim (Joystick_Steering);
      Pace.Log.Trace (Obj);
   end Inout;

   type Get_Gear is new Action with null record;
   procedure Inout (Obj : in out Get_Gear);
   procedure Inout (Obj : in out Get_Gear) is
      Values : array (Boolean) of String (1 .. 4) := ("OFF ", "ON  ");
   begin
      Obj.Set := +("Engine is " & Values (Current_Engine_On) &
                   "in gear " & Mob.Drive_Mode_Type'Image (Current_Gear));
      Pace.Log.Trace (Obj);
   end Inout;

   type Tripmeter_Reset is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Tripmeter_Reset);
   procedure Inout (Obj : in out Tripmeter_Reset) is
      Msg : Acu.Vehicle.Reset_Trip;
   begin
      Pace.Dispatching.Input (Msg);
      Pace.Log.Trace (Obj);
   end Inout;

begin
   Save_Action (Accelerate'(Pace.Msg with Set => +"1.0"));
   Save_Action (Steer'(Pace.Msg with Set => +"0.0"));
   Save_Action (Gear'(Pace.Msg with Set => +"FORWARD"));
   Save_Action (Start_Engine'(Pace.Msg with Set => +""));
   Save_Action (Get_Location'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_Fuel'(Pace.Msg with Set => +"(integer template)"));
   Save_Action (Get_Move_Status'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_All_Gauges'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_Engine_Status'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_Trans_Status'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_Rpm'(Pace.Msg with Set => +"(integer template)"));
   Save_Action (Get_Battery_Charge'
                (Pace.Msg with Set => +"(integer template)"));
   Save_Action (Get_Speed'(Pace.Msg with Set => +"(integer template)"));
   Save_Action (Get_Main_Page'(Pace.Msg with Set => Default));
   Save_Action (Compass'(Pace.Msg with Set => Default));
   Save_Action (Joystick'(Pace.Msg with Set => Default));
   Save_Action (Grid_Location'(Pace.Msg with Set => Default));
   Save_Action (Get_Joystick_Acceleration'
                (Pace.Msg with Set => +"(integer template)"));
   Save_Action (Get_Joystick_Steering'
                (Pace.Msg with Set => +"(integer template)"));
   Save_Action (Get_Gear'(Pace.Msg with Set => +"(string template)"));
   Save_Action (Tripmeter_Reset'(Pace.Msg with Set => Default));

   begin
      Pitch_Roll_Threshold := Vkb.Db.Get ("pitch_roll_threshold");
   exception
      when Vkb.Db.No_Match =>
         Pace.Log.Put_Line ("! missing dbw config");
   end;

end Uio.Dbw;
