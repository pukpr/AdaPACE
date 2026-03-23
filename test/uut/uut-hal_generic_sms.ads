with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

with Aunit.Test_Cases;
use Aunit.Test_Cases;
package Uut.Hal_Generic_Sms is
   type Test_Case is new Aunit.Test_Cases.Test_Case with null record;

   --  Override:

   --  Register routines to be run:
   procedure Register_Tests (T : in out Test_Case);

   --  Provide name identifying the test case:
   function Name (T : Test_Case) return String_Access;


end Uut.Hal_Generic_Sms;
