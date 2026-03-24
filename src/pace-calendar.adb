with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Gnat.Calendar;
with Interfaces.C;
with Unchecked_Conversion;

package body Pace.Calendar is

   Base_Time : Ada.Calendar.Time;
   Base_Time_Offset : Long_Integer;
   Base_Time_Set : Boolean := False;

   -- subtype Seconds is Interfaces.Unsigned_64;

   function UT (NTP_Mode : Boolean := True) return Seconds is
      Seconds_1900_1970 : constant := 2_208_988_800; -- Official

      procedure Time_T (T : access Interfaces.C.Unsigned_Long);
      pragma Import (C, Time_T, "time");

      T : aliased Interfaces.C.Unsigned_Long;
      use type Interfaces.C.Unsigned_Long;
   begin
      Time_T (T'Unchecked_Access);
      if NTP_Mode then
         return Interfaces.Unsigned_64 (T + Seconds_1900_1970);
      else
         return Interfaces.Unsigned_64 (T);
      end if;
   end UT;

   function Unix_Clock (Actual : Boolean := True;
                        NTP_Mode : Boolean := True) return Seconds is
      use type Seconds;
   begin
      if Actual then
         return UT;
      end if;
      if Base_Time_Set then
         if Base_Time_Offset > 0 then
            return UT + Seconds(Base_Time_Offset);
         else
            return UT - Seconds(-Base_Time_Offset);
         end if;
      else
         return UT;
      end if;
   end Unix_Clock;

   function Clock return Ada.Calendar.Time is
      use type Ada.Calendar.Time;
      Sim_Time : Duration := Pace.Now;
   begin
      if Base_Time_Set then
         return Base_Time + Sim_Time;
      else
         return Ada.Calendar.Clock;
      end if;
   end Clock;
   
   procedure Set_Base_Time (Start : in Ada.Calendar.Time) is
      T : Ada.Calendar.Time;
      use type Ada.Calendar.Time;
      Since_1900_Set : Duration;
      Since_1900_Now : Duration;
   begin
      T := Ada.Calendar.Time_Of ( 
           Year       => 1901,
           Month      => 1,
           Day        => 1,
           Seconds    => 0.0);
      Since_1900_Set := Start - T;
      Since_1900_Now := Ada.Calendar.Clock - T;
      Base_Time := Start;
      Base_Time_Set := True;
      Base_Time_Offset := Long_Integer (Since_1900_Set - Since_1900_Now);
   end Set_Base_Time;


   type Get is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get);
   procedure Inout (Obj : in out Get) is
      Day, Hour, Minute, Second, Month, Year : Integer; 
      SS : Duration;            
      use Pace.Server.Xml;
   begin
      Gnat.Calendar.Split (Date       => Clock,
                           Year       => Year,
                           Month      => Month,
                           Day        => Day,
                           Hour       => Hour,
                           Minute     => Minute,
                           Second     => Second,
                           Sub_Second => SS);
      Put_Content;
      Pace.Server.Put_Data (Item("cal", Item ("year",Year) &
        Item ("month",Month) & Item ("day",Day) & Item ("hour", Hour) &
        Item ("minute",Minute) & Item ("second", Second)));
   end Inout;

   type Set is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Set);
   procedure Inout (Obj : in out Set) is
      T : Ada.Calendar.Time;
      use type Ada.Calendar.Time;
      Elapsed : Duration := Pace.Now;
   begin
      T := Gnat.Calendar.Time_Of ( 
           Year       => Integer'Value(Pace.Server.Keys.Value ("year", "2000")),
           Month      => Integer'Value(Pace.Server.Keys.Value ("month", "1")),
           Day        => Integer'Value(Pace.Server.Keys.Value ("day", "0")),
           Hour       => Integer'Value(Pace.Server.Keys.Value ("hour", "0")),
           Minute     => Integer'Value(Pace.Server.Keys.Value ("minute", "0")),
           Second     => Integer'Value(Pace.Server.Keys.Value ("second", "0")));
      T := T - Elapsed;
      Set_Base_Time (T);
      Pace.Server.Put_Data ("Set calendar completed");
   end Inout;

   use Pace.Server.Dispatch;
begin
   Save_Action (Set'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (Get'(Pace.Msg with Set => Pace.Server.Dispatch.Default));

end Pace.Calendar;
