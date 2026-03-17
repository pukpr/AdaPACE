with Ada.Strings.Unbounded;
with Ada.Finalization;

package Gnu.Xml_Tree is
   -----------------------------------------------------------
   -- XML -- Parsing eXtensible Markup Language
   -----------------------------------------------------------
   use Ada.Strings.Unbounded;

   type Tree is new Ada.Finalization.Limited_Controlled with private;
   procedure Finalize (Root : in out Tree);
   procedure Callback (Root : in out Tree; Tag, Value, Attributes : in String);

   procedure Parse (Text : String; Root : out Tree);
   --  Parse File and return the first node representing the XML file.

   type Print_Callback is access procedure (Text : in String);
   procedure Print (Root : in Tree;
                    Indent : in Natural := 0;
                    Display : in Print_Callback := null);
   --  Simple print procedure. Print the whole tree starting with N.

   procedure Search (Root : in out Tree);
   --  For each leaf node in tree callback a Tag/Value pair with optional Attribute
   --   <Tag Attributes="">Value</Tag>

   --
   -- Functions to get first instances of specific fields.
   -- Caution: These may be repeated in the hierarchy
   --
   function Get_Field (Root : Tree; Name : String; Default : String := "")
                      return String;
   function Get_Field (Root : Tree; Name : String; Default : String := "")
                      return Unbounded_String;
   --  Return the value of the field 'Name' if present in the children of N,
   --  null otherwise (uses Find_Tag)

   function Get_Attribute (Root : Tree;
                           Name : String;
                           Attribute_Name : String;
                           Default : String := "") return String;
   function Get_Attribute (Root : Tree;
                           Name : String;
                           Attribute_Name : String;
                           Default : String := "") return Unbounded_String;
   --  Return the value of the attibute 'Attribute_Name' if present,
   --  null otherwise

   ------------------------------------------------------------------------
   -- Convenience functions
   ------------------------------------------------------------------------

   -- Searches an XML tree for a single key.
   -- The first instance is returned. Default if not found.
   function Search_Xml
              (Tree : in String; Key : in String; Default : in String := "")
              return String;

   type Strings is array (Natural range <>) of Unbounded_String;

   -- Searches an XML tree for a single key.
   -- All values returned in an array of unbounded strings, empty array if not found.
   function Search_Xml
              (Tree : in String; Key : in String)
              return Strings;

private

   type Node;
   type Node_Ptr is access all Node;
   type Node is
      record
         Tag : Unbounded_String;
         --  The name of this node

         Attributes : Unbounded_String;
         --  The attributes of this node

         Value : Unbounded_String;
         --  The value, or null is not relevant

         Parent : Node_Ptr;
         --  The parent of this Node.

         Child : Node_Ptr;
         --  The first Child of this Node. The next child is Child.Next

         Next : Node_Ptr;
         --  Next "brother" node.

         Accessed : Boolean := False;
         --  Use to store data specific to each implementation (e.g a boolean
         --  indicating whether this node has been accessed)
      end record;

   type Tree is new Ada.Finalization.Limited_Controlled with
      record
         N : Node_Ptr;
      end record;

   procedure Get_Buf (Buf : String;
                      Index : in out Natural;
                      Terminator : Character;
                      S : out Unbounded_String);
   --  On return, S will contain the String starting at Buf (Index) and
   --  terminating before the first 'Terminator' character. Index will also
   --  point to the next non blank character.

   procedure Skip_Blanks (Buf : String; Index : in out Natural);
   --  Skip blanks, LF and CR, starting at Index. Index is updated to the
   --  new position (first non blank or EOF)

------------------------------------------------------------------------------
-- $id: gnu-xml_tree.ads,v 1.3 07/31/2003 15:33:16 ludwiglj Exp $
------------------------------------------------------------------------------
end Gnu.Xml_Tree;
