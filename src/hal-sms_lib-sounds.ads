with Hal.Audio3d;

package Hal.Sms_Lib.Sounds is

   pragma Elaborate_Body;

   procedure Initialize;

   procedure Set_Listener (X,Y,Z : in Float := 0.0;
                           Phi : in Float := 0.0); -- Rads

   function Load_File (File_Name : in String)
                          return Hal.Audio3D.Handle ;

   procedure Start_Play (Audio : in Hal.Audio3D.Handle);
   procedure Stop_Play (Audio : in Hal.Audio3d.Handle);

   procedure Set_Pos (Audio : in Hal.Audio3D.Handle;
                      Pos : in Position);

   -- $Id: hal-sms_lib-sounds.ads,v 1.1 2006/05/25 19:01:19 ludwiglj Exp $
end Hal.Sms_Lib.Sounds;
