with Ada.Calendar;
with Pace.Xml;
with Pace.Strings;

package Ual.Utilities is
   --
   -- This package is meant for any common utility which may be needed
   -- by other code, but which shouldn't be classified under any specific
   -- package.  Transformation of data are good things to put here.
   --
   pragma Elaborate_Body;

   -- two modes:
   -- Clock_Time = false :  D is seconds
   -- Clock_Time = true :  D is seconds since start of simulation (sim_time) and we want
   -- the hours, minutes, and seconds of the current calendar day like the time on a clock
   procedure Dur_To_Time (D : in Duration;
                          Hours : out Integer;
                          Minutes : out Integer;
                          Seconds : out Integer;
                          Clock_Time : Boolean := False);

   -- Hours, Minutes, and Seconds will be Strings of length two.  If
   -- necessary they will be padded with 0's.
   -- two modes:
   -- Clock_Time = false :  D is seconds
   -- Clock_Time = true :  D is seconds since start of simulation (sim_time) and we want
   -- the hours, minutes, and seconds of the current calendar day like the time on a clock
   procedure Dur_To_Time (D : in Duration;
                          Hours : out String;
                          Minutes : out String;
                          Seconds : out String;
                          Clock_Time : Boolean := False);

   procedure Dur_To_Date (D : in Duration;
                          Year : out Integer;
                          Month : out Integer;
                          Day : out Integer);

   procedure Dur_To_Date (D : in Duration;
                          Year : out String;
                          Month : out String;
                          Day : out String);

   -- Same as above but returns a single string in the format 08:30:15
   -- two modes:
   -- Clock_Time = false :  D is seconds
   -- Clock_Time = true :  D is seconds since start of simulation (sim_time) and we want
   -- the hours, minutes, and seconds of the current calendar day like the time on a clock
   function Dur_To_Time (D : in Duration;
                         Clock_Time : Boolean := False) return String;

   function Dur_To_Date (D : in Duration) return String;

   function Timestamp (D : in Duration; Clock_Time : Boolean := False) return String;

   -- converts Float to a string in decimal format (instead of default
   -- exponential format) with 6 places beyond the decimal by default, or
   -- the user can specify how many decimal places
   function Float_Put
              (Val : in Float; Decimal_Places : in Integer := 6) return String
              renames Pace.Strings.Trim;

   -- Given a name of a file, returns the contents as a string
   function File_To_String (File : String) return String;

   function Get_Month_Name (Month_Num : Ada.Calendar.Month_Number) return String;

   -- useful to avoid floating precision problems when comparing two floats
   -- for equality
   function Float_Equals (X, Y : Float; Tolerance : Float := 0.001) return Boolean;

   -- convert to all uppercase and spaces to underscores
   function UU(S : in String) return String;
   -- convert to all lowercase and spaces to underscores
   function LL(S : in String) return String;

   function Search_Xml (Xml : in String; Key : in String; Default : in String := "") return String renames Pace.Xml.Search_Xml;
   subtype Strings is Pace.Xml.Strings;
   function Search_Xml (Xml : in String; Key : in String) return Strings renames Pace.Xml.Search_Xml;

end Ual.Utilities;
