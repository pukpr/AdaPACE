
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
--  In order to help the Ada programmer, the comments in this file   --
--  are, in great extent, a direct copy of the original text in the  --
--  SDL_mixer header files.                                          --
--  **************************************************************** --

with System;
with Interfaces.C.Strings;
with SDL.Audio;
with SDL.Types; use SDL.Types;
with SDL.RWops;
with SDL.Error;
package SDL.Mixer is
   package A  renames SDL.Audio;
   package C  renames Interfaces.C;
   package RW renames SDL.RWops;
   package CS renames Interfaces.C.Strings;
   package Er renames SDL.Error;

   --  The default mixer has 8 simultaneous mixing channels
   MIX_CHANNELS : constant := 8;

   --  Good default values for a PC soundcard
   MIX_DEFAULT_FREQUENCY : constant := 22050;
   MIX_DEFAULT_FORMAT    : constant := A.AUDIO_S16;
   MIX_DEFAULT_CHANNELS  : constant := 2;
   MIX_MAX_VOLUME        : constant := 128;  -- Volume of a chunk

   --  The internal format for an audion chunk
   type Chunk is
      record
         allocated : C.int;
         abuf      : Uint8_ptr;
         alen      : Uint32;
         volume    : Uint8;  --  Per-sample volume, 0-128
      end record;
   pragma Convention (C, Chunk);

   type Chunk_ptr is access Chunk;
   pragma Convention (C, Chunk_ptr);

   null_Chunk_ptr : constant Chunk_ptr := null;

   --  The different fading types supported
   type Fading is (
      NO_FADING,
      FADING_OUT,
      FADING_IN);
   pragma Convention (C, Fading);

   --  The internal format for a music chunk interpreted via mikmod
   type Music_ptr is new System.Address;

   null_Music_ptr : constant Music_ptr := Music_ptr (System.Null_Address);

   --  Open the mixer with a certain audio format
   function OpenAudio (
      frequency : C.int;
      format    : A.Format_Flag;
      channels  : C.int;
      chunksize : C.int)
      return C.int;
   pragma Import (C, OpenAudio, "Mix_OpenAudio");

   --  Dynamically change the number of channels managed by the mixer.
   --  If decreasing the number of channels, the upper channels are
   --  stopped.
   --  This function returns the new number of allocated channels.
   function AllocateChannels (numchans : C.int) return C.int;
   pragma Import (C, AllocateChannels, "Mix_AllocateChannels");

   --  Find out what the actual audio device parameters are.
   --  This function returns 1 if the audio has been opened, 0 otherwise.
   function QuerySpec (
      frequency : int_ptr;
      format    : A.Format_Flag_ptr; --  Uint16_ptr;
      channels  : int_ptr)
      return C.int;
   pragma Import (C, QuerySpec, "Mix_QuerySpec");

   procedure Query_Spec (
      frequency : out C.int;
      format    : out A.Format_Flag;
      channels  : out C.int);
   pragma Import (C, Query_Spec, "Mix_QuerySpec");

   procedure Query_Spec_VP (
      Result    : out C.int;
      frequency : out C.int;
      format    : out A.Format_Flag_ptr; --  Uint16;
      channels  : out C.int);
   pragma Import (C, Query_Spec_VP, "Mix_QuerySpec");
   pragma Import_Valued_Procedure (Query_Spec_VP);


   --  Load a wave file or a music (.mod .s3m .it .xm) file
   function LoadWAV_RW (
      src     : RW.RWops_ptr;
      freesrc : C.int)
      return Chunk_ptr;
   pragma Import (C, LoadWAV_RW, "Mix_LoadWAV_RW");

   function LoadWAV (file : CS.chars_ptr) return Chunk_ptr;
   pragma Inline (LoadWAV);

   function Load_WAV (file : String) return Chunk_ptr;
   pragma Inline (Load_WAV);

   function LoadMUS (file : CS.chars_ptr) return Music_ptr;
   pragma Import (C, LoadMUS, "Mix_LoadMUS");

   function Load_MUS (file : String) return Music_ptr;
   pragma Inline (Load_MUS);

   --  This hasn't been hooked into music.c yet
   --  Load a music file from an SDL_RWop object (MikMod-specific currently)
   --  Matt Campbell (matt@campbellhome.dhs.org) April 2000
   --  function LoadMUS_RW (r_w : RW.RWops_ptr) return Music_ptr;


   --  Load a wave file of the mixer format from a memory buffer
   function QuickLoad_WAV (mem : Uint8_ptr) return Chunk_ptr;
   pragma Import (C, QuickLoad_WAV, "Mix_QuickLoad_WAV");

   --  Free an audio chunk previously loaded
   procedure FreeChunk (chunk : Chunk_ptr);
   pragma Import (C, FreeChunk, "Mix_FreeChunk");

   procedure FreeMusic (music : Music_ptr);
   pragma Import (C, FreeMusic, "Mix_FreeMusic");

   --  Set a function that is called after all mixing is performed.
   --  This can be used to provide real-time visual display of the audio stream
   --  or add a custom mixer filter for the stream data.
   type Mix_Proc_Type is access
      procedure (udata : System.Address; stream : Uint8_ptr; len : C.int);
   pragma Convention (C, Mix_Proc_Type);

   procedure SetPostMix (
      mix_proc : Mix_Proc_Type;
      arg : System.Address);
   pragma Import (C, SetPostMix, "Mix_SetPostMix");

   --  Add your own music player or additional mixer function.
   --  If 'mix_func' is NULL, the default music player is re-enabled.
   procedure HookMusic (
      mix_proc : Mix_Proc_Type;
      arg      : System.Address);
   pragma Import (C, HookMusic, "Mix_HookMusic");

   type Music_Finished_Type is access procedure;
   pragma Convention (C, Music_Finished_Type);
   
   --  Add your own callback when the music has finished playing.
   procedure HookMusicFinished (
      music_finished : Music_Finished_Type);
   pragma Import (C, HookMusicFinished, "Mix_HookMusicFinished");


   --  Add your own callback when a channel has finished playing. NULL
   --  to disable callback. The callback may be called from the mixer's audio
   --  callback or it could be called as a result of Mix_HaltChannel(), etc.
   --  do not call SDL_LockAudio() from this callback; you will either be
   --  inside the audio callback, or SDL_mixer will explicitly lock the audio
   --  before calling your callback.
   type Channel_Finished_Type is access procedure (Channel : C.Int);
   pragma Convention (C, Channel_Finished_Type);

   procedure HookChannelFinished (Channel_Finished : Channel_Finished_Type);
   pragma Import (C, HookChannelFinished, "Mix_ChannelFinished");


   --  Get a pointer to the user data for the current music hook
   function GetMusicHookData return System.Address;
   pragma Import (C, GetMusicHookData, "Mix_GetMusicHookData");


   --  Reserve the first channels (0 -> n-1) for the application, i.e. don't allocate
   --  them dynamically to the next sample if requested with a -1 value below.
   --  Returns the number of reserved channels.
   function ReservChannels (num : C.int) return C.int;
   pragma Import (C, ReservChannels, "Mix_ReservChannels");

   --  Channel grouping functions

   --  Attach a tag to a channel. A tag can be assigned to several mixer
   --  channels, to form groups of channels.
   --  If 'tag' is -1, the tag is removed (actually -1 is the tag used to
   --  represent the group of all the channels).
   --  Returns true if everything was OK.

   function GroupChannel (
      which : C.int;
      tag   : C.int)
      return C.int;
   pragma Import (C, GroupChannel, "Mix_GroupChannel");

   --  Assign several consecutive channels to a group
   function GroupChannels (
      from   : C.int;
      to     : C.int;
      tag    : C.int)
      return C.int;
   pragma Import (C, GroupChannels, "Mix_GroupChannels");

   --  Finds the first available channel in a group of channels
   function GroupAvailable (tag  : C.int) return C.int;
   pragma Import (C, GroupAvailable, "Mix_GroupAvailable");

   --  Returns the number of channels in a group. This is also a subtle
   --  way to get the total number of channels when 'tag' is -1
   function GroupCount (tag : C.int) return C.int;
   pragma Import (C, GroupCount, "Mix_GroupCount");

   --  Finds the "oldest" sample playing in a group of channels
   function GroupOldest (tag : C.int) return C.int;
   pragma Import (C, GroupOldest, "Mix_GroupOldest");

   --  Finds the "most recent" (i.e. last) sample playing in a group of channels
   function GroupNewer (tag : C.int) return C.int;
   pragma Import (C, GroupNewer, "Mix_GroupNewer");

   --  Play an audio chunk on a specific channel.
   --  If the specified channel is -1, play on the first free channel.
   --  If 'loops' is greater than zero, loop the sound that many times.
   --  If 'loops' is -1, loop inifinitely (~65000 times).
   --  Returns which channel was used to play the sound.
   function PlayChannel (
      channel    : C.int;
      chunk  : Chunk_ptr;
      loops      : C.int)
      return C.int;

   procedure PlayChannel (
      channel    : C.int;
      chunk  : Chunk_ptr;
      loops      : C.int);

   pragma Inline (PlayChannel);

   --  The same as above, but the sound is played at most 'ticks' milliseconds
   function PlayChannelTimed (
      channel : C.int;
      chunk   : Chunk_ptr;
      loops   : C.int;
      ticks   : C.int)
      return C.int;

   procedure PlayChannelTimed (
      channel : C.int;
      chunk   : Chunk_ptr;
      loops   : C.int;
      ticks   : C.int);

   pragma Import (C, PlayChannelTimed, "Mix_PlayChannelTimed");

   function PlayMusic (
      music : Music_ptr;
      loops : C.int)
      return C.int;

   procedure PlayMusic (
      music : Music_ptr;
      loops : C.int);

   pragma Import (C, PlayMusic, "Mix_PlayMusic");

   --  Fade in music or a channel over "ms" milliseconds, same semantics
   --  as the "Play" functions
   function FadeInMusic (
      music : Music_ptr;
      loops : C.int;
      ms    : C.int)
      return C.int;

   procedure FadeInMusic (
      music : Music_ptr;
      loops : C.int;
      ms    : C.int);
   pragma Import (C, FadeInMusic, "Mix_FadeInMusic");

   function FadeInChannel (
      channel : C.int;
      chunk   : Chunk_ptr;
      loops   : C.int;
      ms      : C.int)
      return C.int;
   pragma Inline (FadeInChannel);

   function FadeInChannelTimed (
      channel : C.int;
      chunk   : Chunk_ptr;
      loops   : C.int;
      ms      : C.int;
      ticks   : C.int)
      return C.int;
   pragma Import (C, FadeInChannelTimed, "Mix_FadeInChannelTimed");

   --  Set the volume in the range of 0-128 of a specific channel or chunk.
   --  If the specified channel is -1, set volume for all channels.
   --  Returns the original volume.
   --  If the specified volume is -1, just return the current volume.
   function Volume (
      channel : C.int;
      volume  : C.int)
      return C.int;
   pragma Import (C, Volume, "Mix_Volume");

   function VolumeChunk (
      chunk  : Chunk_ptr;
      volume : C.int)
      return C.int;
   pragma Import (C, VolumeChunk, "Mix_VolumeChunk");

   function VolumeMusic (volume : C.int) return C.int;
   pragma Import (C, VolumeMusic, "Mix_VolumeMusic");

   --  Halt playing of a particular channel
   function HaltChannel (channel : C.int) return C.int;
   pragma Import (C, HaltChannel, "Mix_HaltChannel");

   function HaltGroup (tag : C.int) return C.int;
   pragma Import (C, HaltGroup, "Mix_HaltGroup");

   function HaltMusic return C.int;
   procedure HaltMusic;
   pragma Import (C, HaltMusic, "Mix_HaltMusic");

   --  Change the expiration delay for a particular channel.
   --  The sample will stop playing after the 'ticks' milliseconds have elapsed,
   --  or remove the expiration if 'ticks' is -1
   function ExpireChannel (
      channel : C.int;
      ticks   : C.int)
      return C.int;
   pragma Import (C, ExpireChannel, "Mix_ExpireChannel");

   --  Halt a channel, fading it out progressively till it's silent
   --  The ms parameter indicates the number of milliseconds the fading
   --  will take.
   function FadeOutChannel (
      which : C.int;
      ms    : C.int)
      return C.int;

   procedure FadeOutChannel (
      which : C.int;
      ms    : C.int);

   pragma Import (C, FadeOutChannel, "Mix_FadeOutChannel");

   function FadeOutGroup (
      tag : C.int;
      ms  : C.int)
      return C.int;
   pragma Import (C, FadeOutGroup, "Mix_FadeOutGroup");

   function FadeOutMusic (ms : C.int) return C.int;
   procedure FadeOutMusic (ms : C.int);
   pragma Import (C, FadeOutMusic, "Mix_FadeOutMusic");

   --  Query the fading status of a cYhannel
   function FadingMusic return Fading;
   pragma Import (C, FadingMusic, "Mix_FadingMusic");

   function FadingChannel (which : C.int) return Fading;
   pragma Import (C, FadingChannel, "Mix_FadingChannel");

   --  Pause/Resume a particular channel
   procedure Pause (channel : C.int);
   pragma Import (C, Pause, "Mix_Pause");

   procedure Resume (channel : C.int);
   pragma Import (C, Resume, "Mix_Resume");

   function Paused (channel : C.int) return C.int;
   pragma Import (C, Paused, "Mix_Paused");

   --  Pause/Resume the music stream
   procedure PauseMusic;
   pragma Import (C, PauseMusic, "Mix_PauseMusic");

   procedure ResumeMusic;
   pragma Import (C, ResumeMusic, "Mix_ResumeMusic");

   procedure RewindMusic;
   pragma Import (C, RewindMusic, "Mix_RewindMusic");

   function PausedMusic return C.int;
   pragma Import (C, PausedMusic, "Mix_PausedMusic");

   --  Check the status of a specific channel.
   --  If the specified channel is -1, check all channels.
   function Playing (channel : C.int) return C.int;
   pragma Import (C, Playing, "Mix_Playing");

   function PlayingMusic return C.int;
   pragma Import (C, PlayingMusic, "Mix_PlayingMusic");

   --  Stop music and set external music playback command
   function SetMusicCMD (command : CS.chars_ptr) return C.int;
   procedure SetMusicCMD (command : CS.chars_ptr);
   pragma Import (C, SetMusicCMD, "Mix_SetMusicCMD");

   function Set_Music_CMD (command : String) return Integer;
   pragma Inline (Set_Music_CMD);

   procedure Set_Music_CMD (command : String);
   pragma Inline (Set_Music_CMD);

   procedure CloseAudio;
   pragma Import (C, CloseAudio, "Mix_CloseAudio");

   --  We'll use SDL for reporting errors
   procedure SetError (fmt : CS.chars_ptr) renames Er.SetError;
   procedure Set_Error (fmt : String) renames Er.Set_Error;
   function GetError return CS.chars_ptr renames Er.GetError;
   function Get_Error return String renames Er.Get_Error;

end SDL.Mixer;
