
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

with Interfaces.C;
package Sdl is
   --  pragma Linker_Options ("-lSDL");
   --  pragma Linker_Options ("-lpthread");

   package C renames Interfaces.C;

   --  As of version 0.5, SDL is loaded dynamically into the application */

   --  These are the flags which may be passed to Init-- you should
   --  specify the subsystems which you will be using in your application.

   type Init_Flags is mod 2 ** 32;
   pragma Convention (C, Init_Flags);

   Init_Timer : Init_Flags := 16#00000001#;
   Init_Audio : Init_Flags := 16#00000010#;
   Init_Video : Init_Flags := 16#00000020#;
   Init_Cdrom : Init_Flags := 16#00000100#;
   Init_Joystick : Init_Flags := 16#00000200#;
   --  Don't catch fatal signals
   Init_Noparachute : Init_Flags := 16#00100000#;
   --  Not supported on all OS's
   Init_Eventthread : Init_Flags := 16#01000000#;
   Init_Everything : Init_Flags := 16#0000FFFF#;


   --  This function loads the SDL dynamically linked library and
   --  initializes the subsystems specified by 'flags' (and those
   --  satisfying dependencies) Unless the INIT_NOPARACHUTE flag
   --  is set, it will install cleanup signal handlers for some
   --  commonly ignored fatal signals (like SIGSEGV)
   function Init (Flags : Init_Flags) return C.Int;
   procedure Init (Flags : Init_Flags);
   pragma Import (C, Init, "SDL_Init");

   --  This function initializes specific SDL subsystems
   function Initsubsystem (Flags : Init_Flags) return C.Int;
   pragma Import (C, Initsubsystem, "SDL_InitSubSystem");

   --  This function cleans up specific SDL subsystems
   procedure Quitsubsystem (Flags : Init_Flags);
   pragma Import (C, Quitsubsystem, "SDL_QuitSubSystem");

   --  This function returns mask of the specified subsystems which have
   --  been initialized.
   --  If 'flags' is 0, it returns a mask of all initialized subsystems.
   function Wasinit (Flags : Init_Flags) return Init_Flags;
   pragma Import (C, Wasinit, "SDL_WasInit");

   --  This function cleans up all initialized subsystems and unloads the
   --  dynamically linked library.  You should call it upon all exit
   --  conditions.
   procedure Sdl_Quit;
   pragma Import (C, Sdl_Quit, "SDL_Quit");



end Sdl;
