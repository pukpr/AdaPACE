package Hal.Audio3d is

   pragma Elaborate_Body;

   type Handle is private;

   Audio_Error : exception;
   Invalid_Device : exception;

   type To_Up is
      record
         To, Up : Position;
      end record;
   pragma Convention (C, To_Up);

   procedure Init;
   procedure Listener_Position (Pos : in Position; Rot : in To_Up);
   function Load_File (Name : in String; Repeat : in Boolean) return Handle;
   function Play_File (Name : in String; Repeat : in Boolean) return Handle;
   procedure Set_Source_Position (Audio : in Handle; Pos : in Position);
   procedure Set_Source_Velocity (Audio : in Handle; Pos : in Position);
   procedure Set_Source_Gain (Audio : in Handle; Gain : in Float);
   procedure Play (Audio : in Handle);
   procedure Stop (Audio : in Handle);
   procedure Pause (Audio : in Handle);
   procedure Mute (Audio : in Handle);
   procedure Unmute (Audio : in Handle);

private
   type Handle is new Natural;
end;
