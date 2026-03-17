with Ada.Strings.Bounded;
with Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Hash;
with Ada.Strings.Hash;
with Ada.Containers.Hashed_Sets;
with Ada.Containers.Vectors;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Indefinite_Doubly_Linked_Lists;

package Pace.Strings is

   pragma Elaborate_Body;
   BS_Length : constant Integer := Pace.Getenv ("PACE_STRING", 50);
   BT_Length : constant Integer := Pace.Getenv ("PACE_TEXT", 150);

   package Bstr is new Ada.Strings.Bounded.Generic_Bounded_Length (BS_Length);
   subtype Bs is Bstr.Bounded_String;

   package Btext is new Ada.Strings.Bounded.Generic_Bounded_Length (BT_Length);
   subtype Bt is Btext.Bounded_String;

   package Ustr renames Ada.Strings.Unbounded;
   subtype Us is Ustr.Unbounded_String;

   ---- SMALL bounded strings <-> Fixed & Unbounded

   function Bstr_To_Str (Str : Bs) return String;
   function B2s (Str : Bs) return String renames Bstr_To_Str;

   function Str_To_Bstr (Str : String) return Bs;
   function S2b (Str : String) return Bs renames Str_To_Bstr;

   function Str_To_Ustr (Str : String) return Us;
   function S2u (Str : String) return Us renames Str_To_Ustr;

   function Bstr_To_Ustr (Str : Bs) return Us;
   function B2u (Str : Bs) return Us renames Bstr_To_Ustr;

   function Ustr_To_Bstr (Str : Us) return Bs;
   function U2b (Str : Us) return Bs renames Ustr_To_Bstr;

   function Ustr_To_Str (Str : Us) return String;
   function U2s (Str : Us) return String renames Ustr_To_Str;

   ---- LARGE bounded strings <-> Fixed & Unbounded
   function Btext_To_Str (Str : Bt) return String;
   function Str_To_Btext (Str : String) return Bt;
   function Btext_To_Ustr (Str : Bt) return Us;
   function Ustr_To_Btext (Str : Us) return Bt;

   function Bt2s (Str : Bt) return String renames Btext_To_Str;
   function S2Bt (Str : String) return Bt renames Str_To_Btext;
   function Bt2u (Str : Bt) return Us renames Btext_To_Ustr;
   function U2Bt (Str : Us) return Bt renames Ustr_To_Btext;

   -- nest the unbounded strings in case exposed elsewhere
   package UB is

   end UB;


   -- Data structures of strings
   --
   function Hash (Key : Bs) return Ada.Containers.Hash_Type;

   function Hash (Key : Us) return Ada.Containers.Hash_Type;

   package Bstr_Hashset is new Ada.Containers.Hashed_Sets (Element_Type => Bs,
                                                           Hash => Pace.Strings.Hash,
                                                           Equivalent_Elements => Bstr."=",
                                                           "=" => Bstr."=");

   package Ustr_Hashset is new Ada.Containers.Hashed_Sets (Element_Type => Us,
                                                           Hash => Ustr.Hash,
                                                           Equivalent_Elements => Ustr."=",
                                                           "=" => Ustr."=");

   package Str_Vector is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => String,
      "=" => Standard."=");

   package Bstr_Vector is new Ada.Containers.Vectors (Index_Type => Positive,
                                                      Element_Type => Bs,
                                                      "=" => Bstr."=");

   package Ustr_Vector is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Us,
      "=" => Ustr."=");

   -- Fixed string list
   package Str_List is new Ada.Containers.Indefinite_Doubly_Linked_Lists
     (Element_Type => String,
      "=" => Standard."=");

   -- SMALL bounded string list
   package Bstr_List is new Ada.Containers.Doubly_Linked_Lists
     (Element_Type => Bs,
      "=" => Bstr."=");

   -- SMALL bounded string list
   package Ustr_List is new Ada.Containers.Indefinite_Doubly_Linked_Lists
     (Element_Type => Us,
      "=" => Ustr."=");

   package Ustr_Sort is new Ustr_List.Generic_Sorting (Ustr."<");

   function Map_Float_Equals (L,R : Float) return Boolean renames Standard."=";

   package Str_Map_To_Float is new Ada.Containers.Indefinite_Hashed_Maps (String,
                                                                          Float,
                                                                          Ada.Strings.Hash,
                                                                          Standard."=",
                                                                          Map_Float_Equals);

   package Str_Map_To_Ustr is new Ada.Containers.Indefinite_Hashed_Maps (String,
                                                                         Us,
                                                                         Ada.Strings.Hash,
                                                                         Standard."=",
                                                                         Ustr."=");

   ------------------------------------------------------
   -- FIELDS -- Extracts fields from a string
   ------------------------------------------------------

   function Select_Field
     (Item : String; Field_No : Positive; Field_Separator : Character)
      return String;

   --  Returns a string that represents the nth string in the field.
   --  The 'first of the return string is always set to one
   --  Fields are separated by the supplied character
   --  E.g. the following would result in the string "mouse"
   --     Field ("cat:dog:mouse", 3, ':')
   --
   --  To process each field in a string you can do the following
   --  (presuming Line (1..Last) has the string you want to process)
   --
   --  for i in 1 .. Integer'Last loop
   --     declare
   --        Item : constant String := Field (Line (1..Last), i, ':');
   --     begin
   --        exit when Item = ""; -- assumes all fields have values!
   --        -- process item...
   --     end;
   --  end loop;


   function Count_Fields
     (Item : String; Field_Separator : Character) return Natural;

   --  returns the # of fields separated by the field_separator
   --  character E.g.
   --
   --    Count_Fields ("cat:dog:mouse", ':')  -> 3
   --    Count_Fields ("cat:dog:mouse", 'o')  -> 3
   --    Count_Fields ("cat:dog:mouse", ' ')  -> 1
   --    Count_Fields ("", ' ')  -> 0

   function Count_Fields(Item : String) return Natural;
   --  This uses the default space OR tab as a delimiter. This differs from the
   --  one above because it counts a series of spaces and tabs as one space.
   --  Leading and trailing spaces (not tabs though!) are also ignored.


   function Select_Field (Item : String; Field_No : Positive) return String;

   --  Returns a string that represents the nth string in the field.
   --  The 'first of the return string is always set to one
   --  Differs from the other 'field' function in that it considers
   --  fields to be separated by multiple white space characters
   --  E.g. the following results in the string "mouse"
   --      Field ("cat    dog  mouse", 3)
   --
   --  Note that this is _not_ the same as
   --      Field ("cat    dog  mouse", 3, ' ')
   --
   --  which sees _each_ space as separating (many empty) fields


   function Trim (Str : in String) return String;
   function Trim (Int : in Integer) return String;
   function Trim (Long_Int : in Long_Integer) return String;
   function Trim (Flt : in Float;
                  Aft : in Integer := 6) return String; -- On Error does 'img
   function Trim (Flt : in Long_Float;
                  Aft : in Integer := 9) return String; -- On Error does 'img
   -- Trims left and right side of string of spaces.

   -- trims out all whitespace (includes tabs and newlines, above trims only do spaces)
   -- includes both ends of string
   function Trim_All (Str : in String) return String;

   function Slider (S : String) return String;
   -- Replaces the string so that 'First index = 1 (i.e. string starts at 1)

   function Head (Item : String;
                  Field_Separator : Character) return String;
   function Tail (Item : String;
                  Field_Separator : Character) return String;

   function Delimited_Contents (Text, Open, Close: in String) return String;
   -- Picks out the string between delimiters

   ------------------------------------------------------------------------------
   -- $Id: pace-strings.ads,v 1.5 2006/04/14 23:14:14 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Strings;
