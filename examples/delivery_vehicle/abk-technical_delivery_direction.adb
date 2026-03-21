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
with Abk.Time_On_Customer;

package body Abk.Technical_Delivery_Direction is

   use Str;
   use Ada.Numerics;
   use Ada.Numerics.Elementary_Functions;
   use Ahd;
   use Ifc.Fm_Data.Item_Vector;

   function Get_Azimuth (Target_Easting, Target_Northing : Float) return Float is
      Customer_Heading : Float; -- orientation that vehicle must be at to point directly at customer
      Vehicle_Heading : Float := Acu.Heading;
      Customer_Coord : Gis.Utm_Coordinate;
      Azimuth : Float;
   begin
      Customer_Coord.Northing := Target_Northing;
      Customer_Coord.Easting := Target_Easting;
      declare
         Msg : Nav.Location.Get_Data;
      begin
         Pace.Dispatching.Output (Msg);
         Customer_Heading := Gis.Heading_C2_From_C1 (Msg.Coordinate, Customer_Coord);
      end;
      Pace.Log.Put_Line ("customer_heading is " & Float'Image (Hal.Degs (Customer_Heading)), 8);
      Pace.Log.Put_Line ("vehicle_heading is " & Float'Image (Hal.Degs (Vehicle_Heading)), 8);

      -- find the smaller difference between the two headings
      if abs (Customer_Heading - Vehicle_Heading) > Pi then
         Azimuth := 2.0 * Pi - abs (Customer_Heading - Vehicle_Heading);
      else
         Azimuth := abs (Customer_Heading - Vehicle_Heading);
      end if;

      -- determine whether the customer is to the left or right of vehicle
      if (Vehicle_Heading > Customer_Heading and
          ((Vehicle_Heading >= 0.0 and Customer_Heading >= 0.0) or
           (Vehicle_Heading <= 0.0 and Customer_Heading <= 0.0))) or
         (Customer_Heading <= 0.0 and Vehicle_Heading >= 0.0 and
          (Vehicle_Heading + abs (Customer_Heading) < Pi)) or
         (Customer_Heading >= 0.0 and Vehicle_Heading <= 0.0 and
          (abs (Vehicle_Heading) + Customer_Heading) > Pi) then

         Azimuth := Azimuth;  -- customer is to the left

      else
         Azimuth := -Azimuth;  -- customer is to the right
      end if;
      return Azimuth;
   end Get_Azimuth;

   -- assigns a default launchpad_velocity..
   -- item won't hit customer, but will use the given el's and az's
   procedure Process_No_Customer (Job : in out Job_Record) is
   begin
      for I in 1 .. Natural (Length (Job.Data.Items)) loop
         Job.Items (I).Launchpad_Velocity := 300.0;
         Job.Items (I).Elevation := Element (Job.Data.Items, I).Elevation;
         Job.Items (I).Azimuth := Element (Job.Data.Items, I).Azimuth;
         Job.Items (I).Delivery_Time := 0.0;
      end loop;
   end Process_No_Customer;

   procedure Process_To_Hit_Customer_On_Time (Job : in out Job_Record) is
      Num_Items : Integer :=  Natural (Length (Job.Data.Items));
      Customer_Locations : Abk.Time_On_Customer.Coord_Arr (1 .. Num_Items);
      Possible_Velocities : Abk.Time_On_Customer.Float_Arr (Plant.Charge_Range);
      Box_Kind : Bstr.Bounded_String;

      -- returns the index of velocity in possible_velocities
      function Get_Power_Level (Velocity : Float) return Integer is
      begin
         for I in Possible_Velocities'Range loop
            if Possible_Velocities (I) = Velocity then
               return I;
            end if;
         end loop;
         return 0;  -- default
      end Get_Power_Level;

   begin

      -- get customer locations into correct data type
      Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!!!! DOING CUSTOMER LOCATION!!!!!!!!!!!!!");
      for I in Customer_Locations'Range loop
         Customer_Locations (I) := Element (Job.Data.Items, I).Customer;
      end loop;

      -- get the possible velocities
      Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!!!! DOING VELOCITIES !!!!!!!!!!!!!");
      -- assume the box type is the same for each item
      Box_Kind := Element (Job.Data.Items, 1).Box;
      for I in Possible_Velocities'Range loop
         Possible_Velocities (I) :=
           Sim.Inventory.Get_Launchpad_Velocity (B2s(Box_Kind),
                                              Plant.Charge_Range (I));
      end loop;

      declare
         Msg : Abk.Time_On_Customer.Find_Tot_Solution (Num_Items, Possible_Velocities'Length);
      begin
         Msg.Customer_Locations := Customer_Locations;
         Msg.Possible_Velocities := Possible_Velocities;
         Msg.Delta_Time_Constraint := Plant.Time_Between_Items;
         Msg.Min_Theta_Constraint := Hal.Rads (Plant.Min_Elevation_Angle);
         Msg.Max_Theta_Constraint := Hal.Rads (Plant.Max_Elevation_Angle);
         Pace.Dispatching.Inout (Msg);

         if Msg.Success then
            -- fill in the solution
            Job.Within_Range := True;
            for I in 1 .. Natural (Length (Job.Data.Items)) loop
               Job.Items (I).Elevation := Hal.Degs (Msg.Solution (I).Theta);
               Job.Items (I).Launchpad_Velocity := Msg.Solution (I).Velocity;
               declare
                  Power_Level : Integer := Get_Power_Level (Msg.Solution (I).Velocity);
               begin
                  Job.Items (I).Power_Level := Power_Level;
                  Ifc.Fm_Data.Set_Zoning (Job.Data.Id, I, Power_Level);
               end;

               -- the on_customer_time is relative to the start of the job,
               -- but delivery_time is relative to the start of the simulation
               Job.Items (I).Delivery_Time := Job.Data.Start_Time +
                 Element (Job.Data.Items, I).On_Customer_Time - Msg.Solution (I).Time_Of_Flight;

               -- assign correct azimuth
               Job.Items (I).Azimuth :=
                 Hal.Degs (Get_Azimuth (Msg.Customer_Locations (I).Easting,
                                        Msg.Customer_Locations (I).Northing));

               Pace.Log.Put_Line ("item " & Integer'Image (I), 4);
               Pace.Log.Put_Line ("velocity is " &
                                  Float'Image (Job.Items (I).Launchpad_Velocity), 4);
               Pace.Log.Put_Line ("elevation is " &
                                  Float'Image (Job.Items (I).Elevation), 4);
               Pace.Log.Put_Line ("azimuth is " & Float'Image (Job.Items (I).Azimuth) & "(degrees)", 4);
               Pace.Log.Put_Line ("delivery time is " & Duration'Image (Job.Items (I).Delivery_Time), 4);


            end loop;

         else
            -- if there is no solution then halt the job
            Job.Within_Range := False;
            Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!!! Time On Customer Solution is not possible !!!!!!!!!!!");
         end if;
      end;

   end Process_To_Hit_Customer_On_Time;

   -- assigns launchpad velocity, charge_num, delivery_time, elevation, and azimuth in order
   -- to hit the customer
   -- assumes inventory supply exists
   procedure Process_To_Hit_Customer (Job : in out Job_Record) is

      Easting, Northing : Float;
      Vertical_Distance, Horizontal_Distance : Float;
      Box_Kind : Bstr.Bounded_String;
   begin
      -- calculate elevation, velocity, charge_nums and delivery_time for each item
      for I in 1 .. Natural (Length (Job.Data.Items)) loop
         Easting := Element (Job.Data.Items, I).Customer.Easting;
         Northing := Element (Job.Data.Items, I).Customer.Northing;
         Horizontal_Distance := Get_Horizontal_Distance (Easting, Northing);
         Pace.Log.Put_Line ("horizontal distance is " & Float'Image (Horizontal_Distance), 8);
         Vertical_Distance := Get_Vertical_Distance (Easting, Northing);
         Pace.Log.Put_Line ("vertical distance is " & Float'Image (Vertical_Distance), 8);

         Box_Kind := Element (Job.Data.Items, I).Box;
         Job.Within_Range := False;

         -- each time through loop check to see if item can hit customer in given zone
         -- if it can then exit loop.. so the lowest zone possible will be used
         -- in order to hit the customer
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
                  Job.Items (I).Elevation := Hal.Degs (Elevation);
                  Job.Items (I).Launchpad_Velocity := Velocity;
                  Job.Items (I).Power_Level := Zone;
                  Ifc.Fm_Data.Set_Zoning (Job.Data.Id, I, Zone);
                  Job.Within_Range := True;
                  exit;  -- found a solution, so exit loop
               end if;
            end;
         end loop;

         if Job.Within_Range = False then
            Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!!! Job is not within range!!!!!!!!!!!");
            exit;  -- exit the loop since job won't be ran
         end if;

         Pace.Log.Put_Line ("item " & Integer'Image (I), 8);
         Pace.Log.Put_Line ("velocity is " &
                                          Float'Image (Job.Items (I).Launchpad_Velocity), 8);
         Pace.Log.Put_Line ("elevation is " &
                                           Float'Image (Job.Items (I).Elevation), 8);

         -- this is not a time on customer job, so set delivery_time to 0.0
         Job.Items (I).Delivery_Time := 0.0;

         -- assign correct azimuth
         declare
            Azimuth : Float := Hal.Degs (Get_Azimuth (Easting, Northing));
         begin
            Job.Items (I).Azimuth := Azimuth;
         end;

         Pace.Log.Put_Line ("item " & Integer'Image (I), 4);
         Pace.Log.Put_Line ("velocity is " &
                            Float'Image (Job.Items (I).Launchpad_Velocity), 4);
         Pace.Log.Put_Line ("elevation is " &
                            Float'Image (Job.Items (I).Elevation), 4);
         Pace.Log.Put_Line ("azimuth is " & Float'Image (Job.Items (I).Azimuth), 4);
      end loop;

   end Process_To_Hit_Customer;

   procedure Calculate_Vel_And_Az (Job : in out Job_Record) is
      use Bstr;
   begin
      if Ifc.Fm_Data.Has_Customer (Job.Data) then
         if Bstr.To_String (Job.Data.Control) = "Time On Customer" then
            Pace.Log.Put_Line ("processing customer_on_time", 4);
            Process_To_Hit_Customer_On_Time (Job);
         else
            Pace.Log.Put_Line ("processing customer", 4);
            Process_To_Hit_Customer (Job);
         end if;
      else
         Pace.Log.Put_Line ("processing no customer", 4);
         Process_No_Customer (Job);
      end if;
   end Calculate_Vel_And_Az;


   procedure Input (Obj : in Calculate_Flight_Solution) is
   begin
      Pace.Log.Wait (0.2);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Inout (Obj : in out Perform_Technical_Delivery_Direction) is
   begin
      -- job's do not always start at the preplanned time, and we
      -- need to refer to when the job really starts since time
      -- on customer times are relative to start of job
      Obj.Job.Data.Start_Time := Pace.Now;
      Calculate_Vel_And_Az (Obj.Job);  -- should this be in calculate_flight_solution??
      Pace.Log.Wait (3.0);
      Pace.Log.Trace (Obj);
   exception
      when E: others =>
         Pace.Log.Ex (E);
         Pace.Log.Put_Line
           ("Exception during Preprocessing of Job !!!!!!!!!!!!!!!!");
   end Inout;

end Abk.Technical_Delivery_Direction;
