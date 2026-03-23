with Aunit.Test_Cases.Registration;
use Aunit.Test_Cases.Registration;

with Aunit.Assertions;
use Aunit.Assertions;

with Ual.Probability;
use Ual.Probability;
with Ada.Text_Io;

package body Uut.Ual_Probability is

   procedure Test_Exp_Mean (R : in out Aunit.Test_Cases.Test_Case'Class);
   procedure Test_Gamma_Mean (R : in out Aunit.Test_Cases.Test_Case'Class);

   -- Tests that the Exponential_Random_Var function mean is indeed near the mean supplied.
   procedure Test_Exp_Mean (R : in out Aunit.Test_Cases.Test_Case'Class) is
      Expected_Mean : Float := 5.0;
      Minimum : Float := 1.0;
      Measured_Mean : Float;
      Sum : Float := 0.0;
      Sample_Points : Integer := 1000;
      Delta_Error : Float := 0.5;
   begin
      for I in 1 .. Sample_Points loop
         Sum := Sum + Exponential_Random_Var (Expected_Mean);
      end loop;
      Measured_Mean := Sum / Float (Sample_Points);
      Ada.Text_Io.Put_Line ("Exp : measured_mean was " &
                            Float'Image (Measured_Mean));
      Assert
        (abs (Measured_Mean - Expected_Mean) < Delta_Error,
         "Exponential Distribution Mean is not within the allowed error of " &
           Float'Image (Delta_Error) & " Measured Mean => " &
           Float'Image (Measured_Mean) & " and Expected_Mean => " &
           Float'Image (Expected_Mean));

      -- now do shifted exponential
      Sum := 0.0;
      for I in 1 .. Sample_Points loop
         Sum := Sum + Exponential_Random_Var (Expected_Mean, Minimum);
      end loop;
      Measured_Mean := Sum / Float (Sample_Points);
      Ada.Text_Io.Put_Line ("Exp (shifted) : measured_mean was " &
                            Float'Image (Measured_Mean));
      Assert
        (abs (Measured_Mean - Expected_Mean) < Delta_Error,
         "Exponential Shifted Distribution Mean is not within the allowed error of " &
           Float'Image (Delta_Error) & " Measured Mean => " &
           Float'Image (Measured_Mean) & " and Expected_Mean => " &
           Float'Image (Expected_Mean));

   end Test_Exp_Mean;

   -- Tests that the Gamma_Random_Var function mean is indeed near the mean supplied.
   procedure Test_Gamma_Mean (R : in out Aunit.Test_Cases.Test_Case'Class) is
      Exponential_Mean : Float := 5.0;
      Num_Exp_Vars : Integer := 20;
      Expected_Mean : Float := Float (Num_Exp_Vars) / Exponential_Mean;
      Measured_Mean : Float;
      Sum : Float := 0.0;
      Sample_Points : Integer := 1000;
      Delta_Error : Float := 0.5;
   begin
      for I in 1 .. Sample_Points loop
         Sum := Sum + Gamma_Random_Var (Exponential_Mean, Num_Exp_Vars);
      end loop;
      Measured_Mean := Sum / Float (Sample_Points);
      Ada.Text_Io.Put_Line ("Gamma : measured_mean was " &
                            Float'Image (Measured_Mean));
      Assert (abs (Measured_Mean - Expected_Mean) < Delta_Error,
              "Gamma Distribution Mean is not within the allowed error of " &
                Float'Image (Delta_Error) & " Measured Mean => " &
                Float'Image (Measured_Mean) & " and Expected_Mean => " &
                Float'Image (Expected_Mean));
   end Test_Gamma_Mean;

   --  Register test routines to call:
   procedure Register_Tests (T : in out Test_Case) is
   begin
      --  Repeat for each test routine.
      Register_Routine
        (T, Test_Exp_Mean'Access, "Test_Exp_Mean");
      Register_Routine
        (T, Test_Gamma_Mean'Access, "Test_Gamma_Mean");
   end Register_Tests;

   --  Identifier of test case:
   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Ual_Probability");
   end Name;

end Uut.Ual_Probability;
