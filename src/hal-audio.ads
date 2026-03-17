
package Hal.Audio is
   --------------------------
   -- AUDIO - sound players
   --------------------------
   pragma Elaborate_Body;

   procedure Play (File_Name : in String; Surrogate : Boolean := False);
   --
   -- Plays an audio file
   --
   -- if surrogate is true then plays the sound in a surrogate task

   procedure Say (Text : in String);
   --
   -- Synthesizes speech from a text file
   --

   function Is_On return Boolean;
   --
   -- Controlled by env variable PACE_AUDIO=0 or 1
   --

------------------------------------------------------------------------------
-- $id: hal-audio.ads,v 1.2 11/04/2002 22:23:25 pukitepa Exp $
------------------------------------------------------------------------------
end Hal.Audio;

