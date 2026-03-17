with Pace;
with Ada.Strings.Unbounded;
package Hal.Audio.Mixer is
   -- pragma Elaborate_Body;

   subtype Channel_Range is Integer range -1 .. 7;
   Idle : constant Channel_Range := Channel_Range'First;

   type Play_Mix is new Pace.Msg with
      record
         File : Ada.Strings.Unbounded.Unbounded_String;
         -- if set to true then assumes file is absolute, whereas normally
         -- the assumption is that the audio file is somewhere in the PACE audio directory
         File_Name_Is_Absolute : Boolean := False;
         Volume : Integer range 0..255 := 100;
         -- true by default.. if false then it will play until finished
         Play_Toggle_To_Halt : Boolean := True;
         -- setting Timed means it will play the file for that many seconds
         -- can't be combined with play_until_finished
         Timed : Duration := 0.0;
         Channel : Channel_Range := Idle; -- for internal use, not to be set manually
      end record;
   procedure Inout (Obj : in out Play_Mix);

   -- use this to instantiate a new play_Mix
   function Init (File : String; Volume : Integer := 100; Timed : Duration := 0.0) return Play_Mix;

   -- creates a wav file that says Text and mixes it in through the mixer
   procedure Say (Text : in String; Volume : Integer := 100);

   procedure Shutdown;

   -- $Id: hal-audio-mixer.ads,v 1.6 2005/12/21 15:47:36 pukitepa Exp $
end Hal.Audio.Mixer;
