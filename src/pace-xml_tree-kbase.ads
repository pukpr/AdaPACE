with Ada.Strings.Unbounded;

package Pace.Xml_Tree.Kbase is
   -----------------------------------------------------------
   -- Transforming XML from/to KBase format
   -----------------------------------------------------------

   type Tree is new Pace.Xml_Tree.Tree with null record;
   procedure Parse (Text : String; Root : out Tree);
   --  Transform internal (lisp) KBase representation into an XML Tree.
   --  Then treat the tree as a normal XML data structure

   type Kb_Fact is new Pace.Xml_Tree.Tree with private;
   function Get_Fact (Root : in Kb_Fact) return String;
   --  Transform XML format into external (prolog) KBase representation.
   --  protocol: 
   --   1. Parse XML string into Root
   --   2. Search Root, hidden callback collects the entire data
   --   3. Get_Fact returns the hierarchical Prolog structure
   --   4. Assert "fact" string into Kbase

private

   type Kb_Fact is new Pace.Xml_Tree.Tree with
      record
         Data : Ada.Strings.Unbounded.Unbounded_String;
         Comma : Boolean := False;
      end record;

   procedure Callback (Root : in out Kb_Fact;
                       Tag, Value, Attributes : in String);

------------------------------------------------------------------------------
-- $Id: pace-xml_tree-kbase.ads,v 1.1 2006/04/06 14:56:31 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Xml_Tree.Kbase;
