with Ada.Calendar;
with Gnat.Calendar;

package Pace.Config is
   ------------------------------------------------------
   -- This package is used to access the main kBase and to access files
   ------------------------------------------------------
   pragma Elaborate_Body;

   Not_Found : exception;  -- If cannot match on the following

   --
   -- When Matching Identifier is an atom string, "name(ID, X)."

   function Get_Integer (Name : in String; -- Functor name
                         Id : in String) return Integer;

   function Get_String (Name : in String; -- Functor name
                        Id : in String) return String;

   procedure Load (File_Path : in String);

   --
   -- Returns lower case CSV (Comma Separated Value) of Ada.Tag external name
   function Parse (Tag_Name : in String) return String;

   -- searches all the paths in the $PACE environment variable for File_Name
   -- returns a "" if the file can't be found... if file_name
   -- includes a directory path then will chop it down to just the file
   function Find_File (File_Name : String) return String;

   -- returns an integer to be used as the subnode unique id.. guaranteed to be unique within
   -- the current PACE_NODE
   function Next_Subnode return Integer;



   -- SIMULATION_START defaults to be the actual time at which the simulation starts
   -- if the environment variable TEST_TIME is set to 1, then SIMULATION_START will
   -- be grabbed from a hard-coded value in the kbase

   -- Given Year, Month, Day, and Seconds, return the time as a number of seconds from
   -- the SIMULATION_START time
   function To_Sim_Time (Year : Ada.Calendar.Year_Number;
                         Month : Ada.Calendar.Month_Number;
                         Day : Ada.Calendar.Day_Number;
                         Seconds : Ada.Calendar.Day_Duration) return Duration;

   -- Given the number of seconds from SIMULATION_START, return time in the form
   -- of Year, Month, Day, and Seconds
   procedure To_Calendar_Time (Sim_Time : Duration;
                               Year : out Ada.Calendar.Year_Number;
                               Month : out Ada.Calendar.Month_Number;
                               Day : out Ada.Calendar.Day_Number;
                               Seconds : out Ada.Calendar.Day_Duration);

   function Day_Of_Week (Sim_Time : Duration) return Gnat.Calendar.Day_Name;

end Pace.Config;
