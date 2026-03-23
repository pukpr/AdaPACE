with Aunit.Test_Cases.Registration;
use Aunit.Test_Cases.Registration;

with Aunit.Assertions;
use Aunit.Assertions;

with Hal.Sms;
with Ada.Numerics;

--  Template for test case body.
package body Uut.Hal_Generic_Sms is

   use Hal.Sms;
   use Hal;
   use Ada.Numerics;

   procedure Cb_Check_M1 (value : in float) is
   begin
      Assert (Value >= Pi / 2.0 or Value <= -Pi / 2.0, "Went the wrong way when which_way is positive. Value is " & Value'Img);
   end Cb_Check_M1;

   procedure Cb_Check_M2 (value : in float) is
   begin
      Assert ((Value <= Pi / 2.0 and Value >= -Pi / 2.0), "Went the wrong way when which_way is negative.  Value is " & Value'Img);
   end Cb_Check_M2;

   procedure Cb_Check_M3 (value : in float) is
   begin
      Assert (not (Value > 0.0 and Value < Pi / 2.0), "Attempted to rotate the long way around (negative direction) from 0 to 90 degrees, but Value is " & Value'Img);
   end Cb_Check_M3;

   procedure Cb_Check_M4 (value : in float) is
   begin
      Assert (Value >= 0.0 and Value <= Pi / 2.0, "Attempted to rotate via the shortest route (positive direction) from 0 to 90 degrees, but Value is " & Value'Img);
   end Cb_Check_M4;

   procedure Cb_Check_1 (Ori : in Orientation) is
   begin
      Cb_Check_M1 (Ori.A);
   end Cb_Check_1;

   procedure Cb_Check_2 (Ori : in Orientation) is
   begin
      Cb_Check_M2 (Ori.A);
   end Cb_Check_2;

   procedure Cb_Check_3 (Ori : in Orientation) is
   begin
      Cb_Check_M3 (Ori.A);
   end Cb_Check_3;

   procedure Cb_Check_4 (Ori : in Orientation) is
   begin
      Cb_Check_M4 (Ori.A);
   end Cb_Check_4;

   procedure Test_Rotation_Which_Way (R : in out Aunit.Test_Cases.Test_Case'Class) is
      Start : Orientation := (Pi/2.0, 0.0, 0.0);
      Final : Orientation := (-Pi/2.0, 0.0, 0.0);
      Stopped : Boolean;
   begin
      -- rotating from 90 to -90 in neg direction (through 180)
      Hal.Sms.Rotation ("dummy",
                        Start,
                        Final,
                        5.0,
                        Stopped,
                        0.0,
                        0.0,
                        Cb_Check_1'Access,
                        "",
                        Pos);

      -- rotating from 90 to -90 in neg direction (through 0)
      Hal.Sms.Rotation ("dummy",
                        Start,
                        Final,
                        5.0,
                        Stopped,
                        0.0,
                        0.0,
                        Cb_Check_2'Access,
                        "",
                        Neg);

      -- rotating from 0 to 90 the long way around
      Start.A := 0.0;
      Final.A := Pi / 2.0;
      Hal.Sms.Rotation ("dummy",
                        Start,
                        Final,
                        5.0,
                        Stopped,
                        0.0,
                        0.0,
                        Cb_Check_3'Access,
                        "",
                        Neg);

      -- rotating from 0 to 90 via the shortest route
      Start.A := 0.0;
      Final.A := Pi / 2.0;
      Hal.Sms.Rotation ("dummy",
                        Start,
                        Final,
                        5.0,
                        Stopped,
                        0.0,
                        0.0,
                        Cb_Check_4'Access,
                        "",
                        Shortest_Route);

   end Test_Rotation_Which_Way;

   procedure Test_Motion_Which_Way (R : in out Aunit.Test_Cases.Test_Case'Class) is
      Start : Float := Pi/2.0;
      Final : Float := -Pi/2.0;
      Stopped : Boolean;
   begin
      -- rotating from 90 to -90 in neg direction (through 180)
      Hal.Sms.Motion ("dummy",
                      Start,
                      Final,
                      A,
                      5.0,
                      1.0,
                      1.0,
                      Stopped,
                      Cb_Check_M1'Access,
                      "",
                      Pos);

      -- rotating from 90 to -90 in neg direction (through 0)
      Hal.Sms.Motion ("dummy",
                      Start,
                      Final,
                      A,
                      5.0,
                      1.0,
                      1.0,
                      Stopped,
                      Cb_Check_M2'Access,
                      "",
                      Neg);

      -- rotating from 0 to 90 the long way around
      Start := 0.0;
      Final := Pi / 2.0;
      Hal.Sms.Motion ("dummy",
                      Start,
                      Final,
                      A,
                      5.0,
                      1.0,
                      1.0,
                      Stopped,
                      Cb_Check_M3'Access,
                      "",
                      Neg);


      -- rotating from 0 to 90 via the shortest route
      Start := 0.0;
      Final := Pi / 2.0;
      Hal.Sms.Motion ("dummy",
                      Start,
                      Final,
                      A,
                      5.0,
                      1.0,
                      1.0,
                      Stopped,
                      Cb_Check_M4'Access,
                      "",
                      Shortest_Route);

   end Test_Motion_Which_Way;


   --  Register test routines to call:
   procedure Register_Tests (T : in out Test_Case) is
   begin
      --  Repeat for each test routine.
      Register_Routine (T, Test_Rotation_Which_Way'Access,
                        "Test_Rotation_Which_Way");
      Register_Routine (T, Test_Motion_Which_Way'Access,
                        "Test_Motion_Which_Way");
   end Register_Tests;

   --  Identifier of test case:
   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Hal_Generic_Sms");
   end Name;

end Uut.Hal_Generic_Sms;
