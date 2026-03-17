with Ada.Containers;
with Ada.Strings.Hash;
with Ada.Strings.Unbounded.Hash;
with Ada.Tags;

package Pace.Hash_Table is
   --------------------------------------------------------------
   -- HASH_TABLE -- Reentrant safe
   --------------------------------------------------------------
   pragma Elaborate_Body;

   subtype Hash_Type is Ada.Containers.Hash_Type;

   -------------------
   -- Simple_HTable --
   -------------------

   --  A simple hash table abstraction, easy to instanciate, easy to use.
   --  The table associates one element to one key with the procedure Set.
   --  Get retreives the Element stored for a given Key. The efficiency of
   --  retrieval is function of the size of the Table parameterized by
   --  Header_Num and the hashing function Hash.

   generic

      type Element is private;
      --  The type of element to be stored

      No_Element : Element;
      --  The object that is returned by Get when no element has been set for
      --  a given key

      type Key is private;
      with function Hash (F : Key) return Hash_Type;
      with function Equal (F1, F2 : Key) return Boolean;

   package Simple_Htable is

      procedure Set (K : Key; E : Element);
      --  Associate an element with a given key. Overrides any previously
      --  associated element.

      function Get (K : Key) return Element;
      --  Returns the Element associated wtih a key or No_Element if the
      --  given key has not associated element

      package Iterator is -- Iterates through the Hash Table
         procedure Reset;
         function Next return Element;
         function Done return Boolean;
      end Iterator;

   end Simple_Htable;


   ----------
   -- Hash --
   ----------

   --  Hashing functions working on String keys
   function Hash (Key : String) return Hash_Type renames Ada.Strings.Hash;
   function Hash (Key : Ada.Strings.Unbounded.Unbounded_String) 
     return Hash_Type renames Ada.Strings.Unbounded.Hash;

   --  Hashing function working on Tag keys
   function Hash (Key : Ada.Tags.Tag) return Hash_Type;

------------------------------------------------------------------------------
-- $Id: pace-hash_table.ads,v 1.1 2006/03/15 22:54:09 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Hash_Table;
