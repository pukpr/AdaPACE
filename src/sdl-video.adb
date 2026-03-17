
-- ----------------------------------------------------------------- --
--                AdaSDL                                             --
--                Binding to Simple Direct Media Layer               --
--                Copyright (C) 2001 A.M.F.Vargas                    --
--                Antonio M. F. Vargas                               --
--                Ponta Delgada - Azores - Portugal                  --
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
--  This is an Ada binding to SDL - Simple DirectMedia Layer from    --
--  Sam Lantinga - www.libsld.org                                    --
--  **************************************************************** --
--  In order to help the Ada programmer, the comments in this file   --
--  are, in great extent, a direct copy of the original text in the  --
--  SDL header files.                                                --
--  **************************************************************** --
-- with Lib_C;
package body Sdl.Video is
   use type Cs.Chars_Ptr;

   -------------
   -- LoadBMP --
   -------------

   function Loadbmp (File : C.Strings.Chars_Ptr) return Surface_Ptr is
   begin
      return Loadbmp_Rw
               (Src => Sdl.Rwops.Rwfromfile
                         (File => File, Mode => C.Strings.New_String ("rb")),
                Freesrc => 1);
   end Loadbmp;

   --  ===================================================================
   function Loadbmp (File : String) return Surface_Ptr is
   begin
      return Loadbmp_Rw (Src => Sdl.Rwops.Rwfromfile
                                  (File => C.Strings.New_String (File),
                                   Mode => C.Strings.New_String ("rb")),
                         Freesrc => 1);
   end Loadbmp;


   -------------
   -- SaveBMP --
   -------------

   function Savebmp (Surface : Surface_Ptr; File : C.Strings.Chars_Ptr)
                    return C.Int is
   begin
      return Savebmp_Rw
               (Surface => Surface,
                Dst => Sdl.Rwops.Rwfromfile
                         (File => File, Mode => C.Strings.New_String ("wb")),
                Freedst => 1);
   end Savebmp;

   --------------
   -- MUSTLOCK --
   --------------

   function Mustlock (Surface : Surface_Ptr) return Boolean is
   begin
      return (Surface.Offset /= 0 or
              ((Surface.Flags and (Hwsurface or Asyncblit or Rleaccel)) /= 0));
   end Mustlock;


   --  ======================================
   procedure Disable_Clipping (Surface : Surface_Ptr) is
   begin
      Setcliprect (Surface, null);
   end Disable_Clipping;

   --  ======================================
   procedure Update_Rect (Screen : Surface_Ptr; The_Rect : Rect) is
   begin
      Updaterect (Screen, Sint32 (The_Rect.X), Sint32 (The_Rect.Y),
                  Uint32 (The_Rect.W), Uint32 (The_Rect.H));
   end Update_Rect;

   --  ======================================
   procedure Wm_Set_Caption (Title : in String; Icon : in String) is
   begin
      Wm_Setcaption (Cs.New_String (Title), Cs.New_String (Icon));
   end Wm_Set_Caption;

   --  ======================================
   procedure Wm_Set_Caption_Title (Title : in String) is
   begin
      Wm_Setcaption (Cs.New_String (Title), Cs.Null_Ptr);
   end Wm_Set_Caption_Title;

   --  ======================================
   procedure Wm_Set_Caption_Icon (Icon : in String) is
   begin
      Wm_Setcaption (Cs.Null_Ptr, Cs.New_String (Icon));
   end Wm_Set_Caption_Icon;

   --  ======================================
   procedure Wm_Get_Caption (Title : out Us.Unbounded_String;
                             Icon : out Us.Unbounded_String) is
      The_Title : aliased Cs.Chars_Ptr := Cs.Null_Ptr;
      The_Icon : aliased Cs.Chars_Ptr := Cs.Null_Ptr;
   begin
      Wm_Getcaption (The_Title'Unchecked_Access, The_Icon'Unchecked_Access);
      if The_Title /= Cs.Null_Ptr then
         Title := Us.To_Unbounded_String (Cs.Value (The_Title));
      else
         Title := Us.Null_Unbounded_String;
      end if;
      if The_Icon /= Cs.Null_Ptr then
         Icon := Us.To_Unbounded_String (Cs.Value (The_Icon));
      else
         Icon := Us.Null_Unbounded_String;
      end if;
   end Wm_Get_Caption;

   --  ======================================
   procedure Wm_Get_Caption_Title (Title : out Us.Unbounded_String) is
      The_Title : aliased Cs.Chars_Ptr := Cs.Null_Ptr;
   begin
      Wm_Getcaption (The_Title'Unchecked_Access, null);
      if The_Title /= Cs.Null_Ptr then
         Title := Us.To_Unbounded_String (Cs.Value (The_Title));
      else
         Title := Us.Null_Unbounded_String;
      end if;
   end Wm_Get_Caption_Title;

   --  ======================================
   procedure Wm_Get_Caption_Icon (Icon : out Us.Unbounded_String) is
      The_Icon : aliased Cs.Chars_Ptr := Cs.Null_Ptr;
   begin
      Wm_Getcaption (null, The_Icon'Unchecked_Access);
      if The_Icon /= Cs.Null_Ptr then
         Icon := Us.To_Unbounded_String (Cs.Value (The_Icon));
      else
         Icon := Us.Null_Unbounded_String;
      end if;
   end Wm_Get_Caption_Icon;

end Sdl.Video;

