
with Ada.Strings.Unbounded;
with AUnit.Test_Cases;
package Uut.Pubs is

   use Ada.Strings.Unbounded, AUnit.Test_Cases;
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test_Case);
   --  Register routines to be run

   function Name (T : Test_Case) return String_Access;
   --  Returns name identifying the test case
end;
