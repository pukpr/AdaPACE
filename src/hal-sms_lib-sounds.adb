with Pace.Log;
with Pace.Config;
with Pace.Socket;
with Pace.Server.Dispatch;
with Hal.Audio3d.Commands;
with Hal.Rotations;
with Str;
with Ada.Numerics.Elementary_Functions;
with Hal.Sms;

package body Hal.Sms_Lib.Sounds is

   function Id is new Pace.Log.Unit_Id;
   Check_Time : constant Duration := Duration (Pace.Getenv("SOUND_CHECK", 0.15));
   Ramp_Mode : constant Boolean := Pace.Getenv("SOUND_RAMP", "0") = "1";

   task Agent is pragma Task_Name (Pace.Log.Name);
      pragma Storage_Size (1000000);
      entry Activate;
   end Agent;

   Intialized : Boolean := False;
   procedure Initialize is
      Msg : Hal.Audio3d.Commands.Init_Cmd;
   begin
      if not Intialized then
         Pace.Socket.Send (Msg);
         Intialized := True;
      end if;
   end;

   PI : constant := Ada.Numerics.Pi;

   procedure Set_Listener (X,Y,Z : in Float := 0.0;
                          Phi : in Float := 0.0) is
      --      Up, To    : Position;
      use  Ada.Numerics.Elementary_Functions;
      PlayerPos : Position          := (X, Y, Z);
      Orient    : Hal.Audio3d.To_Up :=
        (To => (Sin (Pi+Phi), 0.0, Cos (Pi+Phi)),
         Up => (0.0, 1.0, 0.0));
      Listener  : Hal.Audio3d.Commands.Listener_Position_Cmd;
   begin
      -- Have to match this To/Up to Division's To/Up
