-- ----------------------------------------------------------------------------
------------------------------------------
-- ****************************************************************************
--****************************************
-- ----------------------------------------------------------------------------
------------------------------------------
--
-- PACKAGE NAME   - Alc
--(OpenALada - Ada binding to OpenAL)
--
-- DESCRIPTION    - This file implements the OpenAL "Alc.h" and "Alctypes.h"
--headers.
--
-- REFERENCE      - For information about OpenAL visit: www.openAL.org
--
-- COPYRIGHT      - (C) 2005 Dr.Aurele Vitali, All Rights Reserved -
--www.OpenALada.com
--
--                   Revision |   Date    | Description
--                  ----------+-----------+------------------------------------
------------------------------------------
--                     1.0    | 22 Jan 05 | Initial Release, Aurele Vitali
--<aurele.vitali@gmail.com>
--                  ----------+-----------+------------------------------------
------------------------------------------
--                     1.0a   | 23 Jan 05 | Released under "GNAT-Modified GPL".
--                  ----------+-----------+------------------------------------
------------------------------------------
--                     1.1    | 03 Mar 05 | Changes by Martin Dowie
--<martin.dowie@btopenworld.com>
--                            |           |
--                            |           | a) Removed Pragma
--"Linker_Options(...)"
--                            |           | b) Included Pragma
--"Preelaborate(...)"
--                            |           | c) Included "for Al.c.ALCvoid'size
--use 1"
--                            |           | d) Included Pragma "Convension (C,
--...)" for access pointers
--                            |           | e) Redefined type "lpALCstr" as
--"Interfaces.C.Char_array"
--                            |           | f) Removed "To_String" and
--"To_lpStr" functions
--                            |           | g) Removed package body (i.e. the
--"To_String" and "To_lpStr" functions)
--                            |           | h) Saved file as an Ada
--specification (.ads)
--                  ----------+-----------+------------------------------------
------------------------------------------
--                            |           |
--                  ----------+-----------+------------------------------------
------------------------------------------
--                            |           |
--                  ----------+-----------+------------------------------------
------------------------------------------
--
-- This program is free software; you can redistribute it and/or  modify  it
--under the  terms of the GNU General Public
-- License as published by the Free Software Foundation; either version 2 of
--the License, or (at your option) any later
-- version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
--ANY WARRANTY;  without  even the  implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more
-- details.
--
-- You should have received a copy of the  GNU  General  Public  License
--along with this program; if not, write to the
-- Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
--02111-1307, USA.
--
-- ----------------------------------------------------------------------------
------------------------------------------
-- ****************************************************************************
--****************************************
-- ----------------------------------------------------------------------------
------------------------------------------

with Interfaces.C;

package Al.c is

   pragma Preelaborate (Al.c);

   -- -------------------------------------------------------------------------
   -------------------------------------------
   -- Alc types
   -- -------------------------------------------------------------------------
   -------------------------------------------

   type ALCvoid is null record; -- Any type
