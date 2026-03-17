
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

package Sdl.Quit is

   --  An QUITEVENT is generated when the user tries to close the application
   --  window.  If it is ignored or filtered out, the window will remain open.
   --  If it is not ignored or filtered, it is queued normally and the window
   --  is allowed to close.  When the window is closed, screen updates will
   --  complete, but have no effect.

   --  SDL_Init installs signal handlers for SIGINT (keyboard interrupt)
   --  and SIGTERM (system termination request), if handlers do not already
   --  exist, that generate QUITEVENT events as well.  There is no way
   --  to determine the cause of an QUITEVENT, but setting a signal
   --  handler in your application will override the default generation of
   --  quit events for that signal.

   --  There are no functions directly affecting the quit event */

   --  #define SDL_QuitRequested() \
   --      (SDL_PumpEvents(),\
   --       SDL_PeepEvents(NULL,0,SDL_PEEKEVENT,SDL_QUITMASK))

   type Exit_Proc_Ptr is access procedure;
   pragma Convention (C, Exit_Proc_Ptr);
   procedure Atexit (Exit_Proc : Exit_Proc_Ptr);
   pragma Import (C, Atexit);

end Sdl.Quit;
