with AUnit.Assertions; use AUnit.Assertions;
with Pace.Server.Dispatch;
with Uio.Server;
with Pace.Strings; use Pace.Strings;
with Pace;
with AUnit.Test_Cases; use AUnit.Test_Cases;
with AUnit.Test_Cases.Registration; use AUnit.Test_Cases.Registration;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Wmi_Pattern_Test is

   package Wmi renames Uio.Server;

   type Test_Wmi_Action is new Pace.Server.Dispatch.Action with null record;

   Action_Was_Called : Boolean := False;
   Received_Param : Unbounded_String;

   procedure Inout (Obj : in out Test_Wmi_Action);

   procedure Inout (Obj : in out Test_Wmi_Action) is
   begin
      Action_Was_Called := True;
   end Inout;

   procedure Set_Up (T : in out Test_Case) is
   begin
      Action_Was_Called := False;
      Received_Param := Null_Unbounded_String;
   end Set_Up;

   procedure Tear_Down (T : in out Test_Case) is
   begin
      null;
   end Tear_Down;

   procedure Test_Wmi_Call (T : in out AUnit.Test_Cases.Test_Case'Class) is
      P_Str : String := Wmi.P("key", "val");
   begin
      Assert (P_Str = "key=val", "Wmi.P(""key"", ""val"") returned " & P_Str);
      
      Pace.Server.Dispatch.Save_Action (Test_Wmi_Action'(Pace.Msg with Set => +"Default"));

      Wmi.Call ("WMI_PATTERN_TEST.TEST_WMI_ACTION", P_Str);

      Assert (Action_Was_Called, "Action was not called via Wmi.Call");

   end Test_Wmi_Call;

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Wmi_Call'Access, "Test_Wmi_Call");
   end Register_Tests;

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Wmi Pattern Test");
   end Name;

end Wmi_Pattern_Test;
