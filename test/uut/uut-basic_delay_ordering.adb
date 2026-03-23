with Ada.Text_Io;
with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;

with Pace.Log;

with Aunit.Test_Cases.Registration; use Aunit.Test_Cases.Registration;

with Aunit.Assertions; use Aunit.Assertions;

package body Uut.Basic_Delay_Ordering is

   function Id is new Pace.Log.Unit_Id;

   package Asu renames Ada.Strings.Unbounded;

   S : Asu.Unbounded_String;

   task type Appender (My_Id : Integer) is
      entry Init (Wait : Duration);
      entry Start;
      entry Done;
   end Appender;

   task body Appender is
      Counter : Integer := 0;
      My_Wait : Duration;
      My_Id_Str : String := Id & My_Id'Img;
   begin
      Pace.Log.Agent_Id (My_Id_Str);
      accept Init (Wait : Duration) do
         My_Wait := Wait;
      end Init;
      accept Start;
      while Counter < 5 loop
         Asu.Append (S, Ada.Strings.Fixed.Trim (My_Id'Img, Ada.Strings.Both));
         Pace.Log.Wait (My_Wait);
         Counter := Counter + 1;
      end loop;
      accept Done;
   exception
      when E : others =>
         Ada.Text_Io.Put_Line ("Caught exception!!!");
   end Appender;

   procedure Test_Ordering (T : in out Aunit.Test_Cases.Test_Case'Class) is
      A1 : Appender (1);
      A2 : Appender (2);
      A3 : Appender (3);
      A4 : Appender (4);
      A5 : Appender (5);
      A6 : Appender (6);
      A7 : Appender (7);
      A8 : Appender (8);
      A9 : Appender (9);
   begin

      A1.Init (1.0);
      A1.Start;
      Pace.Log.Wait (0.1);

      A2.Init (1.0);
      A2.Start;
      Pace.Log.Wait (0.1);

      A3.Init (1.0);
      A3.Start;
      Pace.Log.Wait (0.1);

      A4.Init (1.0);
      A4.Start;
      Pace.Log.Wait (0.1);

      A5.Init (1.0);
      A5.Start;
      Pace.Log.Wait (0.1);

      A6.Init (1.0);
      A6.Start;
      Pace.Log.Wait (0.1);

      A7.Init (1.0);
      A7.Start;
      Pace.Log.Wait (0.1);

      A8.Init (1.0);
      A8.Start;
      Pace.Log.Wait (0.1);

      A9.Init (1.0);
      A9.Start;
      Pace.Log.Wait (0.1);

      A1.Done;
      A2.Done;
      A3.Done;
      A4.Done;
      A5.Done;
      A6.Done;
      A7.Done;
      A8.Done;
      A9.Done;

      declare
         use Ada.Strings.Unbounded;
         Expected : Unbounded_String := Null_Unbounded_String;
         The_Order : String := "123456789";
      begin
         for J in 1 .. 5 loop
            Append (Expected, The_Order);
         end loop;

         Assert (S = Expected, "Expected order of appending to be " & To_String (Expected) & " but was " & To_String (S));
      end;
   end Test_Ordering;

   -- Name --
   ----------

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Basic_Delay_Ordering");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine(T, Test_Ordering'Access, "Test_Ordering");
   end Register_Tests;

   -- $Id: uut-basic_delay_ordering.adb,v 1.3 2006/03/31 20:58:22 ludwiglj Exp $
end Uut.Basic_Delay_Ordering;
