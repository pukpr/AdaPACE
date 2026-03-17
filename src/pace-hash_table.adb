with Ada.Containers.Indefinite_Hashed_Maps;
pragma Elaborate_All (Ada.Containers.Indefinite_Hashed_Maps);
with Ada.Strings.Hash;
with Unchecked_Conversion;
with Interfaces;
with Ada.Assertions;

package body Pace.Hash_Table is

   --------------------
   --  Simple_HTable --
   --------------------

   package body Simple_Htable is

      package Maps is new Ada.Containers.Indefinite_Hashed_Maps 
        (Key, Element, Hash, Equal);

      M : Maps.Map;
      
      protected Lock is
         procedure Set (K : Key; E : Element);
         function Get (K : Key) return Element;
         procedure Reset;
         procedure Next (E : out Element);
         function Done return Boolean;
      private
         C : Maps.Cursor;
         First : Boolean := True;
      end Lock;

      protected body Lock is
         procedure Set (K : Key; E : Element) is
         begin
            if Maps.Contains (M, K) then
               Maps.Replace (M, K, E);
            else
               Maps.Insert (M, K, E);
            end if;
         end Set;

         function Get (K : Key) return Element is
         begin
            if Maps.Contains (M, K) then
               return Maps.Element (M, K);
            else
               return No_Element;
            end if;
         end Get;

         procedure Reset is
         begin
            C := Maps.First (M);
            First := True;
         end Reset;

         procedure Next (E : out Element) is
         begin
            if First then
               First := False;
            else
               C := Maps.Next (C);
            end if;
            if Done then
               E := No_Element;
            else
               E := Maps.Element (C);
            end if;
         end Next;

         function Done return Boolean is
         begin
            return not Maps.Has_Element (C);
         end Done;
      end Lock;

      procedure Set (K : Key; E : Element) is
      begin
         Lock.Set (K, E);
      end Set;

      function Get (K : Key) return Element is
      begin
         return Lock.Get (K);
      end Get;

      package body Iterator is
         procedure Reset is
         begin
            Lock.Reset;
         end Reset;
         function Next return Element is
            E : Element;
         begin
            Lock.Next (E);
            return E;
         end Next;
         function Done return Boolean is
         begin
            return Lock.Done;
         end Done;
      end Iterator;

   end Simple_Htable;


   function Hash (Key : Ada.Tags.Tag) return Ada.Containers.Hash_Type is
      Size : constant Integer := Key'Size/8;
      type Long_Byte_Array is array (1..Size) of Interfaces.Unsigned_8;
      function To_Bytes is new Unchecked_Conversion (
                            Ada.Tags.Tag,
                            Long_Byte_Array);
      type Byte_Array is array (1..4) of Interfaces.Unsigned_8;
      function To_Hash is new Unchecked_Conversion (
                            Byte_Array,
                            Ada.Containers.Hash_Type);
                            
      Bytes : constant Long_Byte_Array := To_Bytes (Key);
   begin
      Ada.Assertions.Assert (Size >= 4, "Key Tag must be greater then or equal to 4 Bytes");
      return To_Hash (Byte_Array(Bytes(1..4)));
   end Hash;

------------------------------------------------------------------------------
-- $Id: pace-hash_table.adb,v 1.1 2006/03/15 22:54:09 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Hash_Table;
