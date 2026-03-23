with Aunit.Test_Cases.Registration;
use Aunit.Test_Cases.Registration;

with Aunit.Assertions;
use Aunit.Assertions;

with Pace.Xml_Tree;
use Pace.Xml_Tree;
with Ada.Strings.Unbounded;

--  Template for test case body.
package body Uut.Gnu_Xml_Tree is

   package Asu renames Ada.Strings.Unbounded;

   procedure Test_Get_Field (R : in out Aunit.Test_Cases.Test_Case'Class);
   procedure Test_Get_Attribute (R : in out Aunit.Test_Cases.Test_Case'Class);

   Xml1 : String :=
     "<animals><omnivore><bear id='1' age='40'><kind>black</kind></bear></omnivore><carnivore><canine><type stuff='blah'>Timber Wolf</type></canine></carnivore></animals>";
   Xml1_Tree : Tree;

   procedure Set_Up (T : in out Test_Case) is
   begin
      Parse (Xml1, Xml1_Tree);
   end Set_Up;

   procedure Tear_Down (T : in out Test_Case) is
   begin
      --  Do any necessary cleanups, so the next test
      --  has a clean environment.  If there is no
      --  cleanup, omit spec and body, as default is
      --  provided in Test_Cases.
      null;
   end Tear_Down;


   procedure Test_Get_Field (R : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      declare
         Result : String := Get_Field (Xml1_Tree, "kind", "hello");
      begin
         Assert
           (Result = "black",
            "Get_Field failed to find the correct value. Expected 'black' but found '" &
              Result & "'");
      end;

      declare
         Result : String := Get_Field (Xml1_Tree, "type");
      begin
         Assert
           (Result = "Timber Wolf",
            "Get_Field failed to find the correct value. Expected 'Timber Wolf' but found '" &
              Result & "'");
      end;

      declare
         Result : String := Get_Field (Xml1_Tree, "not", "blah");
      begin
         Assert
           (Result = "blah",
            "Get_Field failed to return the default upon not finding the element name.  Instead returned '" &
              Result & "'");
      end;

      declare
         Result : String := Get_Field (Xml1_Tree, "not");
      begin
         Assert
           (Result = "",
            "Get_Field failed to return the default default upon not finding the element name.  Instead returned '" &
              Result & "'");
      end;

   end Test_Get_Field;

   procedure Test_Get_Attribute (R : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      declare
         Result : String := Get_Attribute (Xml1_Tree, "bear", "id");
      begin
         Assert
           (Result = "1",
            "Get_Attribute failed to find the correct value.  Expected '1' but found '" &
              Result & "'");
      end;

      declare
         Result : String := Get_Attribute (Xml1_Tree, "bear", "age", "30");
      begin
         Assert
           (Result = "40",
            "Get_Attribute failed to find the correct value.  Expected '40' but found '" &
              Result & "'");
      end;

      declare
         Result : String := Get_Attribute (Xml1_Tree, "type", "stuff");
      begin
         Assert
           (Result = "blah",
            "Get_Attribute failed to find the correct value.  Expected 'blah' but found '" &
              Result & "'");
      end;

      declare
         Result : String := Get_Attribute (Xml1_Tree, "type", "not", "hi");
      begin
         Assert
           (Result = "hi",
            "Get_Attribute failed to return the default upon not finding the attribute name.  Instead returned '" &
              Result & "'");
      end;

      declare
         Result : String := Get_Attribute (Xml1_Tree, "dog", "id");
      begin
         Assert
           (Result = "",
            "Get_Attribute failed to return the default upon not finding the element name.  Instead returned '" &
              Result & "'");
      end;

   end Test_Get_Attribute;


   --  Register test routines to call:
   procedure Register_Tests (T : in out Test_Case) is
   begin
      --  Repeat for each test routine.
      Register_Routine (T, Test_Get_Field'Access, "Test_Get_Field");
      Register_Routine (T, Test_Get_Attribute'Access, "Test_Get_Attribute");
   end Register_Tests;

   --  Identifier of test case:
   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Gnu_Xml_Tree");
   end Name;

end Uut.Gnu_Xml_Tree;
