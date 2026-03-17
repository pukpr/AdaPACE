
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
with Interfaces.C.Strings;
with Sdl.Types;
use Sdl.Types;

package Sdl.Joystick is

   package C renames Interfaces.C;

   --   The pointer to a internal joystick structure used
   --   to identify an SDL joystick
   type Joystick_Ptr is new System.Address;
   Null_Joystick_Ptr : constant Joystick_Ptr :=
     Joystick_Ptr (System.Null_Address);

   --  Function prototypes */
   --
   --  Count the number of joysticks attached to the system
   function Numjoysticks return C.Int;
   pragma Import (C, Numjoysticks, "SDL_NumJoysticks");


   --  Get the implementation dependent name of a joystick.
   --  This can be called before any joysticks are opened.
   --  If no name can be found, this function returns NULL.
   function Joystickname (Device_Index : C.Int) return C.Strings.Chars_Ptr;
   pragma Import (C, Joystickname, "SDL_JoystickName");

   --  Open a joystick for use - the index passed as an argument refers to
   --  the N'th joystick on the system.  This index is the value which will
   --  identify this joystick in future joystick events.

   --  This function returns a joystick identifier, or
   --  NULL if an error occurred.
   function Joystickopen (Device_Index : C.Int) return Joystick_Ptr;
   pragma Import (C, Joystickopen, "SDL_JoystickOpen");

   --  Returns 1 if the joystick has been opened, or 0 if it has not.
   function Joystickopened (Device_Index : C.Int) return C.Int;
   pragma Import (C, Joystickopened, "SDL_JoystickOpened");

   --  Get the device index of an opened joystick.
   function Joystickindex (Joystick : Joystick_Ptr) return C.Int;
   pragma Import (C, Joystickindex, "SDL_JoystickIndex");

   --  Get the number of general axis controls on a joystick
   function Joysticknumaxes (Joystick : Joystick_Ptr) return C.Int;
   pragma Import (C, Joysticknumaxes, "SDL_JoystickNumAxes");

   --  Get the number of trackballs on a joystick
   --  Joystick trackballs have only relative motion events associated
   --  with them and their state cannot be polled.
   function Joysticknumballs (Joystick : Joystick_Ptr) return C.Int;
   pragma Import (C, Joysticknumballs, "SDL_JoystickNumBalls");

   --  Get the number of POV hats on a joystick
   function Joysticknumhats (Joystick : Joystick_Ptr) return C.Int;
   pragma Import (C, Joysticknumhats, "SDL_JoystickNumHats");

   --  Get the number of buttonYs on a joystick
   function Joysticknumbuttons (Joystick : Joystick_Ptr) return C.Int;
   pragma Import (C, Joysticknumbuttons, "SDL_JoystickNumButtons");

   --  Update the current state of the open joysticks.
   --  This is called automatically by the event loop if any joystick
   --  events are enabled.
   procedure Joystickupdate;
   pragma Import (C, Joystickupdate, "SDL_JoystickUpdate");

   --  Enable/disable joystick event polling.
   --  If joystick events are disabled, you must call JoystickUpdate
   --  yourself and check the state of the joystick when you want joystick
   --  information.
   --  The state can be one of QUERY, ENABLE or IGNORE.
   function Joystickeventstate (State : C.Int) return C.Int;
   pragma Import (C, Joystickeventstate, "SDL_JoystickEventState");


   --  Get the current state of an axis control on a joystick
   --  The state is a value ranging from -32768 to 32767.
   --  The axis indices start at index 0.
   function Joystickgetaxis
              (Joystick : Joystick_Ptr; Axis : C.Int) return Sint16;
   pragma Import (C, Joystickgetaxis, "SDL_JoystickGetAxis");

   --  Get the current state of a POV hat on a joystick
   --  The return value is one of the following positions:

   --  TO BE REMOVED type HAT_State is mod 2**16;
   type Hat_State is mod 2 ** 8;
   for Hat_State'Size use 8;

   Hat_Centered : constant Hat_State := 16#00#;
   Hat_Up : constant Hat_State := 16#01#;
   Hat_Right : constant Hat_State := 16#02#;
   Hat_Down : constant Hat_State := 16#04#;
   Hat_Left : constant Hat_State := 16#08#;
   Hat_Rightup : constant Hat_State := (Hat_Right or Hat_Up);
   Hat_Rightdown : constant Hat_State := (Hat_Right or Hat_Down);
   Hat_Leftup : constant Hat_State := (Hat_Left or Hat_Up);
   Hat_Leftdown : constant Hat_State := (Hat_Left or Hat_Down);

   --  The hat indices start at index 0.

   function Joystickgethat (Joystick : Joystick_Ptr; Hat : C.Int) return Uint8;
   pragma Import (C, Joystickgethat, "SDL_JoystickGetHat");

   --  Get the ball axis change since the last poll
   --  This returns 0, or -1 if you passed it invalid parameters.
   --  The ball indices start at index 0.
   function Joystickgetball
              (Joystick : Joystick_Ptr; Ball : C.Int; Dx, Dy : Int_Ptr)
              return C.Int;
   pragma Import (C, Joystickgetball, "SDL_JoystickGetBall");

   type Joy_Button_State is mod 2 ** 8;
   for Joy_Button_State'Size use 8;
   pragma Convention (C, Joy_Button_State);

   Pressed : constant Joy_Button_State := Joy_Button_State (Sdl_Pressed);
   Released : constant Joy_Button_State := Joy_Button_State (Sdl_Released);

   --  Get the current state of a button on a joystick
   --  The button indices start at index 0.
   function Joystickgetbutton
              (Joystick : Joystick_Ptr; Button : C.Int) return Joy_Button_State;
   pragma Import (C, Joystickgetbutton, "SDL_JoystickGetButton");

   --  Close a joystick previously opened with SDL_JoystickOpen
   procedure Joystickclose (Joystick : Joystick_Ptr);
   pragma Import (C, Joystickclose, "SDL_JoystickClose");


end Sdl.Joystick;
