with Pace.Server.Xml;
with Ada.Strings.Unbounded;
with Ada.Characters.Handling;
with Gnu.Xml_Tree.Kbase;
with Text_Io;

function Pace.Kbase_To_Xml (Agent : in Gnu.Rule_Process.Agent_Type;
                            Query : in Ada.Strings.Unbounded.Unbounded_String;
                            Is_Xml_Tree : Boolean) return String is

   package Asu renames Ada.Strings.Unbounded;

   S : Asu.Unbounded_String := Asu.Null_Unbounded_String;

   procedure Xml_Display (Key, Val : in String) is
      use Asu;
   begin
      if Is_Xml_Tree then
         S := S & Val & " ";
      else
         S := S & Pace.Server.Xml.Item
                    (Element => Ada.Characters.Handling.To_Lower (Key),
                     Value => Val);
      end if;
   end Xml_Display;

   procedure Xml_Tree_Display (Text : in String) is
      use Asu;
   begin
      S := S & Text;
   end Xml_Tree_Display;

   Root : Gnu.Xml_Tree.Kbase.Tree;

begin
   Agent.Query (Asu.To_String (Query), Xml_Display'Unrestricted_Access);
   --Pace.Display (":" & Asu.To_String (S));

   if Is_Xml_Tree then
      Gnu.Xml_Tree.Kbase.Parse (Asu.To_String (S), Root);
      S := Asu.Null_Unbounded_String;
      Gnu.Xml_Tree.Kbase.Print (Root, 0, Xml_Tree_Display'Unrestricted_Access);
   end if;
   return Asu.To_String (S);

-- $id: pace-kbase_to_xml.adb,v 1.2 12/13/2002 23:55:16 pukitepa Exp $
end Pace.Kbase_To_Xml;
