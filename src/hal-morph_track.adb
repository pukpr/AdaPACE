with Pace.Log;
with Ada.Numerics.Elementary_Functions;


package body Hal.Morph_Track is

   Y_Pin : array (1 .. 10) of Float;
   Z_Pin : array (1 .. 10) of Float;

   -- checks an angle to see if it is inside the boundary limits, and
   -- if not returns the appropriate angle
   function Boundary_Condition (Angle : in Float) return Float is
   begin
      if Angle > Highest_Angle then
         Pace.Log.Put_Line ("!!!!!!!! Changing morph angle from " &
                            Float'Image (Angle) & " to " &
                            Float'Image (Highest_Angle));
         return Highest_Angle;
      elsif Angle < Lowest_Angle then
         Pace.Log.Put_Line ("!!!!!!!! Changing morph angle from " &
                            Float'Image (Angle) & " to " &
                            Float'Image (Lowest_Angle));
         return Lowest_Angle;
      else
         return Angle;
      end if;
   end Boundary_Condition;



   -- Alpha_Angle should come in with degrees as units and the Pin_Array
   -- being returned will have radians as units
   function Get_Pin_Values (Alpha_Angle : Float)
                           return Hal.Sms_Lib.Morph.Pin_Array is
      use Ada.Numerics.Elementary_Functions;
      N : constant Float := 0.3051;
      M : constant Float := 0.4319;
      Omega : constant Float := 0.1435;
      Radius : constant Float := 0.1616;
      Index : Integer := 0;
      Theta : Float;
      Z_Center : Float;
      Y_Center : Float;
      Y_Tangent_1 : Float;
      Z_Tangent_1 : Float;
      Y_Tangent_2 : Float;
      Z_Tangent_2 : Float;
      Y_Radius : Float;
      Z_Radius : Float;
      Y_Diff : Float;
      Delta_Y : Float;
      Delta_Z : Float;
      L : constant Float := -0.2703;
      Z_Theta : array (1 .. Num_Pins - 1) of Float;
      Theta_Angle : Hal.Sms_Lib.Morph.Pin_Array (1 .. Num_Pins - 1);
      Pin_Diff : constant Float := 0.038;
      D, A, H, B, C : Float;
      Z_Prime : Float;
      Y_Prime : Float;
      Z_A : constant Float := 0.0;
      Z_B : constant Float := 0.2000;
      Y_A, Y_B, U_1, U_2 : Float;
      Difference : Float;
   begin

      -- Equations for curved radius points
      Theta := Hal.Rads (Alpha_Angle);
      if Theta < 0.0 then
         Theta := -Theta;
      end if;
      Y_Center := N * Tan (Theta) - (M / Cos (Theta));
      Z_Center := N;
      -- 1st Tangent Points
      Y_Tangent_1 := Y_Center;
      Z_Tangent_1 := Omega;
      -- 2nd Tangent Points
      Y_Tangent_2 := Y_Center + (Radius * Cos (Theta));
      Z_Tangent_2 := Z_Center - (Radius * Sin (Theta));
      -- Elevation Path
      Y_Diff := (Y_Tangent_2 - Y_Tangent_1);
      Y_Radius := Y_Tangent_1 + Y_Diff;
      Z_Radius := Z_Center + Sqrt ((Radius ** 2) +
                                   ((Y_Radius - Y_Center) ** 2));
      Y_Radius := -Z_Radius * Tan (Theta) + (L / Cos (Theta));


      -- Calculate Vertical Pin Positions
      Y_Pin (1) := -0.435;
      Z_Pin (1) := 0.1435;

      Index := 1;
      loop
         exit when (Y_Tangent_1 - Y_Pin (Index)) < 0.0380;
         Y_Pin (Index + 1) := Y_Pin (Index) + Pin_Diff;
         Z_Pin (Index + 1) := Z_Pin (Index);
         Index := Index + 1;
--          Pace.Log.Put_Line ("PIN " & Integer'Image (Index) &
--                             " IS " & Float'Image (Y_Pin (Index)) &
--                             ", " & Float'Image (Z_Pin (Index)));
         exit when Index = Num_Pins;
      end loop;

      -- Calculate Pin Positions on Curve
      loop
         exit when Index = Num_Pins;
         Delta_Y := Y_Pin (Index) - Y_Center;
         Delta_Z := Z_Pin (Index) - Z_Center;
         D := Sqrt ((Delta_Y ** 2) + (Delta_Z ** 2));
         A := ((Radius ** 2) - (Pin_Diff ** 2) + (D ** 2)) / (2.0 * D);
         H := Sqrt ((Radius ** 2) - (A ** 2));
         Z_Prime := Z_Center + ((A * Delta_Z) / D);
         Y_Prime := Y_Center + ((A * Delta_Y) / D);
         Y_Pin (Index + 1) := Y_Prime - ((H * Delta_Z) / D);
         Z_Pin (Index + 1) := Z_Prime + ((H * Delta_Y) / D);
         Index := Index + 1;
--          Pace.Log.Put_Line ("PIN " & Integer'Image (Index) &
--                             " IS " & Float'Image (Y_Pin (Index)) &
--                             ", " & Float'Image (Z_Pin (Index)));
         Difference := Sqrt (((Y_Tangent_2 - Y_Pin (Index)) ** 2) +
                             ((Z_Tangent_2 - Z_Pin (Index)) ** 2));
         exit when Difference < Pin_Diff;
      end loop;

      -- Calculate Pin Locations on the Straight Path
      loop
         exit when Index = Num_Pins;
         Y_B := (Z_B * Tan (Theta)) + (L / Cos (Theta));
         Y_A := (-Z_A * Tan (Theta)) + (L / Cos (Theta));
         C := (Y_Pin (Index) ** 2) + (Z_Pin (Index) ** 2) +
                (Y_A ** 2) + (Z_A * Z_A) -
                (2.0 * ((Y_Pin (Index) * Y_A) + (Z_Pin (Index) * Z_A))) -
                (Pin_Diff ** 2);
         B := 2.0 * (((Y_B - Y_A) * (Y_A - Y_Pin (Index))) +
                     ((Z_B - Z_A) * (Z_A - Z_Pin (Index))));
         A := ((Y_B - Y_A) ** 2) + ((Z_B - Z_A) ** 2);
         U_1 := (-B + (Sqrt (abs ((B ** 2) - (4.0 * A * C))))) / (2.0 * A);
         U_2 := (-B - (Sqrt (abs ((B ** 2) - (4.0 * A * C))))) / (2.0 * A);
         Z_Pin (Index + 1) := Z_A + (U_1 * (Z_B - Z_A));
         Y_Pin (Index + 1) := Y_A + (U_1 * (Y_B - Y_A));
         if Z_Pin (Index + 1) < Z_Pin (Index) then
            Z_Pin (Index + 1) := Z_A + (U_2 * (Z_B - Z_A));
            Y_Pin (Index + 1) := Y_A + (U_2 * (Y_B - Y_A));
         end if;

         Index := Index + 1;
--          Pace.Log.Put_Line ("PIN " & Integer'Image (Index) &
--                             " IS " & Float'Image (Y_Pin (Index)) &
--                             ", " & Float'Image (Z_Pin (Index)));
      end loop;
      -- Calculate Theta
      for I in 1 .. Num_Pins - 1 loop
         Z_Theta (I) := (Arctan ((Y_Pin (I + 1) - Y_Pin (I)) /
                                 (Z_Pin (I + 1) - Z_Pin (I))));
         if I = 1 then
            Theta_Angle (I) := Hal.Rads (90.0) - Z_Theta (I);
         else
            Theta_Angle (I) := Z_Theta (I - 1) - Z_Theta (I);
         end if;
         --Pace.Log.Put_Line ("Pin " & Integer'Image (I) & " is " & Float'Image(Hal.Degs (Theta_Angle (I))));
      end loop;
      return Theta_Angle;
   end Get_Pin_Values;



   -- the angles are in degrees
   procedure Do_Morph (Starting_Angle, Ending_Angle : Float) is
      -- go through loop this many times
      Num_To_Loop : Integer;
      -- the amount to rotate each time through loop..
      Delta_Angle : Float;
      Current_Angle : Float := Starting_Angle;
      S_Angle : Float := Boundary_Condition (Starting_Angle);
      E_Angle : Float := Boundary_Condition (Ending_Angle);
   begin
      -- skip over if they are the same
      if Starting_Angle /= Ending_Angle then

         Num_To_Loop := Integer (abs (E_Angle - S_Angle) *
                                 Float (Intervals_Per_Degree)) - 1;

         -- figure out if the morph track is rising or lowering
         if S_Angle < E_Angle then
            Delta_Angle := 1.0 / Float (Intervals_Per_Degree);
         else
            Delta_Angle := -1.0 / Float (Intervals_Per_Degree);
         end if;

         for I in 1 .. Num_To_Loop loop
            Current_Angle := Current_Angle + Delta_Angle;
            Hal.Sms_Lib.Morph.Set (Assembly_Prefix,
                               Get_Pin_Values (Current_Angle), Pin_Positions);
            Pace.Log.Wait (Time_Between_One_Degree / Intervals_Per_Degree);
         end loop;
         -- for the last one we want to ensure that it is for the correct
         -- angle, E_Angle
         Hal.Sms_Lib.Morph.Set (Assembly_Prefix,
                            Get_Pin_Values (E_Angle), Pin_Positions);
      end if;
   end Do_Morph;

end Hal.Morph_Track;
