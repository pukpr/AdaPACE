
-- ----------------------------------------------------------------- --
--                AdaSDL                                             --
--                Binding to Simple Direct Media Layer               --
--                Copyright (C) 2001 A.M.F.Vargas                    --
--                Antonio M. F. Vargas                               --
--                Ponta Delgada - Azores - Portugal                  --
--                http://www.adapower.net/~avargas                   --
--                E-mail: avargas@adapower.net                       --
-- ----------------------------------------------------------------- --
--                                                                   --
-- This library is free software; you can redistribute it and/or     --
-- modify it under the terms of the GNU General Public               --
-- License as published by the Free Software Foundation; either      --
-- version 2 of the License, or (at your option) any later version.  --
--                                                                   --
-- This library is distributed in the hope that it will be useful,   --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of    --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details.                          --
--                                                                   --
-- You should have received a copy of the GNU General Public         --
-- License along with this library; if not, write to the             --
-- Free Software Foundation, Inc., 59 Temple Place - Suite 330,      --
-- Boston, MA 02111-1307, USA.                                       --
--                                                                   --
-- As a special exception, if other files instantiate generics from  --
-- this unit, or you link this unit with other files to produce an   --
-- executable, this  unit  does not  by itself cause  the resulting  --
-- executable to be covered by the GNU General Public License. This  --
-- exception does not however invalidate any other reasons why the   --
-- executable file  might be covered by the  GNU Public License.     --
-- ----------------------------------------------------------------- --

--  **************************************************************** --
--  This is an Ada binding to SDL ( Simple DirectMedia Layer from    --
--  Sam Lantinga - www.libsld.org )                                  --
--  **************************************************************** --
--  In order to help the Ada programmer, the comments in this file   --
--  are, in great extent, a direct copy of the original text in the  --
--  SDL header files.                                                --
--  **************************************************************** --

