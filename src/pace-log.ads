with Ada.Exceptions;
with Gnat.Source_Info;

package Pace.Log is
   ------------------------------------------------------
   -- LOG -- Logging trace and exceptions for later retrieval
   ------------------------------------------------------
   pragma Elaborate_Body;

   --
   -- Name a Unit automatically
   --
   generic
   function Unit_Id return String;

   -- Create an orthognal debugging facility
   -- 1. The ID allows debugging on a per Unit basis
   -- 2. A higher Debug_Level allows greater detail or resolution on Unit
   generic  -- If instanced after Unit_Id brings in name automatically via <>
      with function ID return String is <>; 
      Debug_Level : in Integer := 0;
   procedure Print (Text : in String; -- Calls Put_Line with Debug_Level in Value
                    Value : in Integer := Debug_Level);  

   function Name return String renames Gnat.Source_Info.Source_Location;

   --
   -- Register the task Agent via the exception name mechanism
   --
   Main : constant String; -- identifies main procedure
   procedure Agent_Id (Name : in String := Main);

   --
   -- Exceptions
   --
   procedure Ex (X : in Ada.Exceptions.Exception_Occurrence; -- Exception
                 S : in String := "");                       -- Extra info
   -- Logs the specific error

   function Wait_For_Ex return String;
   -- Handler function that waits for an informational error string

   -- Delay for (simulated) time
   procedure Wait (Time : in Duration);
   procedure Wait_Until (Time : in Duration);

   -- Timer for (simulated) time
   procedure Timer_Start (Time : in Duration);
   function Timer_Expired return Boolean;

   -- Trace out message to log
   procedure Trace (Message : in Msg'Class);

   -- Exit application
   procedure Os_On_Exit (Call : in Msg'Class);
   procedure Os_Exit (Status : in Integer);   -- 0=>OK, 1=>Error
   procedure Os_Wait (Status : out Integer);  -- Wait For Exit sig

   -- Console Display
   procedure Put_Line (Text : in String; Value : in Integer := 0);
   -- Redirecting the Display
   type Display_Proc is access procedure (Text : in String);
   procedure Set_Display (To : in Display_Proc);
   function Get_Display return Display_Proc;

   -- Default specifiers
   function Task_Storage (Name : in String) return Integer;
   function Task_Priority (Name : in String) return Integer;

   -- a monotonically increasing counter
   -- (used for web caching)
   protected Counter is
      procedure Increment (Value : out Long_Integer);
   private
      Count : Long_Integer := 0;
   end Counter;

private

   function Get_Agent_Id (Id : Thread := Current) return String;

   procedure Set_Time_Scale (Value : in Duration);

   Main : constant String := "main";

   -- Toggles to either Pause/Resume depending on last state, Force_Resume forces resumption
   procedure Pause_Resume (Force_Resume : Boolean := False);
   function Is_Paused return Boolean;

------------------------------------------------------------------------------
-- $id: pace-log.ads,v 1.2 05/12/2003 22:08:17 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Log;

