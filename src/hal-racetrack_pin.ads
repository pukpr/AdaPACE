with Hal.Sms_Lib.Racetrack;
with Hal.Bounded_Assembly;
with Pace;

use Hal.Bounded_Assembly;
use Hal.Sms_Lib.Racetrack;

-- This package differs from Hal.Racetrack in that it models
-- a track whose slots are connected by pins.  Functionally this
-- means that when it goes around the circles on the ends the arc
-- length does not equal the Slot_Distance, but instead the
-- increment ends after a 1/4 circle, or when the slot is facing
-- directly out.

-- This package makes the following assumptions about the way
-- the model is set up:
-- The diagram below shows the intial starting locations of the
-- slots as well as the way the axes are aligned.
-- Orientations are on the Y axis.
--
--
-- Top row has orientation of Pi/2
--
--    11 10  9  8  7  6  5  4  3  2  1      ^ +x direction
-- 12                                  24   |
--    13 14 15 16 17 18 19 20 21 22 23      |
--                                          --->    +z direction
-- Bottom row has orientation of -Pi/2

generic
   Num_Slots : Integer;
   Num_Intervals : Integer;
   Slot_Distance : Float;
   Track_Width : Float;
   Assembly_Prefix : Bounded_String;
   Slot_To_Slot_Time : Duration;
   Initial_Available_Slot : Integer := 1;
package Hal.Racetrack_Pin is

   pragma Elaborate_Body;

   function Select_Slot (Slot_Num : in Integer) return Integer;

   procedure Inc_Slot (Which_Way : Direction);

   procedure Configure_Track;

   procedure Abort_Selection;

end Hal.Racetrack_Pin;
