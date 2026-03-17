with Pace.Log;
with Ada.Strings.Unbounded;

package Hal.Audio3d.Commands is

   pragma Elaborate_Body;

   type Init_Cmd is new Pace.Msg with null record;
   procedure Input (Obj : in Init_Cmd);

   type Listener_Position_Cmd is new Pace.Msg with
     record
        Pos : Position;
        Rot : To_Up;
     end record;
   procedure Input (Obj : in Listener_Position_Cmd);

   type Load_File_Cmd is new Pace.Msg with
     record
        Name :  Ada.Strings.Unbounded.Unbounded_String;
        Repeat : Boolean;
        Audio : Handle; -- out
     end record;
   procedure Inout (Obj : in out Load_File_Cmd);

   type Play_File_Cmd is new Pace.Msg with
     record
        Name :  Ada.Strings.Unbounded.Unbounded_String;
        Repeat : Boolean;
        Audio : Handle; -- out
     end record;
   procedure Inout (Obj : in out Play_File_Cmd);

   type Set_Source_Position_Cmd is new Pace.Msg with
     record
        Audio : Handle;
        Pos : Position;
     end record;
   procedure Input (Obj : in Set_Source_Position_Cmd);

   type Set_Source_Velocity_Cmd is new Pace.Msg with
     record
        Audio : Handle;
        Pos : Position;
     end record;
   procedure Input (Obj : in Set_Source_Velocity_Cmd);

   type Set_Gain_Cmd is new Pace.Msg with
     record
        Audio : Handle;
        Gain : Float;
     end record;
   procedure Input (Obj : in Set_Gain_Cmd);

   type Play_Cmd is new Pace.Msg with
     record
        Audio : Handle;
     end record;
   procedure Input (Obj : in Play_Cmd);

   type Stop_Cmd is new Pace.Msg with
     record
        Audio : Handle;
     end record;
   procedure Input (Obj : in Stop_Cmd);

   type Pause_Cmd is new Pace.Msg with
     record
        Audio : Handle;
     end record;
   procedure Input (Obj : in Pause_Cmd);

   -- $Id: hal-audio3d-commands.ads,v 1.3 2005/08/19 19:24:46 pukitepa Exp $
end;
