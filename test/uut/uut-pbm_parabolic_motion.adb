with Aunit.Test_Cases.Registration; use Aunit.Test_Cases.Registration;

with Aunit.Assertions; use Aunit.Assertions;

with Ada.Numerics;
with Text_IO;
with PBM.Trajectory;
with PBM.Parabolic_Motion;
with Hal;
with Pace.Log;

package body Uut.Pbm_Parabolic_Motion is

   procedure Test_Impact (R : in out Aunit.Test_Cases.Test_Case'Class);
   procedure Test_Impact (R : in out Aunit.Test_Cases.Test_Case'Class) is
      El      : Float;
      Success : Boolean;
   begin

      -- Intersects at parabolic apex for given parameters
      PBM.Parabolic_Motion.Elevation_Calculation
        (Initial_Velocity    => 500.0,
         Horizontal_Distance => 11046.25,
         Vertical_Distance   => 9566.34,
         Success             => Success,
         Elevation           => El,
         Low_El              => 0.0,
         High_El             => Ada.Numerics.Pi / 2.0);

      El := Hal.Degs(El);
      Assert
        (Success and (El < 60.1 and El > 59.9 ),
         "Solution found? " &
         Success'Img &
         ". Firing angle should be near 60 degrees, actually:" &
         El'Img);

      PBM.Parabolic_Motion.Elevation_Calculation
        (Initial_Velocity    => 500.0,
         Horizontal_Distance => 11046.25,
         Vertical_Distance   => 9566.34,
         Success             => Success,
         Elevation           => El,
         Low_El              => 0.0,
         High_El             => Ada.Numerics.Pi / 2.0,
         High_Quadrant       => False);

      Assert
        (not Success,
         "Should not be able to find a low quadrant solution." &
         "Firing angle :" & El'Img);


      for I in reverse Boolean'Range loop
         -- Suspicious one when using Floats
         PBM.Parabolic_Motion.Elevation_Calculation
           (Initial_Velocity    => 588.0,
            Horizontal_Distance => 10000.0,
            Vertical_Distance   => -123.118,
            Success             => Success,
            Elevation           => El,
            Low_El              => 0.0,
            High_El             => Ada.Numerics.Pi / 2.0,
            High_Quadrant       => I,
            Accuracy_Eps        => 0.01,
            Vertical_Tolerance  => 10.0);

         Assert
           (Success,  "Can't find a solution. High="
            & I'Img & " Firing angle :" & El'Img);
      end loop;

   end Test_Impact;

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Pbm_Parabolic_Motion");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      --  Repeat for each test routine.
      Register_Routine (T, Test_Impact'Access, "Test_Impact");
   end Register_Tests;

end Uut.Pbm_Parabolic_Motion;
