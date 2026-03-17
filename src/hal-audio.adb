with Ada.Characters.Handling;
with Gnat.Os_Lib;
with Pace.Log;
--with Pace.Semaphore;
with Pace;
with Pace.Config;
with Pace.Surrogates;
with Ada.Strings.Unbounded;

package body Hal.Audio is
   Audio_Is_On : constant Boolean := 0 < Pace.Getenv("PACE_AUDIO", 1);
   Sim :  constant Boolean := 0 < Pace.Getenv ("PACE_SIM", 0);

   Play_Exec : constant String := Pace.Config.Find_File ("/audio/play");
   Say_Exec : constant String := Pace.Config.Find_File ("/audio/say");

   procedure Play_Sound (File_Name : in String) is
      Ok : Boolean;
      Name : aliased String := Pace.Config.Find_File ("/audio/" & File_Name);
   begin
      Gnat.Os_Lib.Spawn (Play_Exec, (1 => Name'Unchecked_Access), Ok);
      if not Ok then
         Pace.Log.Put_Line ("Should be Playing: " & Name);
      end if;
   end Play_Sound;

   -- plays an audio file in a surrogate task
   type Play_Surrogate is new Pace.Msg with
      record
         File_Name : Ada.Strings.Unbounded.Unbounded_String;
      end record;
   procedure Input (Obj : Play_Surrogate);
   procedure Input (Obj : Play_Surrogate) is
   begin
      Play_Sound (Ada.Strings.Unbounded.To_String (Obj.File_Name));
   end Input;

   procedure Play (File_Name : in String; Surrogate : Boolean := False) is
   begin
      if Audio_Is_On and not Sim then
         if Surrogate then
            declare
               Msg : Play_Surrogate;
            begin
               Msg.File_Name := Ada.Strings.Unbounded.To_Unbounded_String (File_Name);
               Pace.Surrogates.Input (Msg);
            end;
         else
            Play_Sound (File_Name);
         end if;
      end if;
   end Play;

   procedure Say (Text : in String) is
      Ok : Boolean;
      Say_Text : aliased String := Ada.Characters.Handling.To_Lower (Text);
   begin
      if Audio_Is_On and not Sim then
         Gnat.Os_Lib.Spawn (Say_Exec, (1 => Say_Text'Unchecked_Access), Ok);
         if not Ok then
            Pace.Log.Put_Line ("Should be Saying: " & Say_Text);
         end if;
      end if;
   end Say;

   function Is_On return Boolean is
   begin
      return Audio_Is_On;
   end Is_On;
------------------------------------------------------------------------------
-- $id: hal-audio.adb,v 1.3 10/30/2003 15:14:21 ludwiglj Exp $
------------------------------------------------------------------------------
end Hal.Audio;

