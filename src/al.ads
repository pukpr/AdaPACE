-- ----------------------------------------------------------------------------
------------------------------------------
-- ****************************************************************************
--****************************************
-- ----------------------------------------------------------------------------
------------------------------------------
--
-- PACKAGE NAME   - Al
--(OpenALada - Ada binding to OpenAL)
--
-- DESCRIPTION    - This file implements the OpenAL "Al.h" and "Altypes.h"
--headers.
--
-- REFERENCE      - For information about OpenAL visit: www.OpenAL.org
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
--                            |           | a) Removed Pragma "Linker_Options
--(...)"
--                            |           | b) Included Pragma "Preelaborate
--(...)"
--                            |           | c) Included Pragma "Pack (...)"
--for unconstrained arrays
--                            |           | d) Included Pragma "Convension (C,
--...)" for access pointers
--                            |           | e) Included "for Al.ALvoid'size
--use 1"
--                            |           | f) Redefined type "lpALstr" as
--"Interfaces.C.Char_array"
--                            |           | g) Saved file as an Ada
--specification (.ads)
--                            |           |
--                            |           | Note: "pragma Pack (ALvoid_Array)"
--generates a warning in ObjectAda 7.1.2a
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
with System;

package Al is

   pragma Preelaborate (Al);

   -- -------------------------------------------------------------------------
   -------------------------------------------
   -- OpenAL types
   -- -------------------------------------------------------------------------
   -------------------------------------------

   subtype ALsize_t is Interfaces.C.size_t; -- Max array size in bytes

   type ALvoid is new System.Address; -- Any type
