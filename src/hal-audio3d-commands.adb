package body Hal.Audio3d.Commands is

   procedure Input (Obj : in Init_Cmd) is
   begin
      Hal.Audio3d.Init;
   end;

   procedure Input (Obj : in Listener_Position_Cmd) is
   begin
      Hal.Audio3d.Listener_Position (Obj.Pos, Obj.Rot);
   end;

   procedure Inout (Obj : in out Load_File_Cmd) is
   begin
      Obj.Audio := Hal.Audio3d.Load_File (
                    Ada.Strings.Unbounded.To_String (Obj.Name), 
                    Obj.Repeat);
   exception
      when E: Audio_Error =>
         Pace.Log.Ex (E);
         Obj.Audio := Handle'Last;
   end;

   procedure Inout (Obj : in out Play_File_Cmd) is
   begin
      Obj.Audio := Hal.Audio3d.Play_File (
                    Ada.Strings.Unbounded.To_String (Obj.Name), 
                    Obj.Repeat);
   exception
      when E: Audio_Error =>
         Pace.Log.Ex (E);
         Obj.Audio := Handle'Last;
   end;

   procedure Input (Obj : in Set_Source_Position_Cmd) is
   begin
      Hal.Audio3d.Set_Source_Position (Obj.Audio, Obj.Pos);
   exception
      when E : others =>
         Pace.Log.Ex (E, Pace.Tag (Obj));
   end;

   procedure Input (Obj : in Set_Source_Velocity_Cmd) is
   begin
      Hal.Audio3d.Set_Source_Velocity (Obj.Audio, Obj.Pos);
   exception
      when E : others =>
         Pace.Log.Ex (E, Pace.Tag (Obj));
   end;

   procedure Input (Obj : in Set_Gain_Cmd) is
   begin
      Hal.Audio3d.Set_Source_Gain (Obj.Audio, Obj.Gain);
   exception
      when E : others =>
         Pace.Log.Ex (E, Pace.Tag (Obj));
   end;

   procedure Input (Obj : in Play_Cmd) is
   begin
      Hal.Audio3d.Play (Obj.Audio);
   exception
      when E : others =>
         Pace.Log.Ex (E, Pace.Tag (Obj));
   end;

   procedure Input (Obj : in Stop_Cmd) is
   begin
      Hal.Audio3d.Stop (Obj.Audio);
   exception
      when E : others =>
         Pace.Log.Ex (E, Pace.Tag (Obj));
   end;

   procedure Input (Obj : in Pause_Cmd) is
   begin
      Hal.Audio3d.Pause (Obj.Audio);
   exception
      when E : others =>
         Pace.Log.Ex (E, Pace.Tag (Obj));
   end;

   -- $Id: hal-audio3d-commands.adb,v 1.3 2005/08/19 19:24:46 pukitepa Exp $
end;
