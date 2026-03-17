
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

with Interfaces.C.Strings;

package Sdl.Error is

   package C renames Interfaces.C;
   package Cs renames Interfaces.C.Strings;

   --  Public functions

   --  In C this is a function with variable arguments.
   --   ' void SDL_SetError(const char *fmt, ...);'
   --  new functions will be added as needed
   procedure Seterror (Fmt : Cs.Chars_Ptr);
   pragma Import (C, Seterror, "SDL_SetError");

   procedure Set_Error (Fmt : String);
   pragma Inline (Set_Error);


   function Geterror return Cs.Chars_Ptr;
   pragma Import (C, Geterror, "SDL_GetError");

   function Get_Error return String;
   pragma Inline (Get_Error);

   procedure Clearerror;
   pragma Import (C, Clearerror, "SDL_ClearError");

   type Errorcode is new Interfaces.C.Int;
   Enomem : constant Errorcode := 0;
   Efread : constant Errorcode := 1;
   Efwrite : constant Errorcode := 2;
   Efseek : constant Errorcode := 3;
   Lasterror : constant Errorcode := 4;

   --  Not available on some systems
   --  procedure Error (code : errorcode);
   --  pragma Import (C, Error, "SDL_Error");

   procedure Outofmemory;
   pragma Inline (Outofmemory);

end Sdl.Error;
