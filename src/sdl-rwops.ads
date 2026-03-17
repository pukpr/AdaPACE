
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

with System;
with Interfaces.C;
with Interfaces.C.Strings;
with Interfaces.C_Streams;
with Sdl.Types;
use Sdl.Types;

--  This is a set of routines from SDL lib that doesn't
--  have a dependency from the SDL Ada package.
package Sdl.Rwops is

   package C renames Interfaces.C;
   package C_Streams renames Interfaces.C_Streams;
   package Cs renames Interfaces.C.Strings;

   type Void_Ptr is new System.Address;
   type File_Ptr is new C_Streams.Files;

   type Rwops;
   type Rwops_Ptr is access all Rwops;

   --  Seek to 'offset' relative to whence, one of stdio's
   --  whence values: SEEK_SET, SEEK_CUR, SEEK_END
   --  returns the finnal offset in the data source.
   type Seek_Type is
     access function (Context : Rwops_Ptr; Offset : C.Int; Whence : C.Int)
                     return C.Int;
   pragma Convention (C, Seek_Type);

   --  Read up to 'num' objects each of size 'objsize' from
   --  the data source to the ares pointed by 'ptr'.
   --  Returns number of objects read, or -1 if the read failed.
   type Read_Type is access function (Context : Rwops_Ptr;
                                      Ptr : Void_Ptr;
                                      Size : C.Int;
                                      Maxnum : C.Int) return C.Int;
   pragma Convention (C, Read_Type);

   --  Write exactly 'num' objects each of size 'objsize' from
   --  the area pointed by 'ptr' to data source.
   --  Returns 'num', or -1 if the write failed.
   type Write_Type is
     access function
              (Context : Rwops_Ptr; Ptr : Void_Ptr; Size : C.Int; Num : C.Int)
              return C.Int;
   pragma Convention (C, Write_Type);

   --  Close and free an allocated SDL_FSops structure.
   type Close_Type is access function (Context : Rwops_Ptr) return C.Int;
   pragma Convention (C, Close_Type);


   type Stdio_Type is
      record
         Autoclose : C.Int;
         Fp : File_Ptr;
      end record;
   pragma Convention (C, Stdio_Type);

   type Uint8_Ptr is access all Uint8;

   type Mem_Type is
      record
         Base, Here, Stop : Uint8_Ptr;
      end record;
   pragma Convention (C, Mem_Type);

   type Unknown_Type is
      record
         Data1 : Void_Ptr;
      end record;
   pragma Convention (C, Unknown_Type);

   type Hidden_Select_Type is (Is_Stdio, Is_Mem, Is_Unknown);
   type Hidden_Union_Type (Hidden_Select : Hidden_Select_Type := Is_Stdio) is
      record
         case Hidden_Select is
            when Is_Stdio =>
               Stdio : Stdio_Type;
            when Is_Mem =>
               Mem : Mem_Type;
            when Is_Unknown =>
               Unknown : Unknown_Type;
         end case;
      end record;
   pragma Convention (C, Hidden_Union_Type);
   pragma Unchecked_Union (Hidden_Union_Type);


   --  This is the read/write operation structure -- very basic */
   type Rwops is
      record
         Seek : Seek_Type;
         Read : Read_Type;
         Write : Read_Type;
         Close : Close_Type;
         Type_Union : Uint32;
         Hidden : Hidden_Union_Type;
      end record;

   function Rwfromfile
              (File : Cs.Chars_Ptr; Mode : Cs.Chars_Ptr) return Rwops_Ptr;
   pragma Import (C, Rwfromfile, "SDL_RWFromFile");

   function Rw_From_File (File : String; Mode : String) return Rwops_Ptr;
   pragma Inline (Rw_From_File);

   function Rwfromfp (File : File_Ptr; Autoclose : C.Int) return Rwops_Ptr;
   pragma Import (C, Rwfromfp, "SDL_RWFromFP");

   function Rwfrommem (Mem : Void_Ptr; Size : C.Int) return Rwops_Ptr;
   pragma Import (C, Rwfrommem, "SDL_RWFromMem");

   function Allocrw return Rwops_Ptr;
   pragma Import (C, Allocrw, "SDL_AllocRW");

   procedure Freerw (Area : Rwops_Ptr);
   pragma Import (C, Freerw, "SDL_FreeRW");

   function Rwseek
              (Ctx : Rwops_Ptr; Offset : C.Int; Whence : C.Int) return C.Int;
   pragma Inline (Rwseek);

   function Rwtell (Ctx : Rwops_Ptr) return C.Int;
   pragma Inline (Rwtell);

   function Rwread (Ctx : Rwops_Ptr; Ptr : Void_Ptr; Size : C.Int; N : C.Int)
                   return C.Int;
   pragma Inline (Rwread);

   function Rwwrite (Ctx : Rwops_Ptr; Ptr : Void_Ptr; Size : C.Int; N : C.Int)
                    return C.Int;
   pragma Inline (Rwwrite);

   function Rwclose (Ctx : Rwops_Ptr) return C.Int;
   pragma Inline (Rwclose);

end Sdl.Rwops;
