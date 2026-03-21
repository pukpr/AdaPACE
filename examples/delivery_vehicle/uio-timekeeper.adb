with Pace.Log;
with Pace.Notify;
with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Ual.Utilities;
with Ada.Calendar;
with Pace.Strings; use Pace.Strings;

package body Uio.Timekeeper is
   use Pace.Server.Dispatch;

   function Id is new Pace.Log.Unit_Id;

   task Agent;

   type Clock_Notify is new Pace.Notify.Subscription with null record;

   task body Agent is
      Msg : Clock_Notify;
   begin
      Pace.Log.Agent_Id (Id);
      loop
         Pace.Log.Wait (60.0);
         Input (Msg);
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;


   function Create_Time_Xml (Hours, Minutes, Seconds : String) return String is
      use Pace.Server.Xml;
   begin
      return (Item ("current_time",
                    Item ("hours", Hours) & Item ("minutes", Minutes) &
                      Item ("seconds", Seconds) & Item ("clock", "Z")));
   end Create_Time_Xml;

   function Create_Actual_Time_Xml return String is
      use Ada.Calendar;
      T : Time := Clock;
      Year : Year_Number;
      Month : Month_Number;
      Day : Day_Number;
      Seconds_In_Day : Day_Duration;
      Hours : String (1 .. 2);
      Minutes : String (1 .. 2);
      Seconds : String (1 .. 2);
   begin
      Split (T, Year, Month, Day, Seconds_In_Day);
      Ual.Utilities.Dur_To_Time (Seconds_In_Day, Hours, Minutes, Seconds);
      return Create_Time_Xml (Hours, Minutes, Seconds);
   end Create_Actual_Time_Xml;

   Adjusted_Time : Duration := 0.0;
   function Create_Sim_Time_Xml return String is
      Current_Time : constant Duration := Pace.Now;
      A_Time : Duration;
      Hours, Minutes, Seconds : String (1 .. 2);
      use Pace.Server.Xml;
   begin
      -- Clock resetting occurs by setting Adjusted_Time to Now
      A_Time := Current_Time - Adjusted_Time;
      if A_Time < 0.0 then
         A_Time := 0.0;
      end if;
      Ual.Utilities.Dur_To_Time (A_Time, Hours, Minutes, Seconds);
      return Create_Time_Xml (Hours, Minutes, Seconds);
   end Create_Sim_Time_Xml;

   -- if set=actual then return actual time, otherwise return sim time
   procedure Inout (Obj : in out Get_Time) is
   begin
      Pace.Server.Xml.Put_Content
        (Default_Stylesheet => "eng/move/nav-time.xsl");
      if (+Obj.Set) = "actual" then
         Obj.Set := +Create_Actual_Time_Xml;
      else
         Obj.Set := +Create_Sim_Time_Xml;
      end if;
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

--    procedure Inout (Obj : in out Get_Time_Xml) is
--    begin
--       if Obj.Is_Sim_Time then
--          Obj.Time_Xml := +Create_Sim_Time_Xml;
--       else
--          Obj.Time_Xml := +Create_Actual_Time_Xml;
--       end if;
--       Pace.Log.Trace (Obj);
--    end Inout;

   type Reset_Wait is new Action with null record;
   procedure Inout (Obj : in out Reset_Wait);
   procedure Inout (Obj : in out Reset_Wait) is
      Msg_Clock_Notify : Clock_Notify;
   begin
      Msg_Clock_Notify.Ack := False;
      Input (Msg_Clock_Notify);
      Pace.Log.Trace (Obj);
   end Inout;

   type Wait_Time is new Action with null record;
   procedure Inout (Obj : in out Wait_Time);
   procedure Inout (Obj : in out Wait_Time) is
      Msg_Clock_Notify : Clock_Notify;
      Msg_Get_Time : Get_Time;
   begin
      -- (Flush the current data) and then wait
      -- Msg_Clock_Notify.Flush := True;
      Inout (Msg_Clock_Notify);

      -- Get the time
      Inout (Msg_Get_Time);
      Pace.Log.Trace (Obj);
   end Inout;


   Get_Month_Abbrev : constant array (Ada.Calendar.Month_Number)
                                 of String (1 .. 3) :=
     ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");

   function Create_Day_Xml return String is
      use Pace.Server.Xml;
      use Ada.Calendar;

      function Add_Front_Zero (Day : Day_Number) return String is
      begin
         if Day < 10 then
            return "0" & Trim (Day_Number'Image (Day));
         else
            return Trim (Day_Number'Image (Day));
         end if;
      end Add_Front_Zero;

      T : Time := Clock;  -- this call gets the current time
      Year : Year_Number;
      Month : Month_Number;
      Day : Day_Number;
      Seconds_In_Day : Day_Duration;
   begin
      Split (T, Year, Month, Day, Seconds_In_Day);
      return (Item ("current_day",
                    Item ("year", Trim (Year_Number'Image (Year))) &
                      Item ("month", Trim
                                       (Month_Number'Image (Month))) &
                      Item ("month_abbrev", Get_Month_Abbrev (Month)) &
                      Item ("day", Add_Front_Zero (Day))));
   end Create_Day_Xml;

   procedure Inout (Obj : in out Get_Day) is
   begin
      Pace.Server.Xml.Put_Content
        (Default_Stylesheet => "eng/move/nav-time.xsl");
      Obj.Set := +Create_Day_Xml;
      Pace.Server.Put_Data (Create_Day_Xml);
      Pace.Log.Trace (Obj);
   end Inout;

--   procedure Output (Obj : out Get_Day_Xml) is
--   begin
--      Obj.Day_Xml := +Create_Day_Xml;
--      Pace.Log.Trace (Obj);
--   end Output;

   type Get_Date is new Action with null record;
   procedure Inout (Obj : in out Get_Date);
   procedure Inout (Obj : in out Get_Date) is
      Msg1 : Get_Day;
      Msg2 : Get_Time;
      use Pace.Server.Xml;
   begin
      -- assumes that anytime you want the current day you also
      -- want the actual time instead of the sim time
      Msg2.Set := +"actual";
      Put_Content (Default_Stylesheet => "eng/move/nav-time.xsl");
      Pace.Server.Put_Data (Begin_Doc ("current_date"));
      Inout (Msg1);
      Inout (Msg2);
      Pace.Server.Put_Data (End_Doc ("current_date"));
      Pace.Log.Trace (Obj);
   end Inout;


   procedure Input (Obj : in Reset_Time) is
   begin
      Adjusted_Time := Pace.Now;
      Pace.Log.Trace (Obj);
   end Input;

   type Get_Current_Time is new Action with null record;
   procedure Inout (Obj : in out Get_Current_Time);
   procedure Inout (Obj : in out Get_Current_Time) is
      use Pace.Server.Xml;
      Current_Time : constant Duration := Pace.Now;
      A_Time : Duration;
   begin
      A_Time := Current_Time - Adjusted_Time;
      if A_Time < 0.0 then
         A_Time := 0.0;
      end if;
      Pace.Server.Put_Data (Item ("current_time",
                                  Trim (Duration'Image (A_Time))));
      Pace.Log.Trace (Obj);
   end Inout;

begin
   Save_Action (Get_Current_Time'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_Time'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_Day'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_Date'(Pace.Msg with Set => Xml_Set));
   Save_Action (Reset_Wait'(Pace.Msg with Set => +"0.0"));
   Save_Action (Wait_Time'(Pace.Msg with Set => +"0.0"));

-- $Id: uio-timekeeper.adb,v 1.17 2003/08/04 19:29:01 ludwiglj Exp $ --
end Uio.Timekeeper;