--      Hal.Rotations.To_Axis (0.0, 0.0, 0.0, To, Up);
--      Pace.Log.Put_Line (To.X'Img & To.Y'Img & To.Z'Img);
--      Pace.Log.Put_Line (Up.X'Img & Up.Y'Img & Up.Z'Img);
      Listener.Pos := PlayerPos;
      Listener.Rot := Orient;
      Pace.Socket.Send (Listener);
   end Set_Listener;

   function Load_File (File_Name : in String) return Hal.Audio3d.Handle is
      Load : Hal.Audio3d.Commands.Load_File_Cmd;
      Name : constant String := Pace.Config.Find_File ("/audio/" & File_Name);
      -- use Hal.Audio3d.Commands;
   begin
      Pace.Log.Put_Line ("Loading audio " & Name);
      Load.Name   := Str.S2U (Name);
      Load.Repeat := True;
      Pace.Socket.Send_Inout (Load);
      return Load.Audio;
   end Load_File;

   Running : Boolean := True; -- Disables new sound but will enable old sound to turn off

   procedure Start_Play (Audio : in Hal.Audio3d.Handle) is
      Play : Hal.Audio3d.Commands.Play_Cmd;
   begin
      Play.Audio := Audio;
      if Running then
         Pace.Socket.Send (Play);
      end if;
   end Start_Play;

   procedure Stop_Play (Audio : in Hal.Audio3d.Handle) is
      Stop : Hal.Audio3d.Commands.Stop_Cmd;
   begin
      Stop.Audio := Audio;
      Pace.Socket.Send (Stop);
   end Stop_Play;

   procedure Pause_Play (Audio : in Hal.Audio3d.Handle) is
      Pause : Hal.Audio3d.Commands.Pause_Cmd;
   begin
      Pause.Audio := Audio;
      Pace.Socket.Send (Pause);
   end Pause_Play;

   procedure Set_Pos (Audio : in Hal.Audio3d.Handle; Pos : in Position) is
      Source : Hal.Audio3d.Commands.Set_Source_Position_Cmd;
   begin
      Source.Audio := Audio;
      Source.Pos   := Pos;
      Pace.Socket.Send (Source);
   end Set_Pos;

   type Sound is record
      Name     : Str.Bstr.Bounded_String;
      Pos      : Hal.Position;
      File     : Str.Bstr.Bounded_String;
      Audio    : Hal.Audio3d.Handle;
      Absolute : Boolean;
      Playing  : Boolean := False;
      At_Pos   : Hal.Position;
      At_Rot   : Hal.Orientation;
      Ramping  : Boolean := False;
      Gain     : Float := 1.0;
   end record;
   Sources    : array (Natural range 0 .. 100) of Sound;
   End_Source : Natural := 0;

--   procedure Set_Gain (Audio : in Hal.Audio3d.Handle; Gain : in Float) is
   procedure Set_Gain (Source : in Natural; Gain : in Float) is
      Play : Hal.Audio3d.Commands.Set_Gain_Cmd;
   begin
      Play.Audio := Sources (Source).Audio;
      Play.Gain := Sources (Source).Gain * Gain;
      Pace.Socket.Send (Play);
   end Set_Gain;


   function Get_Field (Field : in String; ID : in Integer) return String is
   begin
      return Pace.Config.Get_String (Field, Integer'Image (ID));
   end Get_Field;

   function Get_Field (Field : in String; ID : in Integer) return Float is
   begin
      return Float'Value (Get_Field (Field, ID));
   end Get_Field;

   function Set_Sound (ID : in Integer) return Boolean is
      use Str;
   begin
      Pace.Log.Put_Line ("Setting " & ID'Img);
      Sources (ID).Name     := S2B (Get_Field ("sound_assembly", ID));
      Sources (ID).Pos.X    := Get_Field ("sound_x", ID);
      Sources (ID).Pos.Y    := Get_Field ("sound_y", ID);
      Sources (ID).Pos.Z    := Get_Field ("sound_z", ID);
      Sources (ID).File     := S2B (Get_Field ("sound_file", ID));
      Sources (ID).Absolute := Get_Field ("sound_position", ID) = "abs";
      Sources (ID).Gain     := Get_Field ("sound_gain", ID);
      End_Source            := End_Source + 1;
      return True;
   exception
      when Pace.Config.Not_Found =>
         return False;
   end Set_Sound;

   procedure Load_File (ID : in Integer) is
      use Str;
   begin
      Sources (ID).Audio := Load_File (B2S (Sources (ID).File));
   end Load_File;

   procedure Check_Sound (ID : in Integer; Pos : in Position;
                         Moved : in Boolean) is
      use Str;
      Assembly_Pos : Position;
   begin
      --Pace.Log.Put_Line ("checking sound for " & ID'Img);
      if Sources (ID).Playing then
         -- Check to see if source has stopped moving
         if Moved then
            null;  -- continue playing
            if Ramp_Mode and then Sources (ID).Ramping then
               Pace.Log.Put_Line (">>> starting " & ID'Img);
               Set_Gain (ID, 1.0);
               Sources (ID).Ramping := False;
            end if;
         else
            if Ramp_Mode then
               Pace.Log.Put_Line ("<<   stopping " & ID'Img);
               Set_Gain (ID, 0.5);
               Sources (ID).Ramping := True;
            else
               Pace.Log.Put_Line ("<<< stopping " & ID'Img);
               Stop_Play (Sources (ID).Audio); -- comment if ramping
            end if;
            Sources (ID).Playing := False;
         end if;
      else
         -- Check to see if source has started moving
         if Moved then
            if Ramp_Mode then
               Pace.Log.Put_Line (">>  starting " & ID'Img);
               Set_Gain (ID, 0.5);
               Sources (ID).Ramping := True;
            else
               Pace.Log.Put_Line (">>> starting " & ID'Img);
            end if;
            Start_Play (Sources (ID).Audio);
            Sources (ID).Playing := True;
         else
            null; -- already stopped
            if Ramp_Mode then
               if Sources (ID).Ramping then
                  Pace.Log.Put_Line ("<   stopping " & ID'Img);
                  Set_Gain (ID, 0.2);
                  Sources (ID).Ramping := False;
               else
                  if Running then
                     Set_Gain (ID, 0.01);
                  else
                     Stop_Play (Sources (ID).Audio);
                  end if;
               end if;
            end if;
         end if;
      end if;
      if Sources (ID).absolute then
         -- Abs Coordinate location, unattached to main vehicle
         Assembly_Pos := Pos;
      else
         -- relative to center of vehicle
         Assembly_Pos := Sources (ID).Pos + Pos;  --- Doesn't make much of a difference to do +Pos?
      end if;
      Set_Pos (Sources (ID).Audio, Assembly_Pos);
   end Check_Sound;

   function Has_Moved (ID : in Integer;
                      Pos : in Position;
                      Rot : in Orientation) return Boolean is
   begin
      if Pos = Sources (ID).At_Pos and
        Rot = Sources (ID).At_Rot then
         return False;
      else
         Sources (ID).At_Pos := Pos;
         Sources (ID).At_Rot := Rot;
         return True;
      end if;
   end Has_Moved;


   task body Agent is
      use Str;
   begin
      Pace.Log.Agent_Id (Id);
      accept Activate;
      Initialize;
      Set_Listener;
      for Id in  Natural'Range loop
         exit when not Set_Sound (Id);
         Load_File (Id);
      end loop;
      loop
         for Id in  0 .. End_Source - 1 loop
            declare
               Name       : constant String := B2S (Sources (Id).Name);
               Pos, Scale : Position;
               Rot        : Orientation;
               Active     : Boolean;
               Moved      : Boolean;
            begin
               -- if Is_Absolute means that Sources (Id).Absolute = true
               Hal.Sms.Get_Coordinate
                 (Assembly    => Name,
                  Pos         => Pos,
                  Ori         => Rot,
                  Active      => Active,
                  Is_Absolute => False,
                  Scale       => Scale,
                  Entity      => "nlosc_ammo_handling");
               Moved := Has_Moved (Id, Pos, Rot);
               -- Moved := True;
               Check_Sound(Id, Pos, Moved); -- the actual call
               -- Check_Sound (Id, Sources (Id).Pos, Moved);
            end;
         end loop;
         Pace.Log.Wait (Check_Time);

      end loop;

   exception
      when E : others =>
         Pace.Log.Ex (E);
   end Agent;

   use Pace.Server;

   type Start is new Dispatch.Action with null record;
   procedure Inout (Obj : in out Start);

   procedure Inout (Obj : in out Start) is
   begin
      Running := True;
      Agent.Activate;
      Pace.Server.Put_Data ("started SMS sound task");
   end Inout;

   type Stop is new Dispatch.Action with null record;
   procedure Inout (Obj : in out Stop);

   procedure Inout (Obj : in out Stop) is
   begin
      Running := False;
      Pace.Server.Put_Data ("inactivated SMS sound task");
   end Inout;

   type Listen is new Dispatch.Action with null record;
   procedure Inout (Obj : in out Listen);

   procedure Inout (Obj : in out Listen) is
      X : constant Float := Float'Value (Pace.Server.Value ("x"));
      Y : constant Float := Float'Value (Pace.Server.Value ("y"));
      Z : constant Float := Float'Value (Pace.Server.Value ("z"));
      P : constant Float := Float'Value (Pace.Server.Value ("p"));

      Pos : Hal.Position;
      Rot : Hal.Orientation;
      Phi : Float;
      --use Pace.Server;
   begin
      Pace.Server.Put_Data ("x:" & X'Img & " y:" & Y'Img &
                           " z:" & Z'Img & " p:" & P'Img );
      Pos := (X, Y, Z);
      Phi := Rads (P);
      Rot := (0.0, Phi, 0.0);
      Hal.Sms.Set("", Pos, Rot);
      Set_Listener (-Pos.X, -Pos.Y, -Pos.Z, Phi);
   end Inout;

begin
   Dispatch.Save_Action (Start'(Pace.Msg with Set => Dispatch.Default));
   Dispatch.Save_Action (Listen'(Pace.Msg with Set => Dispatch.Default));
   Dispatch.Save_Action (Stop'(Pace.Msg with Set => Dispatch.Default));
   -- $Id: hal-sms_lib-sounds.adb,v 1.2 2006/07/07 22:38:14 pukitepa Exp $
end Hal.Sms_Lib.Sounds;
