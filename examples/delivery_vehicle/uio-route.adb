with Ada.Strings.Unbounded;

with Pace.Log;
with Pace.Server.Dispatch;
with Pace.Server.Kbase_Utilities;
with Pace.Server.Xml;
with Pace.Surrogates;
with Pace.Jobs;
with Pace;

with Gis;
with Ual.Utilities;
-- with Gnu.Fields;
with Gnu.Rule_Process;
with Hal.Audio.Mixer;
with Str;

with Uio.Dbw;
with Vkb;
with Plant;
with Nav.Location;
with Nav.Move_Plan;
with Nav.Route_Following;
with Ifc.Fm_Data;

package body Uio.Route is

   function Id is new Pace.Log.Unit_Id;

   use Str;

   package Asu renames Ada.Strings.Unbounded;

   Route_Xml : Asu.Unbounded_String;

   Is_Route_Loaded : Boolean := False;

   -- static vars for get_move_plan_xml
   Current_Mp_Id : Str.Bstr.Bounded_String;
   Dest_Type : Str.Bstr.Bounded_String;
   Max_Dist_From_Corridor : Integer;

   type List_Move_Plans is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out List_Move_Plans);
   procedure Inout (Obj : in out List_Move_Plans) is
      use Gnu.Rule_Process;
      use Pace.Server.Xml;
      use Pace.Server.Kbase_Utilities;
      V : Variables (1 .. 2);
   begin
      Vkb.Agent.Query ("get_mp_list", V);
      declare
         Lists : List_Key_Array (1 .. 2);
         Move_Plan_Xml : Asu.Unbounded_String;
      begin
         Lists (1) := (V (1), S2u("name"));
         Lists (2) := (V (2), S2u("dest_type"));
         Move_Plan_Xml := S2u(Lists_To_Xml (Lists => Lists,
                                         Delimiter => Ascii.Ht,
                                         Xml_Tag => "move_plan"));

         Put_Content (Default_Stylesheet => "/eng/move/nav-mp_list.xsl");
         Pace.Server.Put_Data (Item ("move_plan_list", U2s(Move_Plan_Xml)));
      end;
      Pace.Log.Trace (Obj);
   exception
      when No_Match =>
         Pace.Log.Put_Line ("Query for Move Plan List has failed!");
   end Inout;

   function Get_East_North_Xml
              (Index : Integer; East : Float; North : Float) return String is
      use Pace.Server.Xml;
      Result : Asu.Unbounded_String;
   begin
      Asu.Append (Result, Item (Element => "n", Value => Index));
      Asu.Append (Result, Item (Element => "easting", Value => Str.Trim (East)));
      Asu.Append (Result, Item (Element => "northing", Value => Str.Trim (North)));
      return Asu.To_String (Result);
   end Get_East_North_Xml;

   procedure Add_Customer_Point (Fm_Id : in String) is
      Job : Ifc.Fm_Data.Delivery_Job_Data;
      Found_It : Boolean;
   begin
      Ifc.Fm_Data.Get_Delivery_Job (S2b(Fm_Id), Found_It, Job);
      if not Found_It then
         Pace.Log.Put_Line ("Delivery Job " & Fm_Id & " could not be found!");
         raise Vkb.Rules.No_Match;
      end if;

      declare
         use Gis;
         Msg : Nav.Route_Following.Add_Point;
      begin
         Msg.Index := 1;
         -- use the first customer as the one to emplace by
         Msg.Point.Coord := Ifc.Fm_Data.Item_Vector.Element (Job.Items, 1).Customer;
         Msg.Heading_restriction := Plant.Max_Traverse_Angle;
         Msg.Point.Kind := Tp;

         -- determine heading for emplacement
         declare
            Msg2 : Nav.Location.Track_Heading;
         begin
            Msg2.Target_Northing := Msg.Point.Coord.Northing;
            Msg2.Target_Easting := Msg.Point.Coord.Easting;
            Pace.Dispatching.Inout (Msg2);
            Msg.Heading := Msg2.Heading;    -- heading for emplacing
         end;
         Pace.Dispatching.Input (Msg);
         Asu.Append (Route_Xml,
                     Pace.Server.Xml.Item (Element => "point",
                                           Value => Get_East_North_Xml (1,
                                                                        Msg.Point.Coord.Easting,
                                                                        Msg.Point.Coord.Northing)));
         Route_Xml := Asu.To_Unbounded_String
           (Pace.Server.Xml.Item
            (Element => "datapoints",
             Value => Asu.To_String (Route_Xml)));
      end;
   end Add_Customer_Point;

   procedure Add_Points (Route_Name : in Bstr.Bounded_String) is
      use Pace.Server.Xml;
      use Nav.Move_Plan;
      use Nav.Move_Plan.Checkpoint_Vector;
      Index : Integer := 1;
      Mp_Data : Move_Plan_Data;
      Found_It : Boolean;
   begin
      Current_Mp_Id := Route_Name;
      Nav.Move_Plan.Get_Move_Plan (Route_Name, Found_It, Mp_Data);
      if not Found_It then
         Pace.Log.Put_Line ("Move Plan not found : " & (B2s(Route_Name)));
      else
         Dest_Type := Mp_Data.Plan;
         Max_Dist_From_Corridor := Mp_Data.Max_Corridor;
         for Index in 1 .. Integer (Length (Mp_Data.Points)) loop
            declare
               Msg : Nav.Route_Following.Add_Point;
               Point : Gis.Checkpoint := Element (Mp_Data.Points, Index);
            begin
               Msg.Index := Index;
               Msg.Point := Point;
               Msg.Radius := 100.0;   -- critical radius for within waypoint distance
               Msg.Heading := 0.0;
               Pace.Dispatching.Input (Msg);
               Asu.Append (Route_Xml,
                           Item (Element => "point",
                                 Value => Get_East_North_Xml (Index,
                                                              Point.Coord.Easting,
                                                              Point.Coord.Northing) &
                                 Item (Element => "type",
                                       Value => Point.Kind'Img) &
                                 Item (Element => "zone",
                                       Value => Str.Trim (Point.Coord.Zone_Num))
                                 ));
            end;
         end loop;
         Route_Xml := Asu.To_Unbounded_String
           (Item (Element => "datapoints",
                  Value => Asu.To_String (Route_Xml)));
      end if;
   end Add_Points;

   procedure Route_Load_And_Follow
               (Following_Customer_Point : Boolean := False;
                Plan_Id : Bstr.Bounded_String := S2b("")) is
   begin
      declare
         Msg : Nav.Route_Following.Start;
      begin
         Msg.Index := 1;
         Pace.Dispatching.Input (Msg);
      end;

      loop
         declare
            Msg : Nav.Route_Following.Monitor_Progress;
         begin
            Pace.Dispatching.Inout (Msg);
            if Msg.Reached_Control_Point and not Following_Customer_Point then
               declare
                  Way_Msg : Waypoint_Acknowledge_Signal;
               begin
                  Way_Msg.Plan_Id := Plan_Id;
                  Way_Msg.Waypoint := Natural (Msg.Index);
                  Way_Msg.Ack := False;
                  Pace.Dispatching.Input (Way_Msg);
               end;
            end if;
            exit when Msg.Complete;
            Pace.Log.Put_Line ("Index:" & Integer'Image (Msg.Index), 8);
            -- An audio message occurs when a point is reached and the point is not
            -- a customer point (of type tp for delivery job headings)
            if Msg.Reached_Control_Point and not Following_Customer_Point then
               Hal.Audio.Mixer.Say ("Reached waypoint" &
                                    Integer'Image (Msg.Index - 1));
            end if;
         end;
      end loop;
      Route_Xml := Asu.To_Unbounded_String ("");
      Pace.Log.Put_Line ("DONE", 8);
      if not Following_Customer_Point then
         Hal.Audio.Mixer.Say ("Final waypoint reached.  Move plan finished.");
      end if;
   end Route_Load_And_Follow;

   task Agent is
      entry Load_Route (Plan_Id : in Bstr.Bounded_String);
      entry Inout (Obj : in out Load_Customer);
   end Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         Is_Route_Loaded := False;
         select
            accept Load_Route (Plan_Id : in Bstr.Bounded_String) do
               Add_Points (Plan_Id);
               Is_Route_Loaded := True;
               Route_Load_And_Follow (Following_Customer_Point => False,
                                      Plan_Id => Plan_Id);
            end Load_Route;

         or

            accept Inout (Obj : in out Load_Customer) do
               Add_Customer_Point (Asu.To_String (Obj.Set));
            end Inout;
            Is_Route_Loaded := True;
            Route_Load_And_Follow (Following_Customer_Point => True);
         end select;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   -- the Action taken by a scheduled move plan
   -- input method must end when move plan is done
   type Execute_Move_Plan is new Pace.Msg with
      record
         Plan_Id : Bstr.Bounded_String;
      end record;
   procedure Input (Obj : Execute_Move_Plan);
   procedure Input (Obj : Execute_Move_Plan) is
   begin
      Agent.Load_Route (Obj.Plan_Id);
   end Input;

   use Pace.Server.Dispatch;

   procedure Inout (Obj : in out Load_Route) is
      J : Pace.Jobs.Job;
      A : Execute_Move_Plan;
   begin

      declare
         Mp_Data : Nav.Move_Plan.Move_Plan_Data;
         Found_It : Boolean;
      begin
         -- get the start time
         Nav.Move_Plan.Get_Move_Plan (U2b(Obj.Set), Found_It, Mp_Data);
         if not Found_It then
            Pace.Log.Put_Line ("Move_Plan " & (U2s(Obj.Set)) & " not found in kbase.");
         else
            J.Start_Time := Mp_Data.Start_Time;

            -- create the job and add it to the scheduler
            J.Unique_Id := Bstr.Append ("mp_", Mp_Data.Id);

            J.Expected_Duration := 1000.0; --dummy value for now
            A.Plan_Id := Mp_Data.Id;
            J.Action := Pace.To_Channel_Msg (A);
            Pace.Surrogates.Input (J);
         end if;
      end;

   exception
      when E : others =>
         Pace.Log.Ex (E);
   end Inout;

   procedure Inout (Obj : in out Load_Customer) is
      Job : Ifc.Fm_Data.Delivery_Job_Data;
      Found_It : Boolean;
   begin
      Ifc.Fm_Data.Get_Delivery_Job (U2b(Obj.Set), Found_It, Job);
      -- if there isn't a customer in this job then don't load it!
      if Ifc.Fm_Data.Has_Customer (Job) then
         Agent.Inout (Obj);
      end if;
   end Inout;

   function Get_Route_Status_Xml return String is
      use Pace.Server.Xml;
      use Asu;
      use Gis;
      Result : Asu.Unbounded_String;

      function Create_Time_String (Time : Duration) return String is
         Hours, Minutes, Seconds : String (1 .. 2);
      begin
         if Time = Duration'Last then
            return "";
         else
            Ual.Utilities.Dur_To_Time (Time, Hours, Minutes, Seconds);
            return (Hours & ":" & Minutes & ":" & Seconds);
         end if;
      end Create_Time_String;

      Msg : Nav.Route_Following.Get_Current_Waypoint;
   begin
      if Is_Route_Loaded then
         Pace.Dispatching.Output (Msg);
         Append (Result, Item ("in_progress",
                               Boolean'Image (Msg.Route_In_Progress)));
         Append (Result, Item ("move_plan", B2s(Current_Mp_Id)));
         Append (Result, Item ("dest_type", B2s(Dest_Type)));
         Append (Result, Item ("next_point", Gis.Checkpoint_Type'Image
                               (Msg.Point.Kind)));
         Append (Result, Item ("distance_to_next_point", Msg.Dist_To_Next_Point));
         Append (Result, Item ("time_to_next_point",
                               Create_Time_String (Msg.Time_To_Next_Point)));
         Append (Result, Item ("distance_to_rp", Msg.Dist_To_Last_Point));
         Append (Result, Item ("time_to_rp",
                               Create_Time_String (Msg.Time_To_Last_Point)));
         if Msg.Point.Kind = Sp then
            Append (Result, Item ("distance_from_corridor", ""));
         else
            Append (Result, Item ("distance_from_corridor", Str.Trim (Msg.Distance_From_Corridor)));
         end if;
         Append (Result, Item ("max_distance_from_corridor", Str.Trim (Max_Dist_From_Corridor)));
      end if;
      return Item ("route_status", U2s(Result));
   end Get_Route_Status_Xml;

   function Get_Route_Xml return String is
      use Pace.Server.Xml;
   begin
      return (Item (Element => "route",
                    Value => Uio.Dbw.Get_Loc_Xml & Asu.To_String (Route_Xml)));
   end Get_Route_Xml;

   procedure Inout (Obj : in out Get_Current_Route) is
      use Pace.Server.Xml;
      -- can be overriden using the style cgi parameter.  if no stylesheet
      -- is wanted then set style parameter to empty string
      Default_Stylesheet : String := "/eng/move/nav-image_map.xsl";
   begin
      Put_Content (Default_Stylesheet);
      Obj.Set := S2u(Get_Route_Xml);
      Pace.Server.Put_Data (U2s(Obj.Set));
   end Inout;

   procedure Inout (Obj : in out Update_Move_Plan) is
      use Pace.Server.Xml;
      -- can be overriden using the style cgi parameter.  if no stylesheet
      -- is wanted then set style parameter to empty string
      Default_Stylesheet : String := "/eng/move/nav-route_status.xsl";
   begin
      Put_Content (Default_Stylesheet);
      Obj.Set := S2u(Get_Route_Status_Xml);
      Pace.Server.Put_Data (U2s(Obj.Set));
      Pace.Log.Trace (Obj);
   end Inout;

begin
   Save_Action (Load_Route'(Pace.Msg with Set => S2u("'POC1'")));
   Save_Action (Load_Customer'(Pace.Msg with Set => S2u("(integer template)")));
   Save_Action (List_Move_Plans'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_Current_Route'(Pace.Msg with Set => Xml_Set));
   Save_Action (Update_Move_Plan'(Pace.Msg with Set => Xml_Set));
end Uio.Route;
