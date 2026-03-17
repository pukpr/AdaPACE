-- Manipulating and observing the environment during runtime
with Gnat.Os_Lib;

package Pace.Log.System is

   pragma Elaborate_Body;

   function Make_List (Opts : String; -- space-separated options
                       List : GNAT.Os_Lib.String_List := (1..0 => null)) 
                           return GNAT.Os_Lib.String_List;

   procedure Pause_Resume (Force_Resume : Boolean := False);
   function Is_Paused return Boolean;

end Pace.Log.System;