--   for ALvoid'Size use 1;
--   pragma Convention (C, ALvoid);
   type lpALvoid is access all Al.ALvoid; -- R/W access ptr to ALvoid
   pragma Convention (C, lpALvoid);
   type ALvoid_Array is array (Al.ALsize_t range <>) of aliased Al.ALvoid;
   type lplpVoid is access all Al.lpALvoid; -- R/W access ptr to another ptr
   pragma Convention (C, lplpVoid);

   subtype ALchar is Interfaces.C.char; -- 8-bit signed ANSI character
   type lpALchar is access all Al.ALchar; -- R/W access ptr to ALchar
   pragma Convention (C, lpALchar);
   type lplpALchar is access all Al.lpALchar;
   pragma Convention (C, lplpALchar);
   type ALchar_Array is array (Al.ALsize_t range <>) of aliased Al.ALchar;
   pragma Convention (C, ALchar_Array);

   --subtype lpALstr is Al.lpALchar;
   ---- Removed: 28 Feb 2005
   subtype lpALstr is Interfaces.C.char_array; -- New: 28 Feb 2005, C string

   subtype ALbyte is Interfaces.C.char; -- 8-bit signed byte
   type lpALbyte is access all Al.ALbyte;
   pragma Convention (C, lpALbyte);
   type ALbyte_Array is array (Al.ALsize_t range <>) of aliased Al.ALbyte;
   pragma Convention (C, ALbyte_Array);

   subtype ALubyte is Interfaces.C.unsigned_char; -- 8-bit unsigned byte
   type lpALubyte is access all Al.ALubyte;
   pragma Convention (C, lpALubyte);
   type ALubute_Array is array (Al.ALsize_t range <>) of aliased Al.ALubyte;
   pragma Convention (C, ALubute_Array);

   subtype ALshort is Interfaces.C.short; -- 16-bit signed short integer
   type lpALshort is access all Al.ALshort;
   pragma Convention (C, lpALshort);
   type ALshort_Array is array (Al.ALsize_t range <>) of aliased Al.ALshort;
   pragma Convention (C, ALshort_Array);

   subtype ALushort is Interfaces.C.unsigned_short;   -- 16-bit unsigned short
                                                      --integer
   type lpALushort is access all Al.ALushort;
   pragma Convention (C, lpALushort);
   type ALushort_Array is
     array (Al.ALsize_t range <>) of aliased Al.ALushort;
   pragma Convention (C, ALushort_Array);

   subtype ALint is Interfaces.C.int; -- 32-bit signed integer
   type lpALint is access all Al.ALint;
   pragma Convention (C, lpALint);
   type ALint_Array is array (Al.ALsize_t range <>) of aliased Al.ALint;
   pragma Convention (C, ALint_Array);

   subtype ALuint is Interfaces.C.unsigned; -- 32-bit unsigned integer
   type lpALuint is access all Al.ALuint;
   pragma Convention (C, lpALuint);
   type ALuint_Array is array (Al.ALsize_t range <>) of aliased Al.ALuint;
   pragma Convention (C, ALuint_Array);

   subtype ALfloat is Interfaces.C.C_float; -- 32-bit floating point
   type lpALfloat is access all Al.ALfloat;
   pragma Convention (C, lpALfloat);
   type ALfloat_Array is array (Al.ALsize_t range <>) of aliased Al.ALfloat;
   pragma Convention (C, ALfloat_Array);

   subtype ALdouble is Interfaces.C.double; -- 64-bit floating point
   type lpALdouble is access all Al.ALdouble;
   pragma Convention (C, lpALdouble);
   type ALdouble_Array is
     array (Al.ALsize_t range <>) of aliased Al.ALdouble;
   pragma Convention (C, ALdouble_Array);

   subtype ALboolean is Interfaces.C.int; -- Boolean
   type lpALboolean is access all Al.ALboolean;
   pragma Convention (C, lpALboolean);

   subtype ALenum is Al.ALint; -- Enumerations
   type lpALenum is access all Al.ALenum;
   pragma Convention (C, lpALenum);

   subtype ALsizei is Al.ALint;
   type lpALsizei is access all Al.ALsizei;
   pragma Convention (C, lpALsizei);

   subtype ALclampd is Al.ALdouble; -- Bitfields
   type lpALclampd is access all Al.ALclampd;
   pragma Convention (C, lpALclampd);

   -- -------------------------------------------------------------------------
   -------------------------------------------
   -- OpenAL Constants
   -- -------------------------------------------------------------------------
   -------------------------------------------

   AL_INVALID : constant := -1;
   AL_NONE    : constant := 0;

   AL_FALSE : constant Al.ALboolean := 0;
   AL_TRUE  : constant Al.ALboolean := 1;

   AL_SOURCE_TYPE     : constant := 16#0200#;
   AL_SOURCE_ABSOLUTE : constant := 16#0201#;
   AL_SOURCE_RELATIVE : constant := 16#0202#;

   AL_CONE_INNER_ANGLE : constant := 16#1001#;
   AL_CONE_OUTER_ANGLE : constant := 16#1002#;
   AL_PITCH            : constant := 16#1003#;
   AL_POSITION         : constant := 16#1004#;
   AL_DIRECTION        : constant := 16#1005#;
   AL_VELOCITY         : constant := 16#1006#;
   AL_LOOPING          : constant := 16#1007#;
   AL_STREAMING        : constant := 16#1008#;
   AL_BUFFER           : constant := 16#1009#;
   AL_GAIN             : constant := 16#100A#;
   AL_BYTE_LOKI        : constant := 16#100C#;
   AL_MIN_GAIN         : constant := 16#100D#;
   AL_MAX_GAIN         : constant := 16#100E#;
   AL_ORIENTATION      : constant := 16#100F#;
   AL_CHANNEL_MASK     : constant := 16#3000#;

   AL_SOURCE_STATE : constant := 16#1010#;
   AL_INITIAL      : constant := 16#1011#;
   AL_PLAYING      : constant := 16#1012#;
   AL_PAUSED       : constant := 16#1013#;
   AL_STOPPED      : constant := 16#1014#;

   AL_BUFFERS_QUEUED    : constant := 16#1015#;
   AL_BUFFERS_PROCESSED : constant := 16#1016#;

   AL_FORMAT_MONO8    : constant := 16#1100#;
   AL_FORMAT_MONO16   : constant := 16#1101#;
   AL_FORMAT_STEREO8  : constant := 16#1102#;
   AL_FORMAT_STEREO16 : constant := 16#1103#;

   AL_REFERENCE_DISTANCE : constant := 16#1020#;
   AL_ROLLOFF_FACTOR     : constant := 16#1021#;
   AL_CONE_OUTER_GAIN    : constant := 16#1022#;
   AL_MAX_DISTANCE       : constant := 16#1023#;

   AL_FREQUENCY : constant := 16#2001#;
   AL_BITS      : constant := 16#2002#;
   AL_CHANNELS  : constant := 16#2003#;
   AL_SIZE      : constant := 16#2004#;
   AL_DATA      : constant := 16#2005#;

   AL_UNUSED    : constant := 16#2010#;
   AL_PENDING   : constant := 16#2011#;
   AL_PROCESSED : constant := 16#2012#;

   AL_NO_ERROR          : constant := Al.AL_FALSE;
   AL_INVALID_NAME      : constant := 16#A001#;
   AL_ILLEGAL_ENUM      : constant := 16#A002#;
   AL_INVALID_ENUM      : constant := 16#A002#;
   AL_INVALID_VALUE     : constant := 16#A003#;
   AL_ILLEGAL_COMMAND   : constant := 16#A004#;
   AL_INVALID_OPERATION : constant := 16#A004#;
   AL_OUT_OF_MEMORY     : constant := 16#A005#;

   AL_VENDOR     : constant := 16#B001#;
   AL_VERSION    : constant := 16#B002#;
   AL_RENDERER   : constant := 16#B003#;
   AL_EXTENSIONS : constant := 16#B004#;

   AL_DOPPLER_FACTOR   : constant := 16#C000#;
   AL_DOPPLER_VELOCITY : constant := 16#C001#;

   AL_DISTANCE_MODEL           : constant := 16#D000#;
   AL_INVERSE_DISTANCE         : constant := 16#D001#;
   AL_INVERSE_DISTANCE_CLAMPED : constant := 16#D002#;

   -- -------------------------------------------------------------------------
   -------------------------------------------
   -- OpenAL API
   -- -------------------------------------------------------------------------
   -------------------------------------------

   procedure alEnable (capability : Al.ALenum);

   procedure alDisable (capability : Al.ALenum);

   function alIsEnabled (capability : Al.ALenum) return Al.ALboolean;

   procedure alHint (target : Al.ALenum; mode : Al.ALenum);

   procedure alGetBooleanv (param : Al.ALenum; data : Al.lpALboolean);

   procedure alGetIntegerv (param : ALenum; data : Al.lpALint);

   procedure alGetFloatv (param : Al.ALenum; data : Al.lpALfloat);

   procedure alGetDoublev (param : Al.ALenum; data : Al.lpALdouble);

