
with Pace.Log;
with Pace.Server.Peek_Factory;
with Ada.Numerics.Elementary_Functions;
with Hal;
with Hal.Geometry_And_Trig;

package body Gis.Route_Following is

   use Ada.Numerics.Elementary_Functions;

   North_Pos, East_Pos : Float := 0.0;
   Actual_Heading : Float := 1.0;
   Speed : Float := 0.0;

   function Id is new Pace.Log.Unit_Id;
   function Name return String renames Pace.Log.Name;

   type Sync_State is (Start_State,
                       Monitor_Progress_State
                       );
   My_State : Sync_State := Start_State;
--   function Get_State return String is
--   begin
--      return My_State'Img;
--   end Get_State;
--   package Task_State is new Pace.Server.Peek_Factory (Get_State);

   task Agent is pragma Task_Name (Name);
      entry Input (Obj : in Start);
   end Agent;

   procedure Input (Obj : in Recover) is
   begin
      -- this is a bit different than the other recovers, since
      -- we can't check aho.check_fire from a Common file
      -- so we rely on the continue_following boolean
      declare
         Msg : Stop;
      begin
         Input (Msg);
      end;
      -- Elsewhere it talks about a non-zero "heading_restriction" on the last check-point indicates
      -- that the route isn't officially completed until the route_plan is "stopped"
      -- This is an orientation waypoint if it has a heading_restriction.
      while My_State /= Start_State loop
         Pace.Log.Put_Line ("Stop/Recover GIS.Route_Following state from: " & My_State'Img);
         declare
            Msg : Monitor_Progress;  -- This does not seem important as we just want to stop
         begin                       -- It is possible that we need to drain if Input notify is synched
            Msg.Ack := False;        -- Don't wait if not ready
            Inout (Msg);             -- Drain the output
         end;
         Pace.Log.Wait (0.05);       -- Keep latency minimized for some reason
      end loop;
      Pace.Log.Trace (Obj);
   end Input;

   type Location is
      record
         Point : Checkpoint;
         Heading_Restriction : Float;
         Heading : Float;
         Radius : Float := 100.0;
      end record;

   type Cp_Array is array (1 .. Cp_Range'Last) of Location;

   Route : Cp_Array;
   Points : Cp_Range := 0;
   Continue_Following : Boolean := False;
   Current_Point : Cp_Range := 0;

   Two_Pi : constant := 2.0 * Ada.Numerics.Pi;
   Cp_Skipped : Boolean := False;
   Displacement_Error : Float;
   Corrected_Heading : Float;
   Reached_Control_Point : Boolean := False;

   function Calculate_Distance_To_Cp
              (Cp : in Cp_Range; North, East : in Float) return Float is
      North_Factor, East_Factor : Float;
   begin
      -- Returns straight line distance.to next CP from (North,East)
      North_Factor := (Route (Cp).Point.Coord.Northing - North) ** 2;
      East_Factor := (Route (Cp).Point.Coord.Easting - East) ** 2;
      return Sqrt (North_Factor + East_Factor);
   end Calculate_Distance_To_Cp;

   function Calculate_Distance_To_Rp
              (Cp : in Cp_Range; North, East : in Float) return Float is
      Remaining : Float := 0.0;
   begin
      Remaining := Calculate_Distance_To_Cp (Cp, North, East);
      for I in Cp .. Points - 1 loop
         Remaining := Remaining +
                        Calculate_Distance_To_Cp
                          (I, Route (I + 1).Point.Coord.Northing, Route (I + 1).Point.Coord.Easting);
      end loop;
      return Remaining;
   end Calculate_Distance_To_Rp;

   function Calculate_Corridor_Distance (Current_Point : Cp_Range) return Integer is
      use Hal.Geometry_And_Trig;
      Previous_Waypoint : Two_D_Point := (Route (Current_Point - 1).Point.Coord.Easting,
                                          Route (Current_Point - 1).Point.Coord.Northing);
      Next_Waypoint : Two_D_Point := (Route (Current_Point).Point.Coord.Easting,
                                      Route (Current_Point).Point.Coord.Northing);
      Vehicle_Point : Two_D_Point := (East_Pos, North_Pos);
      Corridor_Distance : Float;
      Intersection_Point : Two_D_Point;  -- dummy
   begin
      Minimum_Distance_Between_Point_And_Line (Previous_Waypoint,
                                               Next_Waypoint,
                                               Vehicle_Point,
                                               Corridor_Distance,
                                               Intersection_Point);
      return Integer (Corridor_Distance);
   end Calculate_Corridor_Distance;

   procedure Output (Obj : out Get_Current_Waypoint) is
      function Get_Time (Distance : Float) return Duration is
      begin
         if Integer (Speed) = 0 then
            return Duration'Last;
         else
            return Duration (Distance / abs Speed);
         end if;
      end Get_Time;
   begin
      Obj.Route_In_Progress := Continue_Following;
      if Continue_Following then
         if Current_Point /= 1 then
            Obj.Distance_From_Corridor := Calculate_Corridor_Distance (Current_Point);
         end if;
         Obj.Corrected_Heading := Corrected_Heading;
         Obj.Point := Route (Current_Point).Point;
         Obj.Dist_To_Last_Point := Calculate_Distance_To_Rp
                                     (Current_Point, North_Pos, East_Pos);
         Obj.Dist_To_Next_Point := Calculate_Distance_To_Cp
                                     (Current_Point, North_Pos, East_Pos);
      else
         Obj.Corrected_Heading := 0.0;
         Obj.Point.Coord.Easting := 0.0;
         Obj.Point.Coord.Northing := 0.0;
         Obj.Point.Kind := Sp;
         Obj.Dist_To_Last_Point := 0.0;
         Obj.Dist_To_Next_Point := 0.0;
      end if;
      Obj.Time_To_Last_Point := Get_Time (Obj.Dist_To_Last_Point);
      Obj.Time_To_Next_Point := Get_Time (Obj.Dist_To_Next_Point);
   end Output;


   procedure Calculate_Correct_Heading (Cp : in Cp_Range) is
      North_Diff, East_Diff : Float;
      North_Dest, East_Dest : Float;
      Desired_Heading : Float;
   begin
      North_Dest := Route (Cp).Point.Coord.Northing;
      East_Dest := Route (Cp).Point.Coord.Easting;
      North_Diff := North_Dest - North_Pos;
      East_Diff := East_Dest - East_Pos;

      if Route (Cp).Heading_Restriction /= 0.0 then
         Desired_Heading := Route (Cp).Heading;
      elsif North_Diff = 0.0 and East_Diff = 0.0 then
         Desired_Heading := Actual_Heading;
      else
         Desired_Heading := Arctan (East_Diff, North_Diff);
      end if;

      -- determine whether this is an orientation waypoint or a positional waypoint
      if Route (Cp).Heading_Restriction /= 0.0 then
         Displacement_Error := abs (Desired_Heading - Actual_Heading);
         Reached_Control_Point :=
           (Displacement_Error <= Hal.Rads (Route (Cp).Heading_Restriction)) or Cp_Skipped;
      else
         Displacement_Error := Sqrt (North_Diff ** 2 + East_Diff ** 2);
         Reached_Control_Point := (Displacement_Error < Route (Cp).Radius) or Cp_Skipped;
      end if;

      -- this comment isn't very COMMON like... but not sure what to do with it
      -- or the code it talks about
      -- the second clause of this if statement is needed so that the route continues
      -- to follow throughout an operation until the crew clears it.. eventually this
      -- may need to be made more robust (currently will break if have multiple waypoints
      -- in an operation, or emplacing for a different reason other than an operation!)
      if Reached_Control_Point and Route (Cp).Heading_Restriction = 0.0 then
         if Current_Point = Points then
            Continue_Following := False;
         else
            Current_Point := Current_Point + 1;
         end if;
      end if;

      Corrected_Heading := (Desired_Heading - Actual_Heading);

      --
      --  Correct heading for nearest orientation
      --
      if Corrected_Heading > Ada.Numerics.Pi then
         Corrected_Heading := Corrected_Heading - Two_Pi;
      elsif Corrected_Heading < -Ada.Numerics.Pi then
         Corrected_Heading := Corrected_Heading + Two_Pi;
      end if;

   exception
      when E: Ada.Numerics.Argument_Error =>
         Pace.Log.Ex (E, "Trig Error?");
   end Calculate_Correct_Heading;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         My_State := Start_State;
         declare
            Msg : Clear_Route;
         begin
            Input (Msg);
         end;
         accept Input (Obj : in Start) do
            Pace.Log.Trace (Obj);
            Continue_Following := True;
            Current_Point := 1;
            My_State := Monitor_Progress_State;
         end Input;
         while Points > 0 loop
            exit when not Continue_Following;
            Pace.Log.Wait (0.5);
            declare
               Msg : Loc.Get_Data;
            begin
               Pace.Dispatching.Output (Msg);
               North_Pos := Msg.Coordinate.Northing;
               East_Pos := Msg.Coordinate.Easting;
               Actual_Heading := Msg.Heading;
               Speed := Msg.Speed;
            end;
            Calculate_Correct_Heading (Current_Point);
            if Do_Monitor_Progress then
               declare
                  Msg : Monitor_Progress;
               begin
                  Msg.Index := Current_Point;
                  Msg.Heading_Correction := Corrected_Heading;
                  Msg.Reached_Control_Point := Reached_Control_Point;
                  Msg.Steer_Correction := Straight;
                  Msg.Complete := not Continue_Following;
                  Input (Msg);
               end;
            end if;
         end loop;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;


   -----------
   -- Clear_Route
   -----------

   procedure Input (Obj : in Clear_Route) is
   begin
      Points := 0;
      Pace.Log.Trace (Obj);
   end Input;

   -----------
   -- Add_Point
   -----------

   procedure Input (Obj : in Add_Point) is
   begin
      Route (Obj.Index) := (Point => Obj.Point,
                            Heading_Restriction => Obj.Heading_Restriction,
                            Heading => Obj.Heading,
                            Radius => Obj.Radius);
      Points := Integer'Max (Obj.Index, Points);
      Pace.Log.Trace (Obj);
   end Input;

   -----------
   -- Start --
   -----------

   procedure Input (Obj : in Start) is
   begin
      select
         Agent.Input (Obj);
      else
         Pace.Log.Put_Line (Pace.Tag (Obj) & " already following route.");
      end select;
   end Input;

   -----------
   -- Stop  --
   -----------

   procedure Input (Obj : in Stop) is
   begin
      Continue_Following := False;
      Pace.Log.Trace (Obj);
   end Input;

   ------------
   -- Update --
   ------------

--    procedure Input (Obj : in Update) is
--    begin
--       North_Pos := Obj.X_Northing;
--       East_Pos := Obj.Y_Easting;
--       Actual_Heading := Obj.Heading_X_To_Y;
--       Speed := Obj.Speed;
--       Pace.Log.Trace (Obj);
--    end Input;

end Gis.Route_Following;
