with Aunit.Test_Cases.Registration;
use Aunit.Test_Cases.Registration;

with Aunit.Assertions;
use Aunit.Assertions;

with Hal.Rotations;
with Pace;
with Hal;
with Ual.Utilities;

--  Template for test case body.
package body Uut.Hal_Rotations is

   use Hal.Rotations;

   --  Example test routine. Provide as many as are needed:
   procedure Test_Adjust_For_Pitch_And_Roll (R : in out
                                               Aunit.Test_Cases.Test_Case'Class);

   procedure Test_Adjust_For_Pitch_And_Roll (R : in out
                                               Aunit.Test_Cases.Test_Case'Class) is

      Tolerance : constant := 0.5;
      Test_Id : Integer := 0;

      procedure Test_Case (In_El, In_Az : Float;
                           Yaw, Pitch, Roll : Float;
                           Exp_El, Exp_Az : Float) is
         Out_El, Out_Az : Float;
      begin
         Test_Id := Test_Id + 1;
         Adjust_For_Pitch_And_Roll (In_El => Hal.Rads (In_El),
                                    In_Az => Hal.Rads (In_Az),
                                    Pitch => Hal.Rads (Pitch),
                                    Roll => Hal.Rads (Roll),
                                    Yaw => Hal.Rads (Yaw),
                                    Invert => True,
                                    Out_El => Out_El,
                                    Out_Az => Out_Az);
         Assert
           (abs (Hal.Degs (Out_El) - Exp_El) < Tolerance,
            "Measured elevation: " & Float'Image (Hal.Degs (Out_El)) &
            " is not within tolerance of expected elevation: " &
            Float'Image (Exp_El) &
            " when doing a roll-pitch-yaw transformation for test id " &
            Integer'Image (Test_Id));
         Assert
           (abs (Hal.Degs (Out_Az) - Exp_Az) < Tolerance,
            "Measured azimuth: " & Float'Image (Hal.Degs (Out_Az)) &
            " is not within tolerance of expected azimuth: " &
            Float'Image (Exp_Az) &
            " when doing a roll-pitch-yaw transformation for test id " &
            Integer'Image (Test_Id));


         -- check the other direction, so Exp_El and In_El swap and same with Az
         Adjust_For_Pitch_And_Roll (In_El => Hal.Rads (Exp_El),
                                    In_Az => Hal.Rads (Exp_Az),
                                    Pitch => Hal.Rads (Pitch),
                                    Roll => Hal.Rads (Roll),
                                    Yaw => Hal.Rads (Yaw),
                                    Invert => False,
                                    Out_El => Out_El,
                                    Out_Az => Out_Az);
         Assert
           (abs (Hal.Degs (Out_El) - In_El) < Tolerance,
            "Measured elevation: " & Float'Image (Hal.Degs (Out_El)) &
            " is not within tolerance of expected elevation: " &
            Float'Image (In_El) &
            " when doing a roll-pitch-yaw transformation for test id " &
            Integer'Image (Test_Id));
         Assert
           (abs (Hal.Degs (Out_Az) - In_Az) < Tolerance,
            "Measured azimuth: " & Float'Image (Hal.Degs (Out_Az)) &
            " is not within tolerance of expected azimuth: " &
            Float'Image (In_Az) &
            " when doing a roll-pitch-yaw transformation for test id " &
            Integer'Image (Test_Id));

      end Test_Case;

   begin

      Test_Case (In_El => 45.0,
                 In_Az => 0.0,
                 Yaw => 0.0,
                 Pitch => 0.0,
                 Roll => -90.0,
                 Exp_El => 0.0,
                 Exp_Az => -45.0);

      Test_Case (In_El => 0.0,
                 In_Az => -45.0,
                 Yaw => 90.0,
                 Pitch => 0.0,
                 Roll => 0.0,
                 Exp_El => 0.0,
                 Exp_Az => 45.0);

      Test_Case (In_El => 45.0,
                 In_Az => 0.0,
                 Yaw => 0.0,
                 Pitch => 30.0,
                 Roll => 0.0,
                 Exp_El => 15.0,
                 Exp_Az => 0.0);

      Test_Case (In_El => 45.0,
                 In_Az => 0.0,
                 Yaw => 0.0,
                 Pitch => 30.0,
                 Roll => 0.0,
                 Exp_El => 15.0,
                 Exp_Az => 0.0);

      Test_Case (In_El => 0.0,
                 In_Az => -170.0,
                 Yaw => -170.0,
                 Pitch => 0.0,
                 Roll => 0.0,
                 Exp_El => 0.0,
                 Exp_Az => 20.0);

      -- the following 3 test cases were verified visually within division
      Test_Case (In_El => 45.0,
                 In_Az => 0.0,
                 Yaw => -10.0,
                 Pitch => 20.0,
                 Roll => 30.0,
                 Exp_El => 25.504,
                 Exp_Az => 6.79634);

      Test_Case (In_El => 60.0,
                 In_Az => 0.0,
                 Yaw => 0.0,
                 Pitch => -7.2075,
                 Roll => 0.2028,
                 Exp_El => 67.2066,
                 Exp_Az => 0.482607);

      Test_Case (In_El => 15.0,
                 In_Az => 30.0,
                 Yaw => -27.0,
                 Pitch => -40.0,
                 Roll => -20.0,
                 Exp_El => 51.8357,
                 Exp_Az => -22.0895);

   end Test_Adjust_For_Pitch_And_Roll;

   procedure Test_Convert_Vector (R : in out Aunit.Test_Cases.Test_Case'Class) is
      use Hal;

      function Float_Vector_Equals (Vec1, Vec2 : Position) return Boolean is
         use Ual.Utilities;
      begin
         return Float_Equals (Vec1.X, Vec2.X) and Float_Equals (Vec1.Y, Vec2.Y) and Float_Equals (Vec1.Z, Vec2.Z);
      end Float_Vector_Equals;

      procedure Test_Case (In_Vector : Position;
                           In_Ori : Orientation;
                           Expected_Vector : Position) is
         Actual_Vector : Position := Hal.Rotations.Convert_Vector (In_Vector,
                                                                   Rz (In_Ori.C),
                                                                   Rx (In_Ori.A),
                                                                   Ry (In_Ori.B));
      begin
         Assert (Float_Vector_Equals (Actual_Vector, Expected_Vector), "Convert_Vector failed: Expected " & To_Str (Expected_Vector) & ", but actual is " & To_Str (Actual_Vector));
      end Test_Case;

   begin
      Test_Case (Position'(1.584, 0.0, -0.024),
                 Orientation'(Rads (270.491), Rads (184.665), Rads (355.335)),
                 Position'(-1.584, -0.0251, 0.000209));
   end Test_Convert_Vector;


   --  Register test routines to call:
   procedure Register_Tests (T : in out Test_Case) is
   begin
      --  Repeat for each test routine.
      Register_Routine (T, Test_Adjust_For_Pitch_And_Roll'Access,
                        "Test_Adjust_For_Pitch_And_Roll");
      Register_Routine (T, Test_Convert_Vector'Access,
                        "Test_Convert_Vector");
   end Register_Tests;

   --  Identifier of test case:
   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Hal_Rotations");
   end Name;

end Uut.Hal_Rotations;
