with Ada.Calendar;
with Ada.Characters.Handling;
with Ada.Float_Text_Io;
with Ada.Integer_Text_Io;
with Ada.Io_Exceptions;
with Ada.Streams.Stream_Io;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded;
with Pace.Config;
with Text_Io;

package body Ual.Utilities is

   procedure Dur_To_Time (D : in Duration;
                          Hours : out Integer;
                          Minutes : out Integer;
                          Seconds : out Integer;
                          Clock_Time : Boolean := False) is
      Temp : Float := Float (D);
      use Ada.Calendar;
      Year : Year_Number;
      Month : Month_Number;
      Day : Day_Number;
      Seconds_From_Start_Of_Day : Day_Duration;
   begin
      if Clock_Time then
         Pace.Config.To_Calendar_Time (D, Year, Month, Day, Seconds_From_Start_Of_Day);
         Temp := Float (Seconds_From_Start_Of_Day);
      end if;
      Hours := Integer (Float'Floor (Temp)) / 3600;
      Temp := Temp - Float (Hours * 3600);
      Minutes := Integer (Float'Floor (Temp)) / 60;
      Seconds := Integer (Temp - Float (Minutes * 60));
   end Dur_To_Time;

   function Pad (Tag_Name : in String) return String is
      use Ada.Strings.Fixed, Ada.Strings.Maps, Ada.Characters.Handling;
   begin
      return Translate (To_Lower (Tag_Name), To_Mapping (" ", "0"));
   end Pad;

   procedure Dur_To_Time (D : in Duration;
                          Hours : out String;
                          Minutes : out String;
                          Seconds : out String;
                          Clock_Time : Boolean := False) is
      H, M, S : Integer;

   begin
      Dur_To_Time (D, H, M, S, Clock_Time);
      Ada.Integer_Text_Io.Put (Hours, H);
      Ada.Integer_Text_Io.Put (Minutes, M);
      Ada.Integer_Text_Io.Put (Seconds, S);
      Hours := Pad (Hours);
      Minutes := Pad (Minutes);
      Seconds := Pad (Seconds);
   exception
      when E: Ada.Io_Exceptions.Layout_Error =>
         Hours := "99";
         Minutes := "99";
         Seconds := "99";
   end Dur_To_Time;

   procedure Dur_To_Date (D : in Duration; Year : out Integer; Month : out Integer; Day : out Integer) is
      Leftover_Seconds : Duration;
      Year_N : Ada.Calendar.Year_Number;
      Month_N : Ada.Calendar.Month_Number;
      Day_N : Ada.Calendar.Day_Number;
   begin
      Pace.Config.To_Calendar_Time(D, Year_N, Month_N, Day_N, Leftover_Seconds);
      Year := Integer(Year_N);
      Month := Integer(Month_N);
      Day := Integer(Day_N);
   end Dur_To_Date;

   procedure Dur_To_Date (D : in Duration; Year : out String; Month : out String; Day : out String) is
      Year_N : Integer;
      Month_N : Integer;
      Day_N : Integer;
   begin
      Dur_To_Date(D, Year_N, Month_N, Day_N);
      Ada.Integer_Text_Io.Put(Year, Year_N);
      Ada.Integer_Text_Io.Put(Month, Month_N);
      Ada.Integer_Text_Io.Put(Day, Day_N);
      Year := Pad(Year);
      Month := Pad(Month);
      Day := Pad(Day);
   exception
      when E: Ada.Io_Exceptions.Layout_Error =>
         Year := "9999";
         Month := "99";
         Day := "99";
   end Dur_To_Date;

   function Dur_To_Time (D : in Duration;
                         Clock_Time : Boolean := False) return String is
      Hours, Minutes, Seconds : String (1 .. 2);
   begin
      Dur_To_Time (D, Hours, Minutes, Seconds, Clock_Time);
      return Hours & ":" & Minutes & ":" & Seconds;
   end Dur_To_Time;

   function Dur_To_Date (D : in Duration) return String is
      Year : String (1 .. 4);
      Month, Day : String (1 .. 2);
   begin
      Dur_To_Date(D, Year, Month, Day);
      return Year & "-" & Month & "-" & Day;
   end Dur_To_Date;

   function Timestamp (D : in Duration; Clock_Time : Boolean := False) return String is
      Year : String (1 .. 4);
      Month, Day, Hours, Minutes, Seconds : String (1 .. 2);
   begin
      Dur_To_Date (D, Year, Month, Day);
      Dur_To_Time (D, Hours, Minutes, Seconds, Clock_Time);
      return Year & "-" & Month & "-" & Day & " " & Hours & ":" & Minutes & ":" & Seconds;
   end Timestamp;

   function File_To_String (File : String) return String is
      package Io renames Ada.Streams.Stream_Io;
      Fd : Io.File_Type;
      Length : Io.Count;
   begin
      Io.Open (Fd, Io.In_File, File);
      Length := Io.Size (Fd);
      declare
         Text : String (1 .. Integer (Length));
         S : Io.Stream_Access := Io.Stream (Fd);
      begin
         String'Read (S, Text);
         Io.Close (Fd);
         return Text;
      end;
   exception
      when others =>
         Text_Io.Put_Line ("ERROR: Reading file : " & File);
         if Io.Is_Open (Fd) then
            Io.Close (Fd);
         end if;
         return "";
   end File_To_String;

   function Get_Month_Name (Month_Num : Ada.Calendar.Month_Number) return String is
   begin
      if Month_Num = 1 then
         return "January";
      elsif Month_Num = 2 then
         return "February";
      elsif Month_Num = 3 then
         return "March";
      elsif Month_Num = 4 then
         return "April";
      elsif Month_Num = 5 then
         return "May";
      elsif Month_Num = 6 then
         return "June";
      elsif Month_Num = 7 then
         return "July";
      elsif Month_Num = 8 then
         return "August";
      elsif Month_Num = 9 then
         return "September";
      elsif Month_Num = 10 then
         return "October";
      elsif Month_Num = 11 then
         return "November";
      else
         return "December";
      end if;
   end Get_Month_Name;

   function Float_Equals (X, Y : Float; Tolerance : Float := 0.001) return Boolean is
   begin
      if abs (X - Y) < Tolerance then
         return True;
      else
         return False;
      end if;
   end Float_Equals;

   type Character_Mapping_Function is access function (From : in Character) return Character;

   function Uppercase_Underscore (C : in Character) return Character is
      use Ada.Characters.Handling;
   begin
      if Is_Lower(C) then
         return To_Upper(C);
      elsif(C = ' ') then
         return '_';
      else
         return C;
      end if;
   end Uppercase_Underscore;

   function Lowercase_Underscore (C : in Character) return Character is
      use Ada.Characters.Handling;
   begin
      if Is_Upper (C) then
         return To_Lower(C);
      elsif (C = ' ') then
         return '_';
      else
         return C;
      end if;
   end Lowercase_Underscore;

   function UU(S : in String) return String is
   begin
      return Ada.Strings.Fixed.Translate(S, Uppercase_Underscore'Access);
   end UU;

   function LL(S : in String) return String is
   begin
      return Ada.Strings.Fixed.Translate(S, Lowercase_Underscore'Access);
   end LL;

end Ual.Utilities;
