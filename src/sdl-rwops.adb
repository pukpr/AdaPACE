
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

package body Sdl.Rwops is

   -------------
   -- RWclose --
   -------------

   function Rwclose (Ctx : Rwops_Ptr) return C.Int is
   begin
      return Ctx.Close (Ctx);
   end Rwclose;

   ------------
   -- RWread --
   ------------

   function Rwread (Ctx : Rwops_Ptr; Ptr : Void_Ptr; Size : C.Int; N : C.Int)
                   return C.Int is
   begin
      return Ctx.Read (Ctx, Ptr, Size, N);
   end Rwread;

   ------------
   -- RWSeek --
   ------------

   function Rwseek
              (Ctx : Rwops_Ptr; Offset : C.Int; Whence : C.Int) return C.Int is
   begin
      return Ctx.Seek (Ctx, Offset, Whence);
   end Rwseek;

   ------------
   -- RWtell --
   ------------

   function Rwtell (Ctx : Rwops_Ptr) return C.Int is
   begin
      return Ctx.Seek (Ctx, 0, C.Int (C_Streams.Seek_Cur));
   end Rwtell;

   -------------
   -- RWwrite --
   -------------

   function Rwwrite (Ctx : Rwops_Ptr; Ptr : Void_Ptr; Size : C.Int; N : C.Int)
                    return C.Int is
   begin
      return Ctx.Write (Ctx, Ptr, Size, N);
   end Rwwrite;

   --  ======================================
   function Rw_From_File (File : String; Mode : String) return Rwops_Ptr is
   begin
      return Rwfromfile (Cs.New_String (File), Cs.New_String (Mode));
   end Rw_From_File;

   --  ======================================

end Sdl.Rwops;

