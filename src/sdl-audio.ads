
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
with SDL.Types; use SDL.Types;
with SDL.RWops;

package SDL.Audio is
   pragma Elaborate_Body;
   package C renames Interfaces.C;

   type Callback_ptr_Type is access procedure (
                              userdata : void_ptr;
                              stream   : Uint8_ptr;
                              len      : C.int);
   pragma Convention (C, Callback_ptr_Type);
   
   --  The calculated values in this structure are calculated by OpenAudio
   type AudioSpec is
      record
         freq     : C.int;   --  DSP frequency -- samples per second
         format   : Uint16;  --  Audio data format
         channels : Uint8;   --  Number of channels: 1 mono, 2 stereo
         silence  : Uint8;   --  Audio buffer silence value (calculated)
         samples  : Uint16;  --  Audio buffer size in samples
         padding  : Uint16;  --  Necessary for some compile environments
         size     : Uint32;  --  Audio buffer size in bytes (calculated)
         --  This function is called when the audio device needs more data.
         --  'stream' is a pointer to the audio data buffer
         --  'len' is the length of that buffer in bytes.
         --  Once the callback returns, the buffer will no longer be valid.
         --  Stereo samples are stored in a LRLRLR ordering.
         callback : Callback_ptr_Type;
         userdata : void_ptr;
      end record;
   pragma Convention (C, AudioSpec);
   
   type AudioSpec_ptr is access all AudioSpec;
   pragma Convention (C, AudioSpec_ptr);

   type Format_Flag is mod 2**16;
   pragma Convention (C, Format_Flag);

   type Format_Flag_ptr is access Format_Flag;
   pragma Convention (C, Format_Flag_ptr);

   --  Audio format flags (defaults to LSB byte order)
   
   --  Unsigned 8-bit samples
   AUDIO_U8      : constant Format_Flag := 16#0008#;
   --  Signed 8-bit samples
   AUDIO_S8      : constant Format_Flag := 16#8008#;
   --  Unsigned 16-bit samples
   AUDIO_U16LSB  : constant Format_Flag := 16#0010#;
   --  Signed 16-bit samples
   AUDIO_S16LSB  : constant Format_Flag := 16#8010#;
   --  As above, but big-endian byte order
   AUDIO_U16MSB  : constant Format_Flag := 16#1010#;
   --  As above, but big-endian byte order
   AUDIO_S16MSB  : constant Format_Flag := 16#9010#;
   
   AUDIO_U16     : constant Format_Flag := AUDIO_U16LSB;
   AUDIO_S16     : constant Format_Flag := AUDIO_S16LSB;
   
   function Get_Audio_U16_Sys return Format_Flag;
   
   function Get_Audio_S16_Sys return Format_Flag;

   --  A structure to hold a set of audio conversion filters and buffers
   type AudioCVT;
   type AudioCVT_ptr is access all AudioCVT;
   pragma Convention (C, AudioCVT_ptr);
   type filter_ptr is access procedure (
                                cvt    : AudioCVT_ptr;
                                format : Uint16);
   pragma Convention (C, filter_ptr);
   type filters_array is array (0 .. 9) of filter_ptr;
   pragma Convention (C, filters_array);
   type AudioCVT is
      record
         need         : C.int;     --  Set to 1 if conversion possible
         src_format   : Uint16;    --  Source audio format
         dst_format   : Uint16;    --  Target audio format
         rate_incr    : C.double;  --  Rate conversion increment
         buf          : Uint8_ptr; --  Buffer to hold entire audio data
         len          : C.int;     --  Length of original audio buffer
         len_cvt      : C.int;     --  Length of converted audio buffer
         len_mult     : C.int;     --  buffer must be len*len_mult big
         len_ratio    : C.double;  --  Given len, final size is len*len_ratio
         filters      : filters_array;
         filter_index : filters_array; --  Current audio conversion function
      end record;
   pragma Convention (C, AudioCVT);

   --  -------------------
   --  Function prototypes
   --  -------------------
   
   --  These function and procedure  are used internally, and should not
   --  be used unless you have a specific need to specify the audio driver
   --  you want to use.You should normally use Init or InitSubSystem.
   function AudioInit (driver_name : C.Strings.chars_ptr) return C.int;
   pragma Import (C, AudioInit, "SDL_AudioInit");
      
   procedure AudioQuit;
   pragma Import (C, AudioQuit, "SDL_AudioQuit");

   --  This function fills the given character buffer with the name of the
   --  current audio driver, and returns a pointer to it if the audio driver
   --  has been initialized. It returns NULL if no driver has been initialized.
   function AudioDriverName (
      namebuf : C.Strings.chars_ptr;
      maslen  : C.int)
      return C.Strings.chars_ptr;
   pragma Import (C, AudioDriverName, "SDL_AudioDriverName");

   --  This function opens the audio device with the desired parameters, and
   --  returns 0 if successful, placing the actual hardware parameters in the
   --  structure pointed to by 'obtained'.  If 'obtained' is NULL, the audio
   --  data passed to the callback function will be guaranteed to be in the
   --  requested format, and will be automatically converted to the hardware
   --  audio format if necessary.  This function returns -1 if it failed
   --  to open the audio device, or couldn't set up the audio thread.

   --  When filling in the desired audio spec structure,
   --  'desired.freq' should be the desired audio frequency in samples-per-sec.
   --  'desired.format' should be the desired audio format.
   --  'desired.samples' is the desired size of the audio buffer, in samples.
   --    This number should be a power of two, and may be adjusted by the audio
   --    driver to a value more suitable for the hardware.  Good values seem to
   --    range between 512 and 8096 inclusive, depending on the application and
   --    CPU speed.  Smaller values yield faster response time, but can lead
   --    to underflow if the application is doing heavy processing and cannot
   --    fill the audio buffer in time.  A stereo sample consists of both right
   --    and left channels in LR ordering.
   --    Note that the number of samples is directly related to time by the
   --    following formula:  ms := (samples*1000)/freq
   --  'desired->size' is the size in bytes of the audio buffer, and is
   --    calculated by OpenAudio.
   --  'desired->silence' is the value used to set the buffer to silence,
   --    and is calculated by OpenAudio.
   --  'desired->callback' should be set to a function that will be called
   --    when the audio device is ready for more data.  It is passed a pointer
   --    to the audio buffer, and the length in bytes of the audio buffer.
   --    This function usually runs in a separate thread, and so you should
   --    protect data structures that it accesses by calling LockAudio
   --    and UnlockAudio in your code.
   --  'desired.userdata' is passed as the first parameter to your callback
   --    function.

   --  The audio device starts out playing silence when it's opened, and should
   --  be enabled for playing by calling PauseAudio(0) when you are ready
   --  for your audio callback function to be called.  Since the audio driver
   --  may modify the requested size of the audio buffer, you should allocate
   --  any local mixing buffers after you open the audio device.
  
   function OpenAudio (
      desired  : AudioSpec_ptr;
      obtained : AudioSpec_ptr)
      return C.int;
   pragma Import (C, OpenAudio, "SDL_OpenAudio");

   --  Get the current audio state:
   type audiostatus is new C.int;
   AUDIO_STOPED  : constant := 0;
   AUDIO_PLAYING : constant := 1;
   AUDIO_PAUSED  : constant := 2;
   
   function GetAudioStatus return audiostatus;
   pragma Import (C, GetAudioStatus, "SDL_GetAudioStatus");

   --  This function pauses and unpauses the audio callback processing.
   --  It should be called with a parameter of 0 after opening the audio
   --  device to start playing sound.  This is so you can safely initialize
   --  data for your callback function after opening the audio device.
   --  Silence will be written to the audio device during the pause.
   procedure PauseAudio (pause_on : C.int);
   pragma Import (C, PauseAudio, "SDL_PauseAudio");


   --  This function loads a WAVE from the data source, automatically freeing
   --  that source if 'freesrc' is non-zero.  For example, to load a WAVE file,
   --  you could do:
   --      LoadWAV_RW(RWFromFile("sample.wav", "rb"), 1, ...);

   --  If this function succeeds, it returns the given AudioSpec,
   --  filled with the audio data format of the wave data, and sets
   --  'audio_buf' to a malloc()'d buffer containing the audio data,
   --  and sets 'audio_len' to the length of that audio buffer, in bytes.
   --  You need to free the audio buffer with FreeWAV when you are
   --  done with it.
   
   --  This function returns NULL and sets the SDL error message if the
   --  wave file cannot be opened, uses an unknown data format, or is
   --  corrupt.  Currently raw and MS-ADPCM WAVE files are supported.
   function LoadWAV_RW (
      src : SDL.RWops.RWops_ptr;
      freesrc : C.int;
      spec : AudioSpec_ptr;
      audio_buf : Uint8_ptr_ptr;
      audio_len : Uint32_ptr)
      return AudioSpec_ptr;
   pragma Import (C, LoadWAV_RW, "SDL_LoadWAV_RW");

   function LoadWAV (
      file : C.Strings.chars_ptr;
      spec : AudioSpec_ptr;
      audio_buf : Uint8_ptr_ptr;
      audio_len : Uint32_ptr)
      return AudioSpec_ptr;
   pragma Inline (LoadWAV);
 
   --  LoadWAV_RW_VP not working properly
   --  for some strange reason. Result is Always null.
   procedure LoadWAV_RW_VP (
      Result : out AudioSpec_ptr;
      src : SDL.RWops.RWops_ptr;
      freesrc : C.int;
      spec : out AudioSpec_ptr;
      audio_buf : out Uint8_ptr;
      audio_len : out Uint32);
   pragma Import (C, LoadWAV_RW_VP, "SDL_LoadWAV_RW");
   pragma Import_Valued_Procedure (LoadWAV_RW_VP);
  
   procedure Load_WAV (
      file : C.Strings.chars_ptr;
      spec : AudioSpec_ptr;      --  out AudioSpec
      audio_buf : Uint8_ptr_ptr; --  out Uint8_ptr
      audio_len : Uint32_ptr;    --  out Uint32
      Valid_WAV : out Boolean);
   pragma Inline (Load_WAV);
   
   --  This function frees data previously allocated with SDL_LoadWAV_RW()
   procedure FreeWAV (audio_buf : Uint8_ptr);
   pragma Import (C, FreeWAV, "SDL_FreeWAV");

   --  This function takes a source format and rate and a destination format
   --  and rate, and initializes the 'cvt' structure with information needed
   --  by ConvertAudio to convert a buffer of audio data from one format
   --  to the other.
   --  This function returns 0, or -1 if there was an error.
   function BuildAudioCVT (
      cvt : AudioCVT_ptr;
      src_format : Uint16;
      src_channels : Uint8;
      src_rate     : C.int;
      dst_format   : Uint16;
      dst_channels : Uint8;
      dst_rate     : C.int)
      return C.int;
   pragma Import (C, BuildAudioCVT, "SDL_BuildAudioCVT");

   
   --  Once you have initialized the 'cvt' structure using BuildAudioCVT,
   --  created an audio buffer cvt.buf, and filled it with cvt.len bytes of
   --  audio data in the source format, this function will convert it in-place
   --  to the desired format.
   --  The data conversion may expand the size of the audio data, so the buffer
   --  cvt.buf should be allocated after the cvt structure is initialized by
   --  BuildAudioCVT, and should be cvt.len * cvt.len_mult bytes long.
   function ConvertAudio (cvt : AudioCVT_ptr) return C.int;
   pragma Import (C, ConvertAudio, "SDL_ConvertAudio");

   --  This takes two audio buffers of the playing audio format and mixes
   --  them, performing addition, volume adjustment, and overflow clipping.
   --  The volume ranges from 0 - 128, and should be set to _MIX_MAXVOLUME
   --  for full audio volume.  Note this does not change hardware volume.
   --  This is provided for convenience -- you can mix your own audio data.
   MIX_MAXVOLUME : constant := 128;
   procedure MixAudio (
      dst    : Uint8_ptr;
      src    : Uint8_ptr;
      len    : Uint32;
      volume : C.int);
   pragma Import (c, MixAudio, "SDL_MixAudio");


   --  The lock manipulated by these functions protects the callback function.
   --  During a LockAudio/UnlockAudio pair, you can be guaranteed that the
   --  callback function is not running.  Do not call these from the callback
   --  function or you will cause deadlock.
   procedure LockAudio;
   pragma Import (C, LockAudio, "SDL_LockAudio");
   
   procedure UnlockAudio;
   pragma Import (C, UnlockAudio, "SDL_UnlockAudio");

   --  This procedure shuts down audio processing and closes the audio device.
   procedure CloseAudio;
   pragma Import (C, CloseAudio, "SDL_CloseAudio");
   

end SDL.Audio;
