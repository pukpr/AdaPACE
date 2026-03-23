with Aunit.Test_Cases.Registration;
use Aunit.Test_Cases.Registration;

with Aunit.Assertions;
use Aunit.Assertions;

with Ada.Strings.Unbounded;
with Ada.Text_Io;
with Ada.Exceptions;

with Pace.Xml;
with Dom.Core;
with Pace.Server.Xml;
with Pace.Strings;
with Ual.Utilities;

package body Uut.Pace_Xml is

   package Asu renames Ada.Strings.Unbounded;

   procedure Test_Search_Xml (R : in out Aunit.Test_Cases.Test_Case'Class);

   procedure Set_Up (T : in out Test_Case) is
   begin
      null;
   end Set_Up;

   procedure Tear_Down (T : in out Test_Case) is
   begin
      null;
   end Tear_Down;

   procedure Check_For_Tag (Xml : String; Key : String; Expected : String; Default : String := "") is
      use Pace.Xml;
      Result : String := Search_Xml (Xml, Key, Default);
   begin
      Assert (Result = Expected,
              "Search_Xml (first element) failed: Expected " & Expected & " but actual is " & Result);
   end Check_For_tag;

   procedure Test_Search_Xml (R : in out Aunit.Test_Cases.Test_Case'Class) is
      use Pace.Xml;
      First_Species : String := "Black Bear";
      Second_Species : String := "Timber Wolf";
      Xml : String := "<zoo><animal><species>" & First_Species & "</species><behavior>Omnivore</behavior></animal><animal><species>" & Second_Species & "</species><behavior>Carnivore</behavior></animal></zoo>";
      Empty_String : String := "";
   begin

      Check_For_Tag (Xml, "species", First_Species);
      Check_For_Tag (Empty_String, "subsystem", "ALL", "ALL");

      -- check empty string using parse directly
      declare
         Doc : Pace.Xml.Doc_Type := Parse ("");
         Result : String := Search_Xml (Doc, "foo", "default");
      begin
         Assert (Result = "default", "Failed to parse empty string using the Parse and Search_Xml approach.");
      end;

      declare
         Result : Strings := Search_Xml (Xml, "species");
      begin
         Assert (Result'Length = 2, "Search_Xml (all elements) failed: Expected 2 species but found " & Result'Length'Img);
         Assert (Result(Result'First) = First_Species,
                 "Search_Xml (all elements) failed: Expected " & First_Species & " but actual is " & Asu.To_String (Result(Result'First)));
         Assert (Result(Result'First+1) = Second_Species,
                 "Search_Xml (all elements) failed: Expected " & Second_Species & " but actual is " & Asu.To_String (Result(Result'First + 1)));
      end;

   end Test_Search_Xml;

   procedure Test_Search_Xml_Whitespace (R : in out Aunit.Test_Cases.Test_Case'Class) is
      use Pace.Xml;
      Xml : String := Ual.Utilities.File_To_String ("uut-xml.txt");
   begin
      Ada.Text_Io.Put_Line ("xml with whitespace is: ");
      Ada.Text_Io.Put_Line (Xml);
      declare
         Expected : String := "M107";
         Result : String := Search_Xml (Xml, "projo_type");
      begin
         Assert (Pace.Strings.Trim (Result) = Expected, "Trim failed to trim newlines!. Expected is :" & Expected & ": but actual is :" & Result & ":");
         Assert (Result = Expected, "Did not match. Expected is :" & Expected & ": but actual is :" & Result & ":");
      end;
   end Test_Search_Xml_Whitespace;

   procedure Test_Empty_Value (R : in out Aunit.Test_Cases.Test_Case'Class) is
      use Pace.Xml;
      use Pace.Server.Xml;
      Xml1 : String := Item ("xml", "<prop></prop>");
      Xml2 : String := Item ("xml", "<prop/>");
   begin
      Check_For_Tag (Xml1, "prop", "", "NA");
      Check_For_Tag (Xml2, "prop", "", "NA");
      Check_For_Tag (Xml1, "projo", "NA", "NA");
      Check_For_Tag (Xml2, "projo", "NA", "NA");
   end Test_Empty_Value;

   procedure Test_Get_Tag (R : in out Aunit.Test_Cases.Test_Case'Class) is
      use Pace.Xml;
      use Pace.Server.Xml;
      use Dom.Core;
      Expected_Plan_Uid : String := "1";
      Expected_Prop_Uid : String := "5";
      Xml : String := Item ("plan",
                            Item ("uid", Expected_Plan_Uid) &
                            Item ("prop", Item ("uid", Expected_Prop_Uid)));
      Doc : Doc_Type := Parse (Xml);
      Plan_Uid_Node : Dom.Core.Node := Get_Tag_From_Doc (Doc, "uid");
      Prop_Node : Dom.Core.Node := Get_Tag_From_Doc (Doc, "prop");
      Prop_Uid_Node : Dom.Core.Node := Get_Tag (Prop_Node, "uid");
   begin
      Assert (Value (Plan_Uid_Node) = Expected_Plan_Uid, "Plan_Uid_Node: Expected " & Expected_Plan_Uid & " but was " & Value (Plan_Uid_Node));
      Assert (Value (Prop_Uid_Node) = Expected_Prop_Uid, "Prop_Uid_Node: Expected " & Expected_Prop_Uid & " but was " & Value (Prop_Uid_Node));
   end Test_Get_Tag;

   procedure Test_To_String (R : in out Aunit.Test_Cases.Test_Case'Class) is
      use Pace.Xml;
      use Dom.Core;
      use Pace.Server.Xml;
      Data : String := Item ("data",
                             Item ("hello",
                                   Item ("leaf", "1", Pair ("a", "7") & Pair ("b", "5")) &
                                   Item ("leaf", "2")) &
                             Item ("world",
                                   Item ("africa",
                                         Item ("leaf", "3"))));
      Msg_Type : String := Item ("msg_type", "fire order");
      Xml : String := Item ("msg",
                            Msg_Type &
                            Data);
      Doc : Doc_Type := Parse (Xml);
      Data_Node : Dom.Core.Node := Get_Tag_From_Doc (Doc, "data");
      Msg_Type_Node : Dom.Core.Node := Get_Tag_From_Doc (Doc, "msg_type");
   begin
      Assert (To_String (Data_Node) = Data,
              "Expected " & Data & " but was " & To_String (Data_Node));
      Assert (To_String (Msg_Type_Node) = Msg_Type,
              "Expected " & Msg_Type & " but was " & To_String (Msg_Type_Node));
   end Test_To_String;

   --  Register test routines to call:
   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Search_Xml'Access, "Test_Search_Xml");
      Register_Routine (T, Test_Search_Xml_Whitespace'Access,
                        "Test_Search_Xml_Whitespace");
      Register_Routine (T, Test_Empty_Value'Access,
                        "Test_Empty_Value");
      Register_Routine (T, Test_Get_Tag'Access, "Test_Get_Tag");
      Register_Routine (T, Test_To_String'Access, "Test_To_String");
   end Register_Tests;

   --  Identifier of test case:
   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Pace_Xml");
   end Name;

end Uut.Pace_Xml;
