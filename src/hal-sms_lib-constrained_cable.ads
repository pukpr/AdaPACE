generic
   Link_Name : in String;  -- Appends a "-N", where N=1..Links
   Links : in Integer;
   Link_Length : in Float;
   Link_Max_Angle : in Float;
package Hal.Sms_Lib.Constrained_Cable is

   -- X into Y about Z
   function Render (X, Y : in Float) return Hal.Position;

end Hal.Sms_Lib.Constrained_Cable;
