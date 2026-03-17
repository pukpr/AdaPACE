generic
   type Mode_Type is (<>);
   type Joystick_Range is range <>;

   with procedure Switch (ID : in Joystick_Range;
                          Mode : in Mode_Type);

package Uio.Joystick_Control is

   pragma Elaborate_Body;

   procedure Set_Joystick_Mode (Joy_Id : Joystick_Range; 
                                New_Mode : Mode_Type);

end Uio.Joystick_Control;
