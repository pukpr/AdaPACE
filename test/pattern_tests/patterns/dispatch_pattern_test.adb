with AUnit.Assertions; use AUnit.Assertions;
with Pace.Server.Dispatch; use Pace.Server.Dispatch;
with Pace.Strings; use Pace.Strings;
with Pace;
with AUnit.Test_Cases; use AUnit.Test_Cases;
with AUnit.Test_Cases.Registration; use AUnit.Test_Cases.Registration;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Dispatch_Pattern_Test is

   type Test_Action is new Action with null record;

   Action_Was_Called : Boolean := False;

   procedure Inout (Obj : in out Test_Action);

   procedure Inout (Obj : in out Test_Action) is
   begin
      Action_Was_Called := True;
   end Inout;

   procedure Set_Up (T : in out Test_Case) is
   begin
      Action_Was_Called := False;
   end Set_Up;

   procedure Tear_Down (T : in out Test_Case) is
   begin
      null;
   end Tear_Down;

   procedure Test_Save_And_Dispatch (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Result : Unbounded_String;
      R_Bool : Boolean;
   begin
      Save_Action (Test_Action'(Pace.Msg with Set => +"Default"));

      Result := To_Unbounded_String(Dispatch_To_Action ("DISPATCH_PATTERN_TEST.TEST_ACTION"));

      Assert (Action_Was_Called, "Action was not called via Dispatch_To_Action (Name: DISPATCH_PATTERN_TEST.TEST_ACTION, Result: " & To_String(Result) & ")");
      
      Action_Was_Called := False;
      R_Bool := Dispatch_To_Action ("DISPATCH_PATTERN_TEST.TEST_ACTION");
      Assert (R_Bool, "Dispatch_To_Action (Boolean) returned False");
      Assert (Action_Was_Called, "Action was not called via Dispatch_To_Action (Boolean)");

   end Test_Save_And_Dispatch;

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Save_And_Dispatch'Access, "Test_Save_And_Dispatch");
   end Register_Tests;

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Dispatch Pattern Test");
   end Name;

end Dispatch_Pattern_Test;
