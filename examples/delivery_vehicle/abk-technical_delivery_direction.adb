with Pace.Log;
with Ahd;
with Hal;
with Nav.Location;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Acu;
with Str;
with Ifc.Fm_Data;
with Sim.Inventory;
with Gis;
with Plant;
with Abk.Time_On_Target;

package body Abk.Technical_Delivery_Direction is

   use Str;
   use Ada.Numerics;
   use Ada.Numerics.Elementary_Functions;
   use Ahd;
   use Ifc.Fm_Data.Item_Vector;

   function Get_Azimuth (Target_Easting, Target_Northing : Float) return Float is
      Target_Heading : Float; -- orientation that vehicle must be at to point directly at target
      Vehicle_Heading : Float := Acu.Heading;
      Target_Coord : Gis.Utm_Coordinate;
      Azimuth : Float;
   begin
      Target_Coord.Northing := Target_Northing;
      Target_Coord.Easting := Target_Easting;
      declare
         Msg : Nav.Location.Get_Data;
      begin
         Pace.Dispatching.Output (Msg);
         Target_Heading := Gis.Heading_C2_From_C1 (Msg.Coordinate, Target_Coord);
      end;
      Pace.Log.Put_Line ("target_heading is " & Float'Image (Hal.Degs (Target_Heading)), 8);
      Pace.Log.Put_Line ("vehicle_heading is " & Float'Image (Hal.Degs (Vehicle_Heading)), 8);

      -- find the smaller difference between the two headings
      if abs (Target_Heading - Vehicle_Heading) > Pi then
         Azimuth := 2.0 * Pi - abs (Target_Heading - Vehicle_Heading);
      else
         Azimuth := abs (Target_Heading - Vehicle_Heading);
      end if;

      -- determine whether the target is to the left or right of vehicle
      if (Vehicle_Heading > Target_Heading and
          ((Vehicle_Heading >= 0.0 and Target_Heading >= 0.0) or
           (Vehicle_Heading <= 0.0 and Target_Heading <= 0.0))) or
         (Target_Heading <= 0.0 and Vehicle_Heading >= 0.0 and
          (Vehicle_Heading + abs (Target_Heading) < Pi)) or
         (Target_Heading >= 0.0 and Vehicle_Heading <= 0.0 and
          (abs (Vehicle_Heading) + Target_Heading) > Pi) then

         Azimuth := Azimuth;  -- target is to the left

      else
         Azimuth := -Azimuth;  -- target is to the right
      end if;
      return Azimuth;
   end Get_Azimuth;

   -- assigns a default launchpad_velocity..
   -- item won't hit target, but will use the given el's and az's
   procedure Process_No_Target (Mission : in out Mission_Record) is
   begin
      for I in 1 .. Natural (Length (Mission.Data.Items)) loop
         Mission.Items (I).Launchpad_Velocity := 300.0;
         Mission.Items (I).Elevation := Element (Mission.Data.Items, I).Elevation;
         Mission.Items (I).Azimuth := Element (Mission.Data.Items, I).Azimuth;
         Mission.Items (I).Delivery_Time := 0.0;
      end loop;
   end Process_No_Target;

   procedure Process_To_Hit_Target_On_Time (Mission : in out Mission_Record) is
      Num_Items : Integer :=  Natural (Length (Mission.Data.Items));
      Target_Locations : Abk.Time_On_Target.Coord_Arr (1 .. Num_Items);
      Possible_Velocities : Abk.Time_On_Target.Float_Arr (Plant.Charge_Range);
      Box_Kind : Bstr.Bounded_String;

      -- returns the index of velocity in possible_velocities
      function Get_Num_Charges (Velocity : Float) return Integer is
      begin
         for I in Possible_Velocities'Range loop
            if Possible_Velocities (I) = Velocity then
               return I;
            end if;
         end loop;
         return 0;  -- default
      end Get_Num_Charges;

   begin

      -- get target locations into correct data type
      Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!!!! DOING TARGET LOCATION!!!!!!!!!!!!!");
      for I in Target_Locations'Range loop
         Target_Locations (I) := Element (Mission.Data.Items, I).Target;
      end loop;

      -- get the possible velocities
      Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!!!! DOING VELOCITIES !!!!!!!!!!!!!");
      -- assume the box type is the same for each item
      Box_Kind := Element (Mission.Data.Items, 1).Box;
      for I in Possible_Velocities'Range loop
         Possible_Velocities (I) :=
           Sim.Inventory.Get_Launchpad_Velocity (B2s(Box_Kind),
                                              Plant.Charge_Range (I));
      end loop;

      declare
         Msg : Abk.Time_On_Target.Find_Tot_Solution (Num_Items, Possible_Velocities'Length);
      begin
         Msg.Target_Locations := Target_Locations;
         Msg.Possible_Velocities := Possible_Velocities;
         Msg.Delta_Time_Constraint := Plant.Time_Between_Items;
         Msg.Min_Theta_Constraint := Hal.Rads (Plant.Min_Elevation_Angle);
         Msg.Max_Theta_Constraint := Hal.Rads (Plant.Max_Elevation_Angle);
         Pace.Dispatching.Inout (Msg);

         if Msg.Success then
            -- fill in the solution
            Mission.Within_Range := True;
            for I in 1 .. Natural (Length (Mission.Data.Items)) loop
               Mission.Items (I).Elevation := Hal.Degs (Msg.Solution (I).Theta);
               Mission.Items (I).Launchpad_Velocity := Msg.Solution (I).Velocity;
               declare
                  Num_Charges : Integer := Get_Num_Charges (Msg.Solution (I).Velocity);
               begin
                  Mission.Items (I).Num_Charges := Num_Charges;
                  Ifc.Fm_Data.Set_Zoning (Mission.Data.Id, I, Num_Charges);
               end;

               -- the on_target_time is relative to the start of the mission,
               -- but delivery_time is relative to the start of the simulation
               Mission.Items (I).Delivery_Time := Mission.Data.Start_Time +
                 Element (Mission.Data.Items, I).On_Target_Time - Msg.Solution (I).Time_Of_Flight;

               -- assign correct azimuth
               Mission.Items (I).Azimuth :=
                 Hal.Degs (Get_Azimuth (Msg.Target_Locations (I).Easting,
                                        Msg.Target_Locations (I).Northing));

               Pace.Log.Put_Line ("item " & Integer'Image (I), 4);
               Pace.Log.Put_Line ("velocity is " &
                                  Float'Image (Mission.Items (I).Launchpad_Velocity), 4);
               Pace.Log.Put_Line ("elevation is " &
                                  Float'Image (Mission.Items (I).Elevation), 4);
               Pace.Log.Put_Line ("azimuth is " & Float'Image (Mission.Items (I).Azimuth) & "(degrees)", 4);
               Pace.Log.Put_Line ("delivery time is " & Duration'Image (Mission.Items (I).Delivery_Time), 4);


            end loop;

         else
            -- if there is no solution then halt the mission
            Mission.Within_Range := False;
            Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!!! Time On Target Solution is not possible !!!!!!!!!!!");
         end if;
      end;

   end Process_To_Hit_Target_On_Time;

   -- assigns launchpad velocity, charge_num, delivery_time, elevation, and azimuth in order
   -- to hit the target
   -- assumes inventory supply exists
   procedure Process_To_Hit_Target (Mission : in out Mission_Record) is

      Easting, Northing : Float;
      Vertical_Distance, Horizontal_Distance : Float;
      Box_Kind : Bstr.Bounded_String;
   begin
      -- calculate elevation, velocity, charge_nums and delivery_time for each item
      for I in 1 .. Natural (Length (Mission.Data.Items)) loop
         Easting := Element (Mission.Data.Items, I).Target.Easting;
         Northing := Element (Mission.Data.Items, I).Target.Northing;
         Horizontal_Distance := Get_Horizontal_Distance (Easting, Northing);
         Pace.Log.Put_Line ("horizontal distance is " & Float'Image (Horizontal_Distance), 8);
         Vertical_Distance := Get_Vertical_Distance (Easting, Northing);
         Pace.Log.Put_Line ("vertical distance is " & Float'Image (Vertical_Distance), 8);

         Box_Kind := Element (Mission.Data.Items, I).Box;
         Mission.Within_Range := False;

         -- each time through loop check to see if item can hit target in given zone
         -- if it can then exit loop.. so the lowest zone possible will be used
         -- in order to hit the target
         for Zone in 1 .. 4 loop
            declare
               Velocity : Float := Sim.Inventory.Get_Launchpad_Velocity (B2s(Box_Kind),
                                                                      Plant.Charge_Range (Zone));
               Elevation : Float;
               Success : Boolean;
            begin
               Pace.Log.Put_Line ("horizontal distance is " & Horizontal_Distance'Img & " and vertical_distance is " & Vertical_Distance'Img & " and velocity is " & Velocity'Img, 8);
               Elevation_Calculation (Velocity, Horizontal_Distance, Vertical_Distance, Success, Elevation);
               if Success then
                  Mission.Items (I).Elevation := Hal.Degs (Elevation);
                  Mission.Items (I).Launchpad_Velocity := Velocity;
                  Mission.Items (I).Num_Charges := Zone;
                  Ifc.Fm_Data.Set_Zoning (Mission.Data.Id, I, Zone);
                  Mission.Within_Range := True;
                  exit;  -- found a solution, so exit loop
               end if;
            end;
         end loop;

         if Mission.Within_Range = False then
            Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!!! Mission is not within range!!!!!!!!!!!");
            exit;  -- exit the loop since mission won't be ran
         end if;

         Pace.Log.Put_Line ("item " & Integer'Image (I), 8);
         Pace.Log.Put_Line ("velocity is " &
                                          Float'Image (Mission.Items (I).Launchpad_Velocity), 8);
         Pace.Log.Put_Line ("elevation is " &
                                           Float'Image (Mission.Items (I).Elevation), 8);

         -- this is not a time on target mission, so set delivery_time to 0.0
         Mission.Items (I).Delivery_Time := 0.0;

         -- assign correct azimuth
         declare
            Azimuth : Float := Hal.Degs (Get_Azimuth (Easting, Northing));
         begin
            Mission.Items (I).Azimuth := Azimuth;
         end;

         Pace.Log.Put_Line ("item " & Integer'Image (I), 4);
         Pace.Log.Put_Line ("velocity is " &
                            Float'Image (Mission.Items (I).Launchpad_Velocity), 4);
         Pace.Log.Put_Line ("elevation is " &
                            Float'Image (Mission.Items (I).Elevation), 4);
         Pace.Log.Put_Line ("azimuth is " & Float'Image (Mission.Items (I).Azimuth), 4);
      end loop;

   end Process_To_Hit_Target;

   procedure Calculate_Vel_And_Az (Mission : in out Mission_Record) is
      use Bstr;
   begin
      if Ifc.Fm_Data.Has_Target (Mission.Data) then
         if Bstr.To_String (Mission.Data.Control) = "Time On Target" then
            Pace.Log.Put_Line ("processing target_on_time", 4);
            Process_To_Hit_Target_On_Time (Mission);
         else
            Pace.Log.Put_Line ("processing target", 4);
            Process_To_Hit_Target (Mission);
         end if;
      else
         Pace.Log.Put_Line ("processing no target", 4);
         Process_No_Target (Mission);
      end if;
   end Calculate_Vel_And_Az;


   procedure Input (Obj : in Calculate_Flight_Solution) is
   begin
      Pace.Log.Wait (0.2);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Inout (Obj : in out Perform_Technical_Delivery_Direction) is
   begin
      -- mission's do not always start at the preplanned time, and we
      -- need to refer to when the mission really starts since time
      -- on target times are relative to start of mission
      Obj.Mission.Data.Start_Time := Pace.Now;
      Calculate_Vel_And_Az (Obj.Mission);  -- should this be in calculate_flight_solution??
      Pace.Log.Wait (3.0);
      Pace.Log.Trace (Obj);
   exception
      when E: others =>
         Pace.Log.Ex (E);
         Pace.Log.Put_Line
           ("Exception during Preprocessing of Mission !!!!!!!!!!!!!!!!");
   end Inout;

end Abk.Technical_Delivery_Direction;
