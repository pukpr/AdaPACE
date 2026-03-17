with Ada.Strings.Hash;
with Ada.Strings.Unbounded.Hash;
with Text_Io;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Ada.Characters.Latin_1;
with Ada.Float_Text_Io;
with Ada.Long_Float_Text_Io;

package body Pace.Strings is

   function Bstr_To_Str (Str : Bs) return String is
   begin
      return Bstr.To_String (Str);
   end Bstr_To_Str;

   function Str_To_Bstr (Str : String) return Bs is
   begin
      return Bstr.To_Bounded_String (Str);
   end Str_To_Bstr;

   function Str_To_Ustr (Str : String) return Us is
   begin
      return Ustr.To_Unbounded_String (Str);
   end Str_To_Ustr;

   function Bstr_To_Ustr (Str : Bs) return Us is
   begin
      return Ustr.To_Unbounded_String (Bstr.To_String (Str));
   end Bstr_To_Ustr;

   function Ustr_To_Bstr (Str : Us) return Bs is
   begin
      return Bstr.To_Bounded_String (Ustr.To_String (Str));
   end Ustr_To_Bstr;

   function Ustr_To_Str (Str : Us) return String is
   begin
      return Ustr.To_String (Str);
   end Ustr_To_Str;

   function Hash (Key : Bs) return Ada.Containers.Hash_Type is
   begin
      return Ada.Strings.Hash (Bstr.To_String (Key));
   end Hash;

   function Hash (Key : Us) return Ada.Containers.Hash_Type is
   begin
      return Ada.Strings.Unbounded.Hash (Key);
   end Hash;


   function Btext_To_Str (Str : Bt) return String is
   begin
      return Btext.To_String (Str);
   end Btext_To_Str;

   function Str_To_Btext (Str : String) return Bt is
   begin
      return Btext.To_Bounded_String (Str);
   end Str_To_Btext;

   function Btext_To_Ustr (Str : Bt) return Us is
   begin
      return Ustr.To_Unbounded_String (Btext.To_String (Str));
   end Btext_To_Ustr;

   function Ustr_To_Btext (Str : Us) return Bt is
   begin
      return Btext.To_Bounded_String (Ustr.To_String (Str));
   end Ustr_To_Btext;

   function Hash (Key : Bt) return Ada.Containers.Hash_Type is
   begin
      return Ada.Strings.Hash (Btext.To_String (Key));
   end Hash;


   -- Trims both ends of string for blanks.
   function Trim (Str : in String) return String is
      use Ada.Strings.Fixed;
   begin
      return Trim (Trim (Str, Ada.Strings.Left), Ada.Strings.Right);
   end Trim;

   function Trim (Int : in Integer) return String is
   begin
      return Trim (Integer'Image (Int));
   end Trim;

   function Trim (Long_Int : in Long_Integer) return String is
   begin
      return Trim (Long_Integer'Image (Long_Int));
   end Trim;

   function Trim (Flt : in Float;
                  Aft : in Integer := 6) return String is
      Str : String (1 .. 100);  -- Sufficient space for rep of float
   begin
      Ada.Float_Text_Io.Put (To => Str, Item => Flt, Aft => Aft, Exp => 0);
      return Trim (Str);
   exception
      when Text_Io.Layout_Error =>
         return Trim (Float'Image (Flt));
   end Trim;

   function Trim (Flt : in Long_Float;
                  Aft : in Integer := 9) return String is
      Str : String (1 .. 100);  -- Sufficient space for rep of float
   begin
      Ada.Long_Float_Text_Io.Put (To => Str, Item => Flt, Aft => Aft, Exp => 0);
      return Trim (Str);
   exception
      when Text_Io.Layout_Error =>
         return Trim (Long_Float'Image (Flt));
   end Trim;

   package Acl renames Ada.Characters.Latin_1;
   All_Whitespace : Ada.Strings.Maps.Character_Set :=
     Ada.Strings.Maps.To_Set (" " &
                              Acl.Lf &
                              Acl.Cr &
                              Acl.Ht); -- tab character
   function Trim_All (Str : in String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Str, All_Whitespace, All_Whitespace);
   end Trim_All;

   function Slider (S : String) return String is
      subtype Slide is String (1 .. S'Length);
   begin
      return Slide (S);
   end;

   use Ada.Strings;

   function Head (Item : String;
                  Field_Separator : Character) return String is
      Finish : Integer := Item'First;
   begin
      Finish := Fixed.Index (Item, (1 => Field_Separator), Finish) - 1;
      if Finish < 0 then
         return "";
      else
         return Trim (Fixed.Head (Item, Finish));
      end if;
   end;

   function Tail (Item : String;
                  Field_Separator : Character) return String is
      Finish : Integer := Item'First;
   begin
      Finish := Item'Last - Fixed.Index (Item, (1 => Field_Separator), Finish);
      if Finish = Item'Last then
         return "";
      else
         return Trim (Fixed.Tail (Item, Finish));
      end if;
   end;

   function Select_Field (Item : String;
                          Field_No : Positive;
                          Field_Separator : Character;
                          Skip_Blanks : Boolean) return String is
      Start, Finish : Integer := Item'First;
   begin
      if Skip_Blanks then
         Start := Fixed.Index_Non_Blank (Item, Start);
         if Start = 0 then
            return "";
         end if;
      end if;
      for I in 1 .. Field_No loop
         Finish := Fixed.Index (Item, "" & Field_Separator, Start) - 1;
         if Start > Item'Last or Finish < 0 then
            exit when I /= Field_No;  -- Hit end w/o finding anything
            Finish := Item'Last;
            exit;                     -- Reached the end on first field
         end if;
         exit when I = Field_No;
         if Skip_Blanks then
            Start := Fixed.Index_Non_Blank (Item, Finish+1);
            if Start = 0 then
               Start := Item'Last;
            end if;
         else
            Start := Finish + 2;
         end if;
      end loop;
      declare
         subtype Slide is String (1 .. Finish - Start + 1);
      begin
         return Slide (Item (Start .. Finish));
      end;
   end;

   function Count_Fields (Item : String;
                          Field_Separator : Character;
                          Skip_Blanks : Boolean) return Natural is
      Finish : Integer := Item'First;
   begin
      if Skip_Blanks then
         Finish := Fixed.Index_Non_Blank (Item, Finish);
         if Finish = 0 then
            return 0;
         end if;
      end if;
      for I in 1..Item'Length loop
         Finish := Fixed.Index (Item, "" & Field_Separator, Finish);
         if Skip_Blanks and Finish > 0 then
            Finish := Fixed.Index_Non_Blank (Item, Finish);
         else
            Finish := Finish + 1;
         end if;
         if Finish > Item'Last then
            return I+1;
         elsif Finish <= 1 then
            return I;
         end if;
      end loop;
      return 0;
   end;

   function Select_Field (Item : String;
                          Field_No : Positive;
                          Field_Separator : Character) return String is
   begin
      return Select_Field (Item, Field_No, Field_Separator, False);
   end;

   function Count_Fields
     (Item : String; Field_Separator : Character) return Natural is
   begin
      return Count_Fields (Item, Field_Separator, False);
   end;

   function Mapping (From : Character) return Character;
   function Mapping (From : Character) return Character is
   begin
      if From = ASCII.HT then
         return ' ';
      else
         return From;
      end if;
   end;

   function Select_Field (Item : String; Field_No : Positive) return String is
      Str : String := Item;
   begin
      Fixed.Translate (Str, Mapping'Access);
      return Select_Field (Str, Field_No, ' ', True);
   end;

   function Count_Fields(Item : String) return Natural is
      Str : String := Item;
   begin
      Fixed.Translate (Str, Mapping'Access);
      return Count_Fields (Str, ' ', True);
   end;


   function Delimited_Contents (Text, Open, Close: in String) return String is
      Start, Stop : Natural;
   begin
      -- Look for start delimiter
      --
      Start := Fixed.Index (Text, Open);
      if Start > 0 then
         --
         -- if found then look for stop delimiter
         --
         Stop := Fixed.Index (Text (Start + 1 .. Text'Last), Close);
         if Stop > Start then
            --
            -- Return the delimited subtext by expanding in place
            --
            return Slider (Text (Start + Open'Length .. Stop - 1));
         else
            return "";  -- No stop tag
         end if;
      else
         return ""; -- No start tag
      end if;
   end Delimited_Contents;

------------------------------------------------------------------------------
-- $Id: pace-strings.adb,v 1.6 2006/04/20 16:04:25 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Strings;
