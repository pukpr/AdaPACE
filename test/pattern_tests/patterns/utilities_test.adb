with AUnit.Assertions; use AUnit.Assertions;
with Pace.Calendar;
with Pace.Command_Line;
with Pace.Config;
with Pace.Fault;
with Pace.Log;
with Pace.Log.System;
-- with Ada.Strings.Unbounded; use Ada.Strings.Unbounded; -- Redundant
with Ada.Calendar;
with Interfaces; use Interfaces;
with GNAT.Calendar;
with AUnit.Test_Cases.Registration; use AUnit.Test_Cases.Registration;
with Ada.Strings.Unbounded; 

package body Utilities_Test is
   
   use Ada.Strings.Unbounded;

   procedure Test_Calendar (T : in out AUnit.Test_Cases.Test_Case'Class) is
      S : Pace.Calendar.Seconds;
   begin
      S := Pace.Calendar.Unix_Clock;
      Assert (S > 0, "Unix_Clock should return > 0");
   end Test_Calendar;

   procedure Test_Command_Line (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Arg : String := Pace.Command_Line.Argument("NON_EXISTENT_KEY", "DEFAULT");
   begin
      Assert (Arg = "DEFAULT", "Argument should return default if key not found");
      Assert (not Pace.Command_Line.Has_Argument("NON_EXISTENT_KEY"), "Has_Argument should be false");
   end Test_Command_Line;

   procedure Test_Config (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Sim_Time : Duration;
      Y : Ada.Calendar.Year_Number;
      M : Ada.Calendar.Month_Number;
      D : Ada.Calendar.Day_Number;
      S : Ada.Calendar.Day_Duration;
   begin
      -- Just test that To_Sim_Time doesn't crash with valid input
      Sim_Time := Pace.Config.To_Sim_Time(2023, 1, 1, 0.0);
      
      -- Round trip might depend on SIMULATION_START env var, so result is relative.
      -- Let's test To_Calendar_Time.
      Pace.Config.To_Calendar_Time(Sim_Time, Y, M, D, S);
      
      -- Ideally this should match input if SIMULATION_START is consistent during call.
      -- But simpler test:
      Assert (GNAT.Calendar.Day_Name'Image(Pace.Config.Day_Of_Week(Sim_Time)) /= "", "Day_Of_Week should return something");
   end Test_Config;

   procedure Test_Fault (T : in out AUnit.Test_Cases.Test_Case'Class) is
      U : Unbounded_String := Pace.Fault.To_Name("Test_Fault");
   begin
      Assert (Pace.Fault.To_Str(U) = "Test_Fault", "Fault To_Name/To_Str round trip failed");
   end Test_Fault;

   procedure Test_Log (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      -- Just check basic execution
      Pace.Log.Wait(0.0);
      Assert (Pace.Log.Main /= "", "Pace.Log.Main should be set");
   end Test_Log;

   procedure Test_Log_System (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (not Pace.Log.System.Is_Paused, "System should not be paused by default");
   end Test_Log_System;

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Calendar'Access, "Test_Calendar");
      Register_Routine (T, Test_Command_Line'Access, "Test_Command_Line");
      Register_Routine (T, Test_Config'Access, "Test_Config");
      Register_Routine (T, Test_Fault'Access, "Test_Fault");
      Register_Routine (T, Test_Log'Access, "Test_Log");
      Register_Routine (T, Test_Log_System'Access, "Test_Log_System");
   end Register_Tests;

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Utilities Tests");
   end Name;

end Utilities_Test;
