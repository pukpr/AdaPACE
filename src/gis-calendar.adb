with Gnat.Calendar;

package body Gis.Calendar is

   procedure UTC_TO_GPS (UTC_Time : in Ada.Calendar.Time;
                         Seconds_in_Week : out Float) is
      Day : Gnat.Calendar.Day_Name;
      Sec : Ada.Calendar.Day_Duration;
      Days : Integer;
   begin
      Day := Gnat.Calendar.Day_Of_Week (UTC_Time);
      Days := Gnat.Calendar.Day_Name'Pos (Day);
      Sec := Ada.Calendar.Seconds(UTC_Time);
      Seconds_In_Week := Float(Days)*86400.0 + Float(Sec);
   end;

   -- $Id: gis-calendar.adb,v 1.1 2004/09/14 21:35:12 pukitepa Exp $
   
end Gis.Calendar;
