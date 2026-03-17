with Ada.Strings.Unbounded;

package Gnu.Xml_Tree.Kbase is
   -----------------------------------------------------------
   -- Transforming XML from/to KBase format
   -----------------------------------------------------------

   type Tree is new Gnu.Xml_Tree.Tree with null record;
   procedure Parse (Text : String; Root : out Tree);
   --  Transform internal (lisp) KBase representation into an XML Tree.


   type Kb_Fact is new Gnu.Xml_Tree.Tree with private;
   function Get_Fact (Root : in Kb_Fact) return String;
   --  Transform XML format into external (prolog) KBase representation.
   --  protocol: 1. Parse 2. Search 3. Get_Fact

private

   type Kb_Fact is new Gnu.Xml_Tree.Tree with
      record
         Data : Ada.Strings.Unbounded.Unbounded_String;
         Comma : Boolean := False;
      end record;

   procedure Callback (Root : in out Kb_Fact;
                       Tag, Value, Attributes : in String);

------------------------------------------------------------------------------
-- $id: gnu-xml_tree-kbase.ads,v 1.2 05/22/2003 21:17:44 pukitepa Exp $
------------------------------------------------------------------------------
end Gnu.Xml_Tree.Kbase;