--   function alGetString (param : Al.ALenum) return Al.lpALstr;

   function alGetBoolean (param : Al.ALenum) return Al.ALboolean;

   function alGetInteger (param : Al.ALenum) return Al.ALint;

   function alGetFloat (param : Al.ALenum) return Al.ALfloat;

   function alGetDouble (param : Al.ALenum) return Al.ALdouble;

   function alGetError return Al.ALenum;

   function alIsExtensionPresent (fname : Al.lpALstr) return Al.ALboolean;

   function alGetProcAddress (fname : Al.lpALstr) return Al.lpALvoid;

   function alGetEnumValue (ename : Al.lpALstr) return Al.ALenum;

   procedure alListenerf (param : Al.ALenum; value : Al.ALfloat);

   procedure alListeneri (param : Al.ALenum; value : Al.ALint);

   procedure alListener3f
     (param : Al.ALenum;
      f1    : Al.ALfloat;
      f2    : Al.ALfloat;
      f3    : Al.ALfloat);

   procedure alListenerfv (pname : Al.ALenum; param : Al.lpALfloat);

   procedure alGetListeneri (pname : Al.ALenum; value : Al.lpALint);

   procedure alGetListenerf (pname : Al.ALenum; value : Al.lpALfloat);

   procedure alGetListenerfv (pname : Al.ALenum; values : Al.lpALfloat);

   procedure alGetListener3f
     (pname : Al.ALenum;
      f1    : Al.lpALfloat;
      f2    : Al.lpALfloat;
      f3    : Al.lpALfloat);

   procedure alGenSources (n : Al.ALsizei; sources : Al.lpALuint);

   procedure alDeleteSources (n : Al.ALsizei; sources : Al.lpALuint);

   function alIsSource (sid : Al.ALuint) return Al.ALboolean;

   procedure alSourcei
     (sid   : Al.ALuint;
      pname : Al.ALenum;
      value : Al.ALint);

   procedure alSourcef
     (sid   : Al.ALuint;
      pname : Al.ALenum;
      value : Al.ALfloat);

   procedure alSource3f
     (sid   : Al.ALuint;
      pname : Al.ALenum;
      f1    : Al.ALfloat;
      f2    : Al.ALfloat;
      f3    : Al.ALfloat);

   procedure alSourcefv
     (sid    : Al.ALuint;
      pname  : Al.ALenum;
      values : Al.lpALfloat);

   procedure alGetSourcei
     (sid   : Al.ALuint;
      pname : Al.ALenum;
      value : Al.lpALint);

   procedure alGetSourcef
     (sid   : Al.ALuint;
      pname : Al.ALenum;
      value : Al.lpALfloat);

   procedure alGetSourcefv
     (sid    : Al.ALuint;
      pname  : Al.ALenum;
      values : Al.lpALfloat);

   procedure alGetSource3f
     (sid   : Al.ALuint;
      pname : Al.ALenum;
      f1    : Al.lpALfloat;
      f2    : Al.lpALfloat;
      f3    : Al.lpALfloat);

   procedure alSourcePlayv (ns : Al.ALsizei; ids : Al.lpALuint);

   procedure alSourceStopv (ns : Al.ALsizei; ids : Al.lpALuint);

   procedure alSourceRewindv (ns : Al.ALsizei; ids : Al.lpALuint);

   procedure alSourcePausev (ns : Al.ALsizei; ids : Al.lpALuint);

   procedure alSourcePlay (sid : Al.ALuint);

   procedure alSourcePause (sid : Al.ALuint);

   procedure alSourceRewind (sid : Al.ALuint);

   procedure alSourceStop (sid : Al.ALuint);

   procedure alGenBuffers (n : Al.ALsizei; buffers : Al.lpALuint);

   procedure alDeleteBuffers (n : Al.ALsizei; buffers : Al.lpALuint);

   function alIsBuffer (buffer : Al.ALuint) return Al.ALboolean;

   procedure alBufferData
     (buffer : Al.ALuint;
      format : Al.ALenum;
      data   : Al.lpALvoid;
      size   : Al.ALsizei;
      freq   : Al.ALsizei);

   procedure alGetBufferi
     (buffer : Al.ALuint;
      param  : Al.ALenum;
      value  : Al.lpALint);

   procedure alGetBufferf
     (buffer : Al.ALuint;
      param  : Al.ALenum;
      value  : Al.lpALfloat);

   procedure alSourceQueueBuffers
     (sid        : Al.ALuint;
      numEntries : Al.ALsizei;
      bids       : Al.lpALuint);

   procedure alSourceUnqueueBuffers
     (sid        : Al.ALuint;
      numEntries : Al.ALsizei;
      bids       : Al.lpALuint);

   procedure alDopplerFactor (value : Al.ALfloat);

   procedure alDopplerVelocity (value : Al.ALfloat);

   procedure alDistanceModel (distanceModel : Al.ALenum);