--   for ALCvoid'Size use 1;
   pragma Convention (C, ALCvoid);
   type lpALCvoid is access all Al.c.ALCvoid; -- R/W access ptr to a ALCvoid
   pragma Convention (C, lpALCvoid);

   type ALCdevice is null record; -- DirectSound device handle
   pragma Convention (C, ALCdevice);
   type lpALCdevice is access all Al.c.ALCdevice;
   pragma Convention (C, lpALCdevice);

   type ALCcontext is null record; -- DirectSound context
   pragma Convention (C, ALCcontext);
   type lpALCcontext is access all Al.c.ALCcontext;
   pragma Convention (C, lpALCcontext);

   subtype ALCchar is Interfaces.C.char; -- 8-bit signed ANSI character
   --type lpALCstr is access all Al.c.ALCchar;
   ---- Removed: 27 Feb 2005
   subtype lpALCstr is Interfaces.C.char_array; -- New: 28 Feb 2005

   subtype ALCbyte is Interfaces.C.char; -- 8-bit signed byte
   type lpALbyte is access all Al.c.ALCbyte;
   pragma Convention (C, lpALbyte);

   subtype ALCubyte is Interfaces.C.unsigned_char; -- 8-bit unsigned byte
   type lpALCubyte is access all Al.c.ALCubyte;
   pragma Convention (C, lpALCubyte);

   subtype ALCshort is Interfaces.C.short; -- 16-bit signed short integer
   type lpALCshort is access all Al.c.ALCshort;
   pragma Convention (C, lpALCshort);

   subtype ALCushort is Interfaces.C.unsigned_short; -- 16-bit unsigned short
   type lpALCushort is access all Al.c.ALCushort;
   pragma Convention (C, lpALCushort);

   subtype ALCint is Interfaces.C.int; -- 32-bit signed integer
   type lpALCint is access all Al.c.ALCint;
   pragma Convention (C, lpALCint);

   subtype ALCuint is Interfaces.C.unsigned; -- 32-bit unsigned integer
   type lpALCuint is access all Al.c.ALCuint;
   pragma Convention (C, lpALCuint);

   subtype ALCfloat is Interfaces.C.C_float; -- 32-bit floating point
   type lpALCfloat is access all Al.c.ALCfloat;
   pragma Convention (C, lpALCfloat);

   subtype ALCdouble is Interfaces.C.double; -- 64-bit floating point
   type lpALCdouble is access all Al.c.ALCdouble;
   pragma Convention (C, lpALCdouble);

   subtype ALCboolean is Interfaces.C.int; -- Boolean
   type lpALCboolean is access all Al.c.ALCboolean;
   pragma Convention (C, lpALCboolean);

   subtype ALCenum is Al.c.ALCint; -- Enumerations
   type lpALCenum is access all Al.c.ALCenum;
   pragma Convention (C, lpALCenum);

   subtype ALCsizei is Al.c.ALCint;
   type lpALCsizei is access all Al.c.ALCsizei;
   pragma Convention (C, lpALCsizei);

   -- -------------------------------------------------------------------------
   -------------------------------------------
   -- Alc Constants
   -- -------------------------------------------------------------------------
   -------------------------------------------

   ALC_INVALID : constant := 16#A000#;

   ALC_FALSE : constant Al.c.ALCboolean := 0;
   ALC_TRUE  : constant Al.c.ALCboolean := 1;

   ALC_FREQUENCY : constant := 16#1007#;
   ALC_REFRESH   : constant := 16#1008#;
   ALC_SYNC      : constant := 16#1009#;

   ALC_NO_ERROR        : constant := Al.c.ALC_FALSE;
   ALC_INVALID_DEVICE  : constant := 16#A001#;
   ALC_INVALID_CONTEXT : constant := 16#A002#;
   ALC_INVALID_ENUM    : constant := 16#A003#;
   ALC_INVALID_VALUE   : constant := 16#A004#;
   ALC_OUT_OF_MEMORY   : constant := 16#A005#;

   ALC_DEFAULT_DEVICE_SPECIFIER : constant := 16#1004#;
   ALC_DEVICE_SPECIFIER         : constant := 16#1005#;
   ALC_EXTENSIONS               : constant := 16#1006#;

   ALC_MAJOR_VERSION : constant := 16#1000#;
   ALC_MINOR_VERSION : constant := 16#1001#;

   ALC_ATTRIBUTES_SIZE : constant := 16#1002#;
   ALC_ALL_ATTRIBUTES  : constant := 16#1003#;

   -- -------------------------------------------------------------------------
   -------------------------------------------
   -- Alc API
   -- -------------------------------------------------------------------------
   -------------------------------------------

   function alcCreateContext
     (dev      : Al.c.lpALCdevice;
      attrList : Al.c.lpALCint)
      return     Al.c.lpALCcontext;

   function alcMakeContextCurrent
     (alcHandle : Al.c.lpALCcontext)
      return      Al.c.ALCboolean;

   procedure alcProcessContext (alcHandle : Al.c.lpALCcontext);

   procedure alcSuspendContext (alcHandle : Al.c.lpALCcontext);

   procedure alcDestroyContext (alcHandle : Al.c.lpALCcontext);

   function alcGetError (dev : Al.c.lpALCdevice) return Al.c.ALCenum;

   function alcGetCurrentContext return Al.c.lpALCcontext;

   function alcOpenDevice (tokstr : Al.c.lpALCstr) return Al.c.lpALCdevice;

   procedure alcCloseDevice (dev : Al.c.lpALCdevice);

   function alcIsExtensionPresent
     (device  : Al.c.lpALCdevice;
      extName : Al.c.lpALCstr)
      return    Al.c.ALCboolean;

   function alcGetProcAddress
     (device   : Al.c.lpALCdevice;
      funcName : Al.c.lpALCdevice)
      return     Al.c.lpALCvoid;

   function alcGetEnumValue
     (device   : Al.c.lpALCdevice;
      enumName : Al.c.lpALCstr)
      return     Al.c.ALCenum;

   function alcGetContextsDevice
     (alcHandle : Al.c.lpALCcontext)
      return      Al.c.lpALCdevice;
   pragma Warnings(Off);
   function alcGetString
     (deviceHandle : Al.c.lpALCdevice;
      token        : Al.c.ALCenum)
      return         Al.c.lpALCstr;
   pragma Warnings(On);

   procedure alcGetIntegerv
     (deviceHandle : Al.c.lpALCdevice;
      token        : Al.c.ALCenum;
      size         : Al.c.ALCsizei;
      data         : Al.c.lpALCint);
private

   pragma Import (C, alcCreateContext, "alcCreateContext");
   pragma Import (C, alcMakeContextCurrent, "alcMakeContextCurrent");
   pragma Import (C, alcProcessContext, "alcProcessContext");
   pragma Import (C, alcSuspendContext, "alcSuspendContext");
   pragma Import (C, alcDestroyContext, "alcDestroyContext");
   pragma Import (C, alcGetError, "alcGetError");
   pragma Import (C, alcGetCurrentContext, "alcGetCurrentContext");
   pragma Import (C, alcOpenDevice, "alcOpenDevice");
   pragma Import (C, alcCloseDevice, "alcCloseDevice");
   pragma Import (C, alcIsExtensionPresent, "alcIsExtensionPresent");
   pragma Import (C, alcGetProcAddress, "alcGetProcAddress");
   pragma Import (C, alcGetEnumValue, "alcGetEnumValue");
   pragma Import (C, alcGetContextsDevice, "alcGetContextsDevice");
   pragma Import (C, alcGetString, "alcGetString");
   pragma Import (C, alcGetIntegerv, "alcGetIntegerv");

end Al.c;
