with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Pace.Rule_Process;
with Pace.Strings;
with Ada.Text_Io;
with Pace.Semaphore;
with Ada.Directories;
with Gnat.Calendar;
with Ada.Command_Line;
with Ada.Exceptions;
with GNAT.OS_Lib;

package body Pace.Config is
   use Pace.Rule_Process;
   use Ada.Calendar;
   use Pace.Strings;

   KB : Agent_Type (100_000);

   Test_Time : Boolean := Pace.Getenv ("PACE_TEST_TIME", 0) = 1;
   Debug : Boolean := Pace.Getenv ("PACE_CONFIG_DEBUG", 0) = 1;
   Get_Separator : constant Character := GNAT.OS_Lib.Path_Separator;
   CN : constant String := Ada.Command_Line.Command_Name;
   Current : constant String :=   -- binary placed in bin/$OS
    CN(CN'First..Ada.Strings.Fixed.Index(CN, "/", Ada.Strings.Backward)) & "../../ssom/";
   Pace_Home : constant String := Current & Get_Separator & Current & "../../Common/ssom/";

   Simulation_Start : Time;

   -- save off current working directory for find_file operations in case
   -- the current working directory changes during runtime
   Startup_Cwd : String := Ada.Directories.Current_Directory & GNAT.OS_Lib.Directory_Separator;

   function To_Sim_Time (Year : Year_Number;
                         Month : Month_Number;
                         Day : Day_Number;
                         Seconds : Day_Duration) return Duration is
   begin
      return Time_Of (Year, Month, Day, Seconds) - Simulation_Start;
   end To_Sim_Time;

   procedure To_Calendar_Time (Sim_Time : Duration;
                               Year : out Ada.Calendar.Year_Number;
                               Month : out Ada.Calendar.Month_Number;
                               Day : out Ada.Calendar.Day_Number;
                               Seconds : out Ada.Calendar.Day_Duration) is
   begin
      Split (Simulation_Start + Sim_Time,
             Year, Month, Day, Seconds);
   end To_Calendar_Time;

   function Day_Of_Week (Sim_Time : Duration) return Gnat.Calendar.Day_Name is
   begin
      return Gnat.Calendar.Day_Of_Week (Simulation_Start + Sim_Time);
   end Day_Of_Week;

   function Get_Integer (Name : in String; Id : in String) return Integer is
   begin
      return Integer'Value (Get_String (Name, Id));
   end Get_Integer;

   function Get_String (Name : in String; Id : in String) return String is
      V : Variables (1..2);
   begin
      V(1) := S2u (Id);
      KB.Query (Name, V);
      return U2s (V (2));
   exception
      when No_Match =>
         raise Not_Found;
   end Get_String;


   procedure Load (File_Path : in String) is
   begin
      if File_Path /= "" then  -- rule processor can't handle empty string
         KB.Load (File_Path);
      end if;
   exception
      when No_Match =>
         Pace.Error ("File Not Loaded " & File_Path);
   end Load;


   function Parse (Tag_Name : in String) return String is
      use Ada.Strings.Fixed, Ada.Strings.Maps, Ada.Characters.Handling;
   begin
      return Translate (To_Lower (Tag_Name), To_Mapping (".", ","));
   end Parse;

   function Find_File (File_Name : String) return String is
      Pace_Path : String := Pace.Getenv ("PACE", Pace_Home);
      Sep : Character := Get_Separator;
      Num_Fields : Integer := Pace.Strings.Count_Fields (Pace_Path, Sep);
   begin
      if Debug then
         Ada.Text_IO.Put_Line ("using " & Sep & " as the separator");
      end if;
      for I in 1 .. Num_Fields loop
         declare
            File : String := Pace.Strings.Select_Field (Pace_Path, I, Sep) & 
                             GNAT.OS_Lib.Directory_Separator & File_Name;
            Abs_File : String := Startup_Cwd & File;
         begin
            if Ada.Directories.Exists (File) then
               if Debug then
                  Ada.Text_IO.Put_Line ("FFL:" & File);
               end if;
               return File;
            elsif Ada.Directories.Exists (Abs_File) then
               if Debug then
                  Ada.Text_IO.Put_Line ("FFA:" & Abs_File);
               end if;
               return Abs_File;
            end if;
         exception
            when Ada.Text_IO.Name_Error =>
               Error ("Pace.Config File Name Error", File);
               Error ("Pace.Config File Name Error", Abs_File);
               raise Ada.Text_IO.Name_Error;
         end;
      end loop;
      Error ("FF_blank");
      return "";
   end Find_File;

   Subnode_Counter : Integer := 0;
   Mutex : aliased Pace.Semaphore.Mutex;
   -- lock to ensure all subnodes returned are unique
   function Next_Subnode return Integer  is
      L : Pace.Semaphore.Lock (Mutex'Access);
   begin
      Subnode_Counter := Subnode_Counter + 1;
      return Subnode_Counter;
   end Next_Subnode;

begin

   KB.Init (Ini_File => "",
            Console => False,
            Screen => Pace.Getenv ("PACE_GRP_DEBUG", 0) = 1,
            Ini => (Clause    => 1000,
                    Hash      => 507,
                    In_Toks   => 500,
                    Out_Toks  => 500,
                    Frames    => 4000,
                    Goals     => 6000,
                    Subgoals  => 300,
                    Trail     => 5000,
                    Control   => 700));
   -- Initial File Load
   Load (Find_File ("/config.pro"));

   -- set up Simulation_Start
   if Test_Time then
      declare
         V : Variables (1..4);
      begin
         KB.Query ("pace_test_time", V);
         Simulation_Start := Time_Of (Year_Number'Value (U2s (V (1))),
                                      Month_Number'Value (U2s (V (2))),
                                      Day_Number'Value (U2s (V (3))),
                                      Day_Duration'Value (U2s (V (4))));
      end;
   else
      Simulation_Start := Ada.Calendar.Clock;
   end if;

exception
   when E : others =>
      Error ("Exception found in Pace.Config",
              Ada.Exceptions.Exception_Information (E));
      ------------------------------------------------------------------------------
      -- $id: pace-config.adb,v 1.1 09/16/2002 18:18:23 pukitepa Exp $
      ------------------------------------------------------------------------------
end Pace.Config;
