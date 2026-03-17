
-- ----------------------------------------------------------------- --
--                ASDL_Mixer                                         --
--                Binding to SDL mixer lib                           --
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
--  This is an Ada binding to SDL_mixer lib from Sam Lantinga at     --
--  www.libsld.org                                                   --
--  **************************************************************** --

package body SDL.Mixer is

   use type C.int;

   --  ======================================
   function LoadWAV (file : CS.chars_ptr) return Chunk_ptr is
   begin
      return LoadWAV_RW (RW.RWFromFile (file, CS.New_String ("rb")), 1);
   end LoadWAV;
  
   --  ======================================
   function Load_WAV (file : String) return Chunk_ptr is
   begin
      return LoadWAV_RW (RW.RW_From_File (file, "rb"), 1);
   end Load_WAV;
   
   --  ======================================
   function Load_MUS (file : String) return Music_ptr is
   begin
      return LoadMUS (CS.New_String (file));
   end Load_MUS;
   
   --  ======================================
   function PlayChannel (
      channel : C.int;
      chunk   : Chunk_ptr;
      loops   : C.int)
      return C.int
   is
   begin
      return PlayChannelTimed (channel, chunk, loops, -1);
   end PlayChannel;
      
   --  ======================================
   procedure PlayChannel (
      channel : C.int;
      chunk   : Chunk_ptr;
      loops   : C.int)
   is
   begin
      PlayChannelTimed (channel, chunk, loops, -1);
   end PlayChannel;
   
   --  ======================================
   function FadeInChannel (
      channel : C.int;
      chunk   : Chunk_ptr;
      loops   : C.int;
      ms      : C.int)
      return C.int
   is
   begin
      return FadeInChannelTimed (channel, chunk, loops, ms, -1);
   end FadeInChannel;
   
   --  ======================================
   function Set_Music_CMD (command : String) return Integer is
   begin
      if command = "" then
         return Integer (SetMusicCMD (CS.Null_Ptr));
      else
         return Integer (SetMusicCMD (CS.New_String (command)));
      end if;
   end Set_Music_CMD;
   
   --  ======================================
   procedure Set_Music_CMD (command : String) is
   begin
      if command = "" then
         SetMusicCMD (CS.Null_Ptr);
      else
         SetMusicCMD (CS.New_String (command));
      end if;
   end Set_Music_CMD;
   --  ======================================
end SDL.Mixer;
