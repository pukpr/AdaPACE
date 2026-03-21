with Hal;
with Pbm;

package body Acu is

   -- Returns the percent to change due to pitch.
   -- This was empirically determined from the requirements that all MGVs
   -- should be able to move 90 kph on a grade of 2%, 55 kph on a grade
   -- of 10%, and 11 kph on a grade of 60%.  Grade is assumed to be
   -- the tangent of (rise/run) and not the sine...  this function
   -- gives results as follows:
   -- grade(%)    angle(degs)  reqs(kph)   this_function (kph)
   --     2        1.146          90          93.41
   --    10        5.711          55          59.36
   --    60       30.964          11          11.89
   -- Inclination_Angle is the angle in degrees, not the grade!!
   function Change_Due_To_Pitch (Pitch : Float; Max_Velocity : Float) return Float is
      Inclination_Angle : Float;
      Max_Speed_At_Current_Pitch : Float;
      Change_By_Percent : Float;
   begin
      -- taking absolute value here.. even if pitch is negative (so
      -- we must be in reverse) we want this angle to be positive
      -- for this empirical equation!
      Inclination_Angle := Hal.Degs (abs (Pitch));
      Max_Speed_At_Current_Pitch :=
        10.0 * (3.1 * (-Inclination_Angle / 10.0 + 2.0) + 0.9);
      Change_By_Percent := Max_Speed_At_Current_Pitch /
        (Max_Velocity * Pbm.Ms_To_Kph_Factor);
      if Change_By_Percent > 1.0 then
         Change_By_Percent := 1.0;
      elsif Change_By_Percent < 0.0 then
         Change_By_Percent := 0.0;
      end if;
      return Change_By_Percent;
   end Change_Due_To_Pitch;

end Acu;
