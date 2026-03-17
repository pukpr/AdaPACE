with Hal.Sms_Lib.Racetrack;
with Hal.Bounded_Assembly;
with Pace;

use Hal.Bounded_Assembly;
use Hal.Sms_Lib.Racetrack;

-- This package makes the following assumptions about the way
-- the model is set up:
-- The diagram below shows the intial starting locations of the
-- slots as well as the way the axes are aligned.
-- Orientations are on the Y axis.
--
--
-- Top row has orientation of Pi/2
--
-- 12 11 10  9  8  7  6  5  4  3  2  1     ^ +x direction
--                                         |
-- 13 14 15 16 17 18 19 20 21 22 23 24     |
--                                         --->    +z direction
-- Bottom row has orientation of -Pi/2

generic
   Num_Slots : Integer;
   Num_Intervals : Integer;
   Slot_Distance : Float;
   Track_Width : Float;
   Assembly_Prefix : Bounded_String;
   Slot_To_Slot_Time : Duration;
   Initial_Available_Slot : Integer := 1;
package Hal.Racetrack is

   pragma Elaborate_Body;

   function Select_Slot (Slot_Num : in Integer) return Integer;

   procedure Inc_Slot (Which_Way : Direction);

   procedure Configure_Track;

   procedure Abort_Selection;

end Hal.Racetrack;
