with Ada.Exceptions;
with Al.Linkage;
with Al.Ut;
with Interfaces.C;
with System;
with Unchecked_Conversion;

package body Hal.Audio3d is

   use Al;

   -- Make the binding use arrays instead of pointers to scalars
   pragma Warnings (Off);
   function To_Dof is new Unchecked_Conversion (System.Address, Lpalfloat);
   function to_ptr is new Unchecked_Conversion (System.Address, Lpaluint);
   pragma Warnings (On);

   Max_Sources : constant := 1000;

   Buffer : array (Handle range 0 .. Max_Sources) of Aluint;
   Source : array (Handle range 0 .. Max_Sources) of Aluint;

   Next_Buffer, Next_Source : Handle := 0;

   procedure Init is
      Argc : aliased Alint := 0;
      Argv : aliased Lpalchar := new Al.Alchar'(Interfaces.C.Nul);
   begin
      -- Initialize OpenAL
      Al.Ut.Alutinit (Argc'Unchecked_Access, Argv'Unchecked_Access);
      -- Global settings
      Allistenerf (AL_GAIN, 1.0);
      Aldopplerfactor (1.0); -- don't exaggerate doppler shift
      Aldopplervelocity (343.0); -- using meters/second
   end Init;

   procedure Listener_Position (Pos : in Position; Rot : in To_Up) is
   begin
      Allistenerfv (AL_POSITION, To_Dof (Pos'Address));
      Allistenerfv (AL_ORIENTATION, To_Dof (Rot'Address));
   end Listener_Position;

   procedure Check (Value : in Al.Alenum; Clear : in Boolean := False) is
      use type ALenum;
   begin
      if Clear then
         null;
      elsif Value /= AL_NO_ERROR then
         Ada.Exceptions.Raise_Exception (Audio_Error'Identity, "AL error code =" & Alenum'Image (Value));
      end if;
   end Check;

   function Load_File (Name : in String; Repeat : in Boolean) return Handle is
      Size, Freq : aliased Alsizei;
      Format : aliased Alenum;
      Data : aliased Lpalvoid;
      Aloop : aliased Alboolean := Boolean'Pos (Repeat);
   begin
      Check (Algeterror, True);
      alGenBuffers (1, To_Ptr (Buffer (Next_Buffer)'Address));
      Check (Algeterror);
      -- Create source
      Algensources (1, To_Ptr (Source (Next_Source)'Address));
      Check (Algeterror);
      Al.Ut.Alutloadwavfile (Interfaces.C.To_C (Name),
                             Format'Unchecked_Access,
                             Data'Unchecked_Access,
                             Size'Unchecked_Access,
                             Freq'Unchecked_Access,
                             Aloop'Unchecked_Access);
      Check (Algeterror);
      Albufferdata (Buffer (Next_Buffer), Format, Data, Size, Freq);
      -- Set static source properties
      Alsourcei (Source (Next_Source),
                 AL_BUFFER,
                 Alint (Buffer (Next_Buffer)));
      Alsourcei (Source (Next_Source), AL_LOOPING, Boolean'Pos (Repeat));
      Alsourcef (Source (Next_Source), AL_REFERENCE_DISTANCE, 10.0);
      Next_Buffer := Next_Buffer + 1;
      Next_Source := Next_Source + 1;
      return Handle (Next_Buffer - 1);
   end Load_File;

   function Play_File (Name : in String; Repeat : in Boolean) return Handle is
      Lh : Handle;
   begin
      Lh := Load_File (Name, Repeat);
      Play (Lh);
      Check (Algeterror);
      return Lh;
   end Play_File;

   procedure Set_Source_Position (Audio : in Handle; Pos : in Position) is
   begin
      Alsourcefv (Source (Audio), AL_POSITION, To_Dof (Pos'Address));
   end Set_Source_Position;

   procedure Set_Source_Velocity (Audio : in Handle; Pos : in Position) is
   begin
      Alsourcefv (Source (Audio), AL_VELOCITY, To_Dof (Pos'Address));
   end Set_Source_Velocity;

   procedure Set_Source_Gain (Audio : in Handle; Gain : in Float) is
   begin
      Alsourcef (Source (Audio), AL_GAIN, Alfloat(Gain));
   end Set_Source_Gain;

   procedure Play (Audio : in Handle) is
   begin
      Alsourceplay (Source (Audio));
   end Play;

   procedure Stop (Audio : in Handle) is
   begin
      Alsourcestop (Source (Audio));
   end Stop;

   procedure Pause (Audio : in Handle) is
   begin
      Alsourcepause (Source (Audio));
   end Pause;

   procedure Mute (Audio : in Handle) is
   begin
      Alsourcef (Source (Audio), AL_MAX_GAIN, Alfloat(0.0));
   end Mute;

   procedure Unmute (Audio : in Handle) is
   begin
      Alsourcef (Source (Audio), AL_MAX_GAIN, Alfloat(1.0));
   end Unmute;

end Hal.Audio3d;
