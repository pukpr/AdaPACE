with Ada.Calendar;

package Gis.Calendar is

   procedure UTC_TO_GPS
     (UTC_Time        : in Ada.Calendar.Time;
      Seconds_in_Week : out Float);
   -- Week_Number also available

end Gis.Calendar;
