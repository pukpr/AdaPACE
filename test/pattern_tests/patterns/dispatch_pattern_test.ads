with AUnit.Test_Cases;
with Ada.Strings.Unbounded;

package Dispatch_Pattern_Test is
   
   type Test_Case is new AUnit.Test_Cases.Test_Case with record
      Was_Called : Boolean := False;
   end record;

   procedure Register_Tests (T : in out Test_Case);
   function Name (T : Test_Case) return Ada.Strings.Unbounded.String_Access;
   procedure Set_Up (T : in out Test_Case);
   procedure Tear_Down (T : in out Test_Case);

end Dispatch_Pattern_Test;
