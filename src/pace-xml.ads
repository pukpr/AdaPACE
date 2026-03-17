with Dom.Core;
with Ada.Strings.Unbounded;
with Ada.Finalization;

package Pace.Xml is
   -----------------------------------------------------------
   -- XML -- Parsing eXtensible Markup Language
   -----------------------------------------------------------
   subtype Node is Dom.Core.Node;
   subtype Node_Types is Dom.Core.Node_Types;
   
   type Doc_Type is tagged limited private;
   procedure Initialize (Object : in out Doc_Type);
   procedure Finalize (Object : in out Doc_Type);

   function Parse (Xml : String) return Doc_Type;

   function Value (N : Dom.Core.Node;
                  Ntype : Dom.Core.Node_Types := Dom.Core.Text_Node) return String;
   function Tag_Name (N : Dom.Core.Node) return String;

   -- Searches an XML tree for a single key.
   -- The first instance is returned. Default if not found.
   function Search_Xml (Xml : in Doc_Type;
                       Key : in String;
                       Default : in String := "") return String;

   -- Searches an XML tree for a single key.
   -- The first instance is returned. Default if not found.
   -- If you will be calling search_xml on the same xml string more than once then parse the xml once
   -- and use the method above instead.
   function Search_Xml (Xml : in String;
                       Key : in String;
                       Default : in String := "") return String;

   type Strings is array (Natural range <>) of Ada.Strings.Unbounded.Unbounded_String;

   -- Searches an XML tree for a single key.
   -- All values returned in an array of unbounded strings, empty array if not found.
   function Search_Xml (Xml : in String;
                       Key : in String) return Strings;

   function Search_Xml (Xml : in Doc_Type;
                       Key : in String) return Strings;

   -- return the first tag with element Key in the Document
   function Get_Tag_From_Doc (Xml : in Doc_Type;
                             Key : in String) return Dom.Core.Node;

   -- return the first tag with element Key in the Node
   function Get_Tag (Xml : in Dom.Core.Node;
                    Key : in String) return Dom.Core.Node;

   -- returns the string representation of the node and all its children and grand-children, etc.
   -- currently includes element tags, text values, and attributes, but nothing else!
   function To_String (Xml : in Dom.Core.Node) return String;

   -----------------------------------------------------------------------
   -- Tag construction A=Attribute Pairs  T=Tag Composites
   -----------------------------------------------------------------------
   function A (Key, Value : in String) return String;
   function A (Key : in String; Value : in Integer) return String;
   function A (Key : in String; Value : in Float) return String;

   function T (Element : in String;
               Value : in String;
               Attribute : in String := "") return String;
   function T (Element : in String;
               Value : in Integer;
               Attribute : in String := "") return String;
   function T (Element : in String;
               Value : in Float;
               Attribute : in String := "") return String;
   function T (Element : in String;
               Value : in Long_Float;
               Attribute : in String := "") return String;
   function T (Element : in String;
               Value : in Boolean;
               Attribute : in String := "") return String;
   function T (Element : in String) return String;

private

   type Doc_Type is new Ada.Finalization.Limited_Controlled with
      record
         D : Dom.Core.Document;
      end record;

end Pace.Xml;
