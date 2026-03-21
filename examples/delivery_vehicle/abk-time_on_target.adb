with Pace.Log;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Numerics;
with Hal;

package body Abk.Time_On_Target is

   type Solution_Item_Pair is
      record
         Sol : Tot_Solution;
         Item_Index : Integer;
      end record;

   -- for sorting by item_index and then by time_of_flight
   -- so all item (i+1) solutions will come before item i solutions and
   -- the item i solutions will be sorted by time_of_flight
   function Tot_Less_Than (X, Y : Solution_Item_Pair) return Boolean is
   begin
      if X.Item_Index = Y.Item_Index then
         if X.Sol.Time_Of_Flight < Y.Sol.Time_Of_Flight then
            return True;
         else
            return False;
         end if;
      elsif X.Item_Index > Y.Item_Index then
         return True;
      else
         return False;
      end if;
   end Tot_Less_Than;

   package Solutions_List_Pkg is new Ada.Containers.Doubly_Linked_Lists (Solution_Item_Pair, "=");
   package Solutions_Sorting is new Solutions_List_Pkg.Generic_Sorting ("<" => Tot_Less_Than);

   use Solutions_List_Pkg;

   procedure Inout (Obj : in out Find_Tot_Solution) is

      Solutions : Solutions_List_Pkg.List;

      Hdist, Vdist : array (1 .. Obj.Num_Items) of Float;

      -- checks Possible_Theta against the min and max theta constraints and adds
      -- to list if it checks out
      procedure Check_And_Add (Theta : Float; Velocity : Float; Item_Index : Integer) is
         Srp : Solution_Item_Pair;
      begin
         if Theta >= Obj.Min_Theta_Constraint and Theta <= Obj.Max_Theta_Constraint then
            Srp.Item_Index := Item_Index;
            Srp.Sol.Theta := Theta;
            Srp.Sol.Velocity := Velocity;
            Srp.Sol.Time_Of_Flight := Duration (Total_Time_In_Air (Theta,
                                                                   Velocity,
                                                                   Vdist (Item_Index)));
            Append (Solutions, Srp);
            Pace.Log.Put_Line ("Adding: Item: " & Item_Index'Img &
                               " Theta: " & Hal.Degs (Srp.Sol.Theta)'Img &
                               " Vel: " & Srp.Sol.Velocity'Img &
                               " TOF: " & Srp.Sol.Time_Of_Flight'Img, 8);
         end if;
      end Check_And_Add;

   begin

      -- calculate the horizontal and vertical distances
      for I in Obj.Target_Locations'Range loop
         Hdist (I) := Get_Horizontal_Distance (Obj.Target_Locations (I).Easting, Obj.Target_Locations (I).Northing);
         Vdist (I) := Get_Vertical_Distance (Obj.Target_Locations (I).Easting, Obj.Target_Locations (I).Northing);
         Pace.Log.Put_Line ("hdist: " & Hdist (I)'Img & " vdist: " & Vdist (I)'Img, 4);
      end loop;

      -- find all velocity and theta combinations that satisfy
      -- the min and max theta constraints for each target
      declare
         Success : Boolean;
         Elevation : Float;
      begin
         for J in Obj.Target_Locations'Range loop
            for I in Obj.Possible_Velocities'Range loop
               Elevation_Calculation (Obj.Possible_Velocities (I),
                                      Hdist (J),
                                      Vdist (J),
                                      Success,
                                      Elevation);
               if Success then
                  -- elevation_calculation finds the theta less than 45 degrees, but
                  -- we also want to consider the theta greater than 45 degrees
                  Check_And_Add (Elevation, Obj.Possible_Velocities (I), J);
                  Check_And_Add (Ada.Numerics.Pi / 2.0 - Elevation, Obj.Possible_Velocities (I), J);
               end if;
            end loop;
         end loop;
      end;

      -- sort by item_index and then time_of_flight
      Solutions_Sorting.Sort (Solutions);

      -- check against the time constraint to find a solution if one exists
      -- take the solution with least time of flight and assign as the last solution
      -- and build up from there
      declare
         Iter : Cursor := First (Solutions);
         -- decreases as solutions are found
         Counter : Integer := Obj.Num_Items;
      begin
         Obj.Solution (Counter) := Element (Iter).Sol;
         Iter := Next (Iter);
         Counter := Counter - 1;
         while Has_Element (Iter) and Counter > 0 loop
            declare
               Srp : Solution_Item_Pair := Element (Iter);
            begin
               Pace.Log.Put_Line ("Sorted: Item: " & Srp.Item_Index'Img &
                                  " Theta: " & Hal.Degs (Srp.Sol.Theta)'Img &
                                  " Vel: " & Srp.Sol.Velocity'Img &
                                  " TOF: " & Srp.Sol.Time_Of_Flight'Img, 8);

               -- since Solutions is ordered by item_index, we only want to consider
               -- a solution that is for the current item we are trying to solve
               if Srp.Item_Index = Counter then
                  if (Srp.Sol.Time_Of_Flight - Obj.Solution (Counter + 1).Time_Of_Flight) > Obj.Delta_Time_Constraint then
                     Obj.Solution (Counter) := Srp.Sol;
                     Counter := Counter - 1;
                  end if;
               end if;
            end;
            Iter := Next (Iter);
         end loop;
         if Counter = 0 then
            Obj.Success := True;
         else
            Obj.Success := False;
         end if;
      end;
      Pace.Log.Trace (Obj);
   end Inout;


end Abk.Time_On_Target;
