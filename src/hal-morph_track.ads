with Hal.Bounded_Assembly;
with Hal.Sms_Lib.Morph;

use Hal.Bounded_Assembly;

-- Represents a morph track... or a bendy straw type action.

generic
   Num_Pins : Integer;
   Intervals_Per_Degree : Integer;
   Lowest_Angle : Float;  -- in degrees
   Highest_Angle : Float; -- in degrees
   Assembly_Prefix : Bounded_String;
   Time_Between_One_Degree : Duration;
   Pin_Positions : Hal.Sms_Lib.Morph.Pin_Pos_Array;
   -- Pin_Positions never changes.. should find a better way .. shouldn't have
   -- to send this across socket each time.. but keeping it on plugin side
   -- loses generality.. solution?
package Hal.Morph_Track is

   pragma Elaborate_Body;

   procedure Do_Morph (Starting_Angle, Ending_Angle : Float);

end Hal.Morph_Track;
