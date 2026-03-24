with Ada.Strings.Unbounded;
with Pace.Log;

package body Hal.Audio.Mixer is

   procedure Inout (Obj : in out Play_Mix) is
      Name : constant String := Ada.Strings.Unbounded.To_String (Obj.File);
   begin
      if Obj.Channel = Idle then
         Hal.Audio.Play (File_Name => Ada.Strings.Unbounded.To_String (Obj.File),
                         Surrogate => True);
         Obj.Channel := 0;
      else
         Obj.Channel := Idle;
      end if;
   exception
      when E : others =>
         Pace.Log.Ex (E, "audio mixer");
   end Inout;

   function Init (File : String; Volume : Integer := 100; Timed : Duration := 0.0) return Play_Mix is
      Obj : Play_Mix;
   begin
      return Obj;
   end Init;

   -- have this call the basic Say which is not-mixed
   procedure Say (Text : in String; Volume : Integer := 100) is
   begin
      Hal.Audio.Say (Text);
   end Say;

   procedure Shutdown is
   begin
      null;
   end;

end Hal.Audio.Mixer;
