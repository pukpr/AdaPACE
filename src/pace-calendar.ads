with Ada.Calendar;
with Interfaces;

package Pace.Calendar is
   -----------------------------------------
   -- CALENDAR -- Morphed Calendar 
   -----------------------------------------

   pragma Elaborate_Body;
   
   function Clock return Ada.Calendar.Time;
   
   procedure Set_Base_Time (Start : in Ada.Calendar.Time);

   subtype Seconds is Interfaces.Unsigned_64;

   -- UNIX => Seconds From 1970
   -- NTP  => Seconds since 1900
   function Unix_Clock (Actual : Boolean := True;
                        NTP_Mode : Boolean := True) return Seconds;

   --  $Id: pace-calendar.ads,v 1.1 2006/02/03 22:18:42 pukitepa Exp $
end Pace.Calendar;
