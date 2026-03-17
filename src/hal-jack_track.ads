with Hal.Key_Frame;

generic
   Name : in String;
   Radius : in Float;
   Length : in Float;
   Height : in Float;
   Offset : in Float;
   Width : in Float;
   Up_Velocity : in Float;
   Down_Velocity : in Float;
   Delta_T : in Float;
   Wheel : in Float;
   Base : in Float;
--   Bend : in Float;
   Shift : in Float;
   Crook : in Float;
   Short : in Float;
   Start_Pos : Hal.Position;
   Start_Ori : Hal.Orientation;
   with function Elevation (Wait : in Boolean := False) return Float;
   with procedure Callback_Check (Pos : Hal.Position);
   Back_Track : in Hal.Key_Frame.Points;
package Hal.Jack_Track is
   pragma Elaborate_Body;

   procedure Up (Dest_Stage : in Natural := Natural'Last;
                 Step : in Boolean := False);
   procedure Down (Dest_Stage : in Natural := 0;
                   Step : in Boolean := False);

   function Get_Current_Stage return Natural;

   function Get_Current_Orientation return Float;

-- $id: hal-jack_track.ads,v 1.6 12/18/2003 21:57:28 pukitepa Exp $
end Hal.Jack_Track;