private

   pragma Import (C, alEnable, "alEnable");
   pragma Import (C, alDisable, "alDisable");
   pragma Import (C, alIsEnabled, "alIsEnabled");
   pragma Import (C, alHint, "alHint");
   pragma Import (C, alGetBooleanv, "alGetBooleanv");
   pragma Import (C, alGetIntegerv, "alGetIntegerv");
   pragma Import (C, alGetFloatv, "alGetFloatv");
   pragma Import (C, alGetDoublev, "alGetDoublev");
--   pragma Import (C, alGetString, "alGetString");
   pragma Import (C, alGetBoolean, "alGetBoolean");
   pragma Import (C, alGetInteger, "alGetInteger");
   pragma Import (C, alGetFloat, "alGetFloat");
   pragma Import (C, alGetDouble, "alGetDouble");
   pragma Import (C, alGetError, "alGetError");
   pragma Import (C, alIsExtensionPresent, "alIsExtensionPresent");
   pragma Import (C, alGetProcAddress, "alGetProcAddress");
   pragma Import (C, alGetEnumValue, "alGetEnumValue");
   pragma Import (C, alListenerf, "alListenerf");
   pragma Import (C, alListeneri, "alListeneri");
   pragma Import (C, alListener3f, "alListener3f");
   pragma Import (C, alListenerfv, "alListenerfv");
   pragma Import (C, alGetListeneri, "alGetListeneri");
   pragma Import (C, alGetListenerf, "alGetListenerf");
   pragma Import (C, alGetListenerfv, "alGetListenerfv");
   pragma Import (C, alGetListener3f, "alGetListener3f");
   pragma Import (C, alGenSources, "alGenSources");
   pragma Import (C, alDeleteSources, "alDeleteSources");
   pragma Import (C, alIsSource, "alIsSource");
   pragma Import (C, alSourcei, "alSourcei");
   pragma Import (C, alSourcef, "alSourcef");
   pragma Import (C, alSource3f, "alSource3f");
   pragma Import (C, alSourcefv, "alSourcefv");
   pragma Import (C, alGetSourcei, "alGetSourcei");
   pragma Import (C, alGetSourcef, "alGetSourcef");
   pragma Import (C, alGetSourcefv, "alGetSourcefv");
   pragma Import (C, alGetSource3f, "alGetSource3f");
   pragma Import (C, alSourcePlayv, "alSourcePlayv");
   pragma Import (C, alSourceStopv, "alSourceStopv");
   pragma Import (C, alSourceRewindv, "alSourceRewindv");
   pragma Import (C, alSourcePausev, "alSourcePausev");
   pragma Import (C, alSourcePlay, "alSourcePlay");
   pragma Import (C, alSourcePause, "alSourcePause");
   pragma Import (C, alSourceRewind, "alSourceRewind");
   pragma Import (C, alSourceStop, "alSourceStop");
   pragma Import (C, alGenBuffers, "alGenBuffers");
   pragma Import (C, alDeleteBuffers, "alDeleteBuffers");
   pragma Import (C, alIsBuffer, "alIsBuffer");
   pragma Import (C, alBufferData, "alBufferData");
   pragma Import (C, alGetBufferi, "alGetBufferi");
   pragma Import (C, alGetBufferf, "alGetBufferf");
   pragma Import (C, alSourceQueueBuffers, "alSourceQueueBuffers");
   pragma Import (C, alSourceUnqueueBuffers, "alSourceUnqueueBuffers");
   pragma Import (C, alDopplerFactor, "alDopplerFactor");
   pragma Import (C, alDopplerVelocity, "alDopplerVelocity");
   pragma Import (C, alDistanceModel, "alDistanceModel");

end Al;
