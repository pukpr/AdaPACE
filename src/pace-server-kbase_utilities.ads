with Pace.Rule_Process;
with Ada.Strings.Unbounded;

package Pace.Server.Kbase_Utilities is

   pragma Elaborate_Body;

   function Kbase_To_Xml (Agent : in Pace.Rule_Process.Agent_Type;
                          Query : in Ada.Strings.Unbounded.Unbounded_String;
                          Is_Xml_Tree : Boolean;
                          Remove_Quotes : Boolean := False) return String;
   -- Queries kbase and returns a String in XML.
   -- if Xml_Tree is true then return string in a hierarchy format, and
   -- if it is false then return string in a list format

   procedure Xml_To_Kbase (Agent : in Pace.Rule_Process.Agent_Type;
                           Xml : in Ada.Strings.Unbounded.Unbounded_String;
                           Functor : String := "");
   -- Asserts a XML tree into KBase, using funtor as the search element


   procedure Query_Kbase
               (Agent : in Pace.Rule_Process.Agent_Type;
                Query : in out Ada.Strings.Unbounded.Unbounded_String);
   -- Queries kbase and puts xml data back through the server to the client.


   function Get_List (Text : in String; Delimiter : in Character := ' ')
                     return Pace.Rule_Process.Variables;
   -- Gets elements from a space-delimited list, eliminating parentheses
   -- if Delimiter is a space, then will assume quotes may be included in Text
   -- and will ensure that spaces inside of quotes do not act as delimiters.
   -- if Delimiter is anything else (i.e. a hard tab: Ascii.HT), then will
   -- simply use Delimiter as the delimiter (thus assuming no quotes in Text)


   function List_To_Xml (Text : in String;
                         Delimiter : in Character := ' ';
                         Xml_Tag : in String) return String;
   -- Same as Get_List above, but instead of returning Variables, returns
   -- an Xml String with the tag name as Xml_Tag.


   type List_Key_Pair is
      record
         Text : Ada.Strings.Unbounded.Unbounded_String;
         Xml_Tag : Ada.Strings.Unbounded.Unbounded_String;
      end record;

   type List_Key_Array is array (Integer range <>) of List_Key_Pair;

   function Lists_To_Xml (Lists : in List_Key_Array;
                          Delimiter : in Character := ' ';
                          Xml_Tag : in String) return String;
   -- Takes in multiple lists of the same size and delimited by the same
   -- character and merges the lists together into one xml string with
   -- tags corresponding to Lists.Xml_Tag and encapsulated within Xml_Tag

   -- $id: pace-server-kbase_utilities.ads,v 1.3 05/22/2003 21:18:19 pukitepa Exp $
end Pace.Server.Kbase_Utilities;