with System.Address_To_Access_Conversions;
with Interfaces.C;
with Interfaces.C.Strings;
with Interfaces.C.Pointers;
with Interfaces.C.Extensions;
with Uintn_Ptrops;
package Sdl.Types is

   package C renames Interfaces.C;
   package Ce renames Interfaces.C.Extensions;
   --  SDL_TABLESIZE ???

   type Sdl_Bool is new C.Int;
   Sdl_False : constant Sdl_Bool := 0;
   Sdl_True : constant Sdl_Bool := 1;


   type Uint8 is new C.Unsigned_Char;
   type Uint8_Ptr is access all Uint8;
   pragma Convention (C, Uint8_Ptr);
   type Uint8_Ptr_Ptr is access all Uint8_Ptr;
   pragma Convention (C, Uint8_Ptr_Ptr);

   package Uint8_Ptrs is new System.Address_To_Access_Conversions (Uint8);


   type Uint8_Array is array (C.Size_T range <>) of aliased Uint8;
   package Uint8_Ptrops is new Uintn_Ptrops (The_Element => Uint8,
                                             The_Element_Array => Uint8_Array);

   procedure Copy_Array (Source : Uint8_Ptrs.Object_Pointer;
                         Target : Uint8_Ptrs.Object_Pointer;
                         Lenght : Natural);
   pragma Inline (Copy_Array);

   function Increment (Pointer : Uint8_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint8_Ptrs.Object_Pointer;
   pragma Inline (Increment);

   function Decrement (Pointer : Uint8_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint8_Ptrs.Object_Pointer;
   pragma Inline (Decrement);

   function Shift_Left (Value : Uint8; Amount : Integer) return Uint8;
   pragma Inline (Shift_Left);

   function Shift_Right (Value : Uint8; Amount : Integer) return Uint8;
   pragma Inline (Shift_Right);


   type Sint8 is new C.Char;
   type Sint8_Ptr is access all Sint8;
   pragma Convention (C, Sint8_Ptr);
   type Sint8_Ptr_Ptr is access all Sint8_Ptr;
   pragma Convention (C, Sint8_Ptr_Ptr);

   type Uint16 is new C.Unsigned_Short;
   type Uint16_Ptr is access all Uint16;
   pragma Convention (C, Uint16_Ptr);
   type Uint16_Ptr_Ptr is access all Uint16_Ptr;
   pragma Convention (C, Uint16_Ptr_Ptr);


   package Uint16_Ptrs is new System.Address_To_Access_Conversions (Uint16);

   type Uint16_Array is array (C.Size_T range <>) of aliased Uint16;
   package Uint16_Ptrops is
     new Uintn_Ptrops (The_Element => Uint16,
                       The_Element_Array => Uint16_Array);

   function Increment (Pointer : Uint16_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint16_Ptrs.Object_Pointer;
   pragma Inline (Increment);

   function Decrement (Pointer : Uint16_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint16_Ptrs.Object_Pointer;
   pragma Inline (Decrement);

   function Shift_Left (Value : Uint16; Amount : Integer) return Uint16;
   pragma Inline (Shift_Left);

   function Shift_Right (Value : Uint16; Amount : Integer) return Uint16;
   pragma Inline (Shift_Right);

   type Sint16 is new C.Short;
   type Sint16_Ptr is access all Sint16;
   pragma Convention (C, Sint16_Ptr);
   type Sint16_Ptr_Ptr is access all Sint16_Ptr;
   pragma Convention (C, Sint16_Ptr_Ptr);

   type Uint32 is new C.Unsigned;
   type Uint32_Ptr is access all Uint32;
   pragma Convention (C, Uint32_Ptr);
   type Uint32_Ptr_Ptr is access all Uint32_Ptr;
   pragma Convention (C, Uint32_Ptr_Ptr);

   package Uint32_Ptrs is new System.Address_To_Access_Conversions (Uint32);

   type Uint32_Array is array (C.Size_T range <>) of aliased Uint32;
   package Uint32_Ptrops is
     new Uintn_Ptrops (The_Element => Uint32,
                       The_Element_Array => Uint32_Array);

   function Increment (Pointer : Uint32_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint32_Ptrs.Object_Pointer;
   pragma Inline (Increment);

   function Decrement (Pointer : Uint32_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint32_Ptrs.Object_Pointer;
   pragma Inline (Decrement);

   function Shift_Left (Value : Uint32; Amount : Integer) return Uint32;
   pragma Inline (Shift_Left);

   function Shift_Right (Value : Uint32; Amount : Integer) return Uint32;
   pragma Inline (Shift_Right);

   type Sint32 is new C.Int;
   type Sint32_Ptr is access all Sint32;
   pragma Convention (C, Sint32_Ptr);
   type Sint32_Ptr_Ptr is access all Sint32_Ptr;
   pragma Convention (C, Sint32_Ptr_Ptr);

   type Uint64 is new Ce.Unsigned_Long_Long;
   type Uint64_Ptr is access all Uint64;
   pragma Convention (C, Uint64_Ptr);
   type Uint64_Ptr_Ptr is access all Uint64_Ptr;
   pragma Convention (C, Uint64_Ptr_Ptr);

   type Sint64 is new Ce.Long_Long;
   type Sint64_Ptr is access all Sint64;
   pragma Convention (C, Sint64_Ptr);
   type Sint64_Ptr_Ptr is access all Sint64_Ptr;
   pragma Convention (C, Sint64_Ptr_Ptr);

   type Bits1 is mod 2 ** 1;
   --  for bits1'Size use 1;

   type Bits6 is mod 2 ** 6;
   --  for bits6'Size use 6;

   type Bits16 is mod 2 ** 16;
   --  for bits16'Size use 16;

   type Bits31 is mod 2 ** 31;
   --  for bits31'Size use 31;

   type Void_Ptr is new System.Address;

   type Chars_Ptr_Ptr is access all C.Strings.Chars_Ptr;
   pragma Convention (C, Chars_Ptr_Ptr);

   type Int_Ptr is access all C.Int;
   pragma Convention (C, Int_Ptr);

   Sdl_Pressed : constant := 16#01#;
   Sdl_Released : constant := 16#00#;

end Sdl.Types;
