with Ada.Text_Io;
with Pace.Log;

with Aunit.Test_Cases.Registration; use Aunit.Test_Cases.Registration;

with Aunit.Assertions; use Aunit.Assertions;

package body Uut.Time_Precision is

   function Id is new Pace.Log.Unit_Id;

   task B is
      entry Start;
      entry Done;
   end B;

   task body B is
      Denominator : Positive := 10;
   begin
      Pace.Log.Agent_Id (Id & "B");
      accept Start;
      loop
         exit when Denominator = 1000000000;

         declare
            D : Duration := Duration (1) / Duration (Denominator);
         begin
--             if D < 0.000001 then
--                D := 0.000001;
--             end if;
            Ada.Text_Io.Put_Line ("delaying " & D'Img);
            Pace.Log.Wait (D);
         end;

         Denominator := Denominator * 10;
      end loop;
      accept Done;
   end B;


   procedure Test_Precision (T : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      B.Start;
      B.Done;
      Assert (True, "ada runtime did not loop forever");
   end Test_Precision;

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Time_Precision");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine
        (T,
         Test_Precision'Access,
         "Test_Precision");
   end Register_Tests;

end Uut.Time_Precision;
