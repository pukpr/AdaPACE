with Pace;

package Hal.Joystick is

   ------------------------------------------------
   -- JOYSTICK -- Interface to generic joystick
   ------------------------------------------------

   Num_Axes : constant := 8;
   Num_Buttons : constant := 26;

   type Joystick_Axes is array (0 .. (Num_Axes - 1)) of Float;
   type Joystick_Buttons is array (0 .. (Num_Buttons - 1)) of Boolean;

   type Joy_Data is
      record
         Axes : Joystick_Axes := (others => 0.0);
         Buttons : Joystick_Buttons := (others => False);
      end record;

end Hal.Joystick;
