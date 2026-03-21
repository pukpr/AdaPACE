with Ada.Real_Time;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Tags;
with Ada.Task_Attributes;
with Pace.Queue.Guarded;
with System;
with Ada.Text_Io;
with Ada.Unchecked_Deallocation;
with Pace.Config;
--with Pace.Semaphore;

package body Pace.Log is

   Config_Debugging : constant Boolean := Getenv ("PACE_LOG_DEBUG", 0) = 1;
   Ignore_Pipe : constant Boolean := Getenv ("PACE_IGNORE_PIPE", 0) = 1;
   
   function Unit_Id return String is
      E : exception;
      S : constant String := Ada.Exceptions.Exception_Name (E'Identity);
      P : Integer := S'Last;
   begin
      for I in 1 .. 3 loop
         P :=
           Ada.Strings.Fixed.Index (S (1 .. P), ".", Ada.Strings.Backward) - 1;
      end loop;
      return S (1 .. P);
   end Unit_Id;

   procedure Print (Text : in String;
                    Value : in Integer := Debug_Level) is
      Buffer : String (1..30) := (others => ' ');
   begin
      -- At this point can bring in a Kbase or Database to isolate debug
      -- statements based on the Unit ID.
      -- For example, via a "config.pro":
      --     debug_level("AHO.IRU", 0).
      -- If these entries are hashed, then a Debug_Level can be read in dynamically
      -- without needing a reecompile.
      Ada.Strings.Fixed.Overwrite (Buffer, 1, ID); 
      Pace.Log.Put_Line (Buffer & "-- " & Text, Value);
   end Print;

   --
   -- Exceptions
   --
   package Q_Ex_Unguarded is new Pace.Queue
                                   (Ada.Strings.Unbounded.Unbounded_String);
   package Q_Ex is new Q_Ex_Unguarded.Guarded;

   procedure Ex (X : in Ada.Exceptions.Exception_Occurrence;
                 S : in String := "") is
      Info : constant String :=
        Get_Agent_Id & " : " &
          Ada.Exceptions.Exception_Information (X) & " : " & S;
   begin
      Pace.Error ("*** LOGGING ERROR in " & Info);
      Q_Ex.Put (Ada.Strings.Unbounded.To_Unbounded_String (Info));
   end Ex;

   function Wait_For_Ex return String is
      Info : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Q_Ex.Get (Info);
      return Ada.Strings.Unbounded.To_String (Info);
   exception
      when E: others =>
         Pace.Error ("Error retrieving diagnostic errors");
         return Get_Agent_Id & " : " & Ada.Exceptions.Exception_Information (E);
   end Wait_For_Ex;

   --
   -- Timing and Discrete Event Engine
   --

   package Rt renames Ada.Real_Time;

   Trace_File : Ada.Text_Io.File_Type; -- Simulation trace output

   Display_Debug : Boolean := False; -- Display debug information
   External_Clock : Boolean := False; -- Drive through external clock
   Trace_On : Boolean := False; -- Simulation trace is on
   Debug_Level : Integer := 0; -- Debug level to Put_Line display

   protected Protected_Time is
      procedure Set (Val : in Duration);
      function Get return Duration;
   private
      Sim_Time : Duration := 0.0;
   end Protected_Time;

   package Time_Io is new Ada.Text_Io.Fixed_Io (Duration);

   Sync_Id : array (Synchronization) of String (1 .. 4) := (Sync => " >> ",
                                                            Async => " -> ",
                                                            Simple => " => ",
                                                            Balk => " <> ",
                                                            Timeout => " 0> ");

   --
   -- Dedicated Structure for identifying tasks
   --
   protected type Waiter is
      entry Wait_For;
      procedure Signal (Time : in Duration);
   private
      Open : Boolean := False;
   end Waiter;

   type Wait_Record;
   type Wait_Access is access all Wait_Record;
   type Wait_Record is
      record
         Time : Duration := 0.0;
         W : Waiter;
         Next : Wait_Access := null;
      end record;

   type String_Access is access all String;
   procedure Free is new Ada.Unchecked_Deallocation (String, String_Access);

   type Task_Resource is
      record
         Name : String_Access;
         Timer : Duration;
         Sim_Wait : Wait_Access;
         Debug : Integer;
      end record;
   Unnamed_Task : String_Access := new String'("unnamed.task");
   Default_Resource : constant Task_Resource :=
     (Name => Unnamed_Task, Timer => 0.0, Sim_Wait => null, Debug => Integer'First);

   package T_Attr is new Ada.Task_Attributes (Task_Resource, Default_Resource);
   Elab_Task : Thread := Current;

   function T_Name (Message : in Msg'Class) return String is
      use Ada.Task_Identification;
   begin
      if Message.Id = Null_Task_Id then
         return "external" & Integer'Image (-Message.Slot) & ".task";
      elsif Message.Id = Elab_Task and then
            T_Attr.Value (Message.Id).Name = Unnamed_Task then
         return "main.elaboration";
      else
         return T_Attr.Value (Message.Id).Name.all;
      end if;
   exception
      when E: others =>  -- Not registered in current program
         Error ("Task name NOT registered " &
                Ada.Task_Identification.Image (Message.Id) & " " &
                Ada.Exceptions.Exception_Information (E));
         return "unknown.task";
   end T_Name;

   Encountered_Shell_Filesize_Limit : Boolean := False;
   Quit_Was_Set : Boolean := False;

   --
   -- Trace output format
   --
   procedure Event_Trace (Message : in Msg'Class;
                          Msg_Send : in Synchronization;
                          Now_Time : in Duration) is
   begin
      if Trace_On then
         Time_Io.Put (Trace_File, Rt.To_Duration
                                    (Message.Time)); -- Print start time
         Ada.Text_Io.Put (Trace_File, ":");
         Time_Io.Put (Trace_File, Now_Time); -- Print current simulation time
         Ada.Text_Io.Put (Trace_File, ": ");
         Ada.Text_Io.Put (Trace_File, T_Name (Message));
         Ada.Text_Io.Put (Trace_File, Sync_Id (Msg_Send));
         Ada.Text_Io.Put (Trace_File, Ada.Tags.External_Tag (Message'Tag));
         Ada.Text_Io.Put (Trace_File, Integer'Image
                                        (Message'Size / 8)); -- Size in Bytes
         Ada.Text_Io.New_Line (Trace_File);
      elsif Display_Debug and then Now_Time = 0.0 then
         Ada.Text_Io.Put_Line (Ada.Tags.External_Tag (Message'Tag));
      end if;
   exception
      when E : others =>
         if not Quit_Was_Set then
            Pace.Error ("Trace_File hit " & Ada.Exceptions.Exception_Name(E),
                       "Encountered Shell Filesize Limit=" & 
                        Boolean'Image (Encountered_Shell_Filesize_Limit));
         end if;
		     
         Trace_On := False;
   end Event_Trace;

   protected Trace_Buffer is
      procedure Put (Message : in Msg'Class;
                     Msg_Send : in Synchronization;
                     Now_Time : in Duration);
      procedure Put (Message : in String);
   end Trace_Buffer;

   protected body Trace_Buffer is
      procedure Put (Message : in Msg'Class;
                     Msg_Send : in Synchronization;
                     Now_Time : in Duration) is
      begin
         Event_Trace (Message, Msg_Send, Now_Time);
      end Put;
      procedure Put (Message : in String) is
      begin
         Ada.Text_Io.Put_Line (Message);
      end Put;
   end Trace_Buffer;

   --
   -- Trace out a message path
   --
   procedure Trace (Message : in Msg'Class) is
      use type Ada.Task_Identification.Task_Id;
      use type Rt.Time_Span;
      Id : Thread := Current;
      Msg_Send : Synchronization := Message.Send;
      Delay_Time : Duration := 0.0;
      Now_Time : Duration;
   begin
      if Display_Debug then
         Trace_Buffer.Put (Message, Msg_Send, 0.0);
      end if;
      if Message.Wait = Zero then            -- If delay time not set in code,
--     Delay_Time := Wait_Time (Message); -- read from table
         if Delay_Time /= 0.0 then
            Wait (Delay_Time);
         end if;
      elsif Message.Wait < Zero then
         null;                                 -- no waits on negative delays
      else
         Wait (Rt.To_Duration (Message.Wait));  -- else delay
      end if;
      if Message.Id /= Id and then
         Message.Send = Simple then -- Override, sending across tasks
         Msg_Send := Sync;
      end if;
      Now_Time := Now;
      Trace_Buffer.Put (Message, Msg_Send, Now_Time);
   end Trace;

   function Get_Agent_Id (Id : Thread := Current) return String is
   begin
      return T_Attr.Value (Id).Name.all;
   end Get_Agent_Id;

   --
   -- Discrete Event Engine Utilities
   --

   Simulated : Boolean := True;

   protected Resource is
      entry Get_Waiter (Time : in Duration;
                        Next_In_Line : out Wait_Access;
                        Id : in Thread);
      function Get_Time return Duration;
      procedure Remove_Waiter;
      function Current_Waiter return Wait_Access;
      procedure Signal;
   private
      The_Current_Waiter : Wait_Access := null; -- new Wait_Record;
      Busy : Boolean := False;
   end Resource;

--    procedure Free is new Ada.Unchecked_Deallocation (Wait_Record, Wait_Access);

   -- Simulated (non-Real Time) states
   Current_Time : Duration := 0.0;
   Run_Until_Time : Duration := 0.0;
--   Current_Waiter : Wait_Access := null; -- new Wait_Record;
   Ready_To_Run_Scheduler : Boolean := False;

   -- Real Time states
   Latency : Duration := 0.0;
   Start_Time : Rt.Time := Rt.Clock;
   Time_Scale : Duration := 1.0;
   Time_Base : Duration := 1.0;  -- the initial "time_scale" which can not change after elaboration

--    pragma Atomic (Time_Scale);

   function Task_Debugging (Name : in String) return Integer is
      use Pace.Config;
   begin
      return Get_Integer ("log", Parse (Name));
   exception
      when Not_Found =>
         return Integer'First;
      when others =>
         Error ("Task_Debugging, in config rule for log()", Name);
         return Integer'First;
   end Task_Debugging;

   task Scheduler is
      entry Start;
      pragma Priority (System.Priority'First);
   end Scheduler;

   procedure Ignore_Signal is
      procedure Signal (Sig, Op : in Integer);
      pragma Import (C, Signal, "signal");
      Sigpipe : constant := 13; -- Note: Not defined on Windows!
      Ignore : constant := 1;   -- Callback cast to 1 means ignore
   begin
      -- PIPE is a UNIX signal that exits program if not ignored or caught.
      -- It looks as if it needs to be caught on a per thread basis also.
      -- Other OS's such as Windows will ignore it
      if Ignore_Pipe then
         Signal (Sigpipe, Ignore);
      end if;
   end Ignore_Signal;

   --
   -- Name the agent task
   --
   procedure Agent_Id (Name : in String := Main) is
      use Ada.Strings.Fixed;
      Agent_Name : String_Access;
      Task_Data : Task_Resource := T_Attr.Value; -- Default_Resource;
   begin
      if Task_Data.Name = Unnamed_Task then
         Ignore_Signal; -- Ignore signals that exit program
         Task_Data.Sim_Wait := new Wait_Record; -- Discrete event resource
         if Name = Main then
            declare
               Name : constant String := Getenv ("PACE_TRACE_OUT", "trace.out");
            begin
               Ada.Text_Io.Create (Trace_File, Ada.Text_Io.Out_File, Name);
               Trace_On := True;
            exception
               when others =>
                  Display ("WARNING: Can't create trace file : " & Name);
            end;
            -- Load.Timings will get activated, when scheduler is ready to run
            Current_Time := 0.0;
            Scheduler.Start;
            Start_Time := Rt.Clock;
            Agent_Name := new String'("main.procedure");
         else
            Agent_Name := new String'(Name);
         end if;
         if Display_Debug then
            Trace_Buffer.Put ("Starting task " & Agent_Name.all & " => " &
                              Ada.Task_Identification.Image (Current));
         end if;
      else  -- A task renaming
         Agent_Name := new String'(Name);
         Free (Task_Data.Name);
         pragma Debug (Trace_Buffer.Put ("Renaming task to " & Agent_Name.all));
      end if;
      Task_Data.Name := Agent_Name;
      if Config_Debugging then
         Task_Data.Debug := Task_Debugging (Name);
      end if;
      T_Attr.Set_Value (Task_Data);
   end Agent_Id;


   protected body Waiter is
      entry Wait_For when Open is
--         Old_Waiter : Wait_Access;
      begin
         pragma Debug(Ada.Text_IO.Put (" w "));
         Open := False;
--         Resource.Remove_Waiter;
--         if Current_Waiter /= null then
--            Old_Waiter := Current_Waiter;
--            Current_Waiter := Current_Waiter.Next;
--            Old_Waiter.Next := null;
--            Old_Waiter.Time := 0.0;
--         end if;
      end Wait_For;

      procedure Signal (Time : in Duration) is
      begin
         pragma Debug(Ada.Text_IO.Put (" s "));
         Current_Time := Time;
         Open := True;
      end Signal;
   end Waiter;

   protected body Resource is

      entry Get_Waiter (Time : in Duration;
                        Next_In_Line : out Wait_Access;
                        Id : in Thread) when not Busy is
         Next_Time : Duration := Current_Time + Time;
         Iterator : Wait_Access := The_Current_Waiter;
         New_Waiter : Wait_Access;
         Task_Data : Task_Resource := T_Attr.Value (ID); -- Default_Resource;
      begin
         Next_In_Line := The_Current_Waiter;
         loop
            if Next_In_Line = null then
               -- add at end
               pragma Debug(Ada.Text_IO.Put (" end "));
               Next_In_Line := Task_Data.Sim_Wait; -- new Wait_Record;
               Next_In_Line.Next := null;
               Next_In_Line.Time := Next_Time;
               if The_Current_Waiter = null then
                  The_Current_Waiter := Next_In_Line;
               else
                  Iterator.Next := Next_In_Line;
               end if;
               exit;
            elsif Next_In_Line.Time <= Next_Time then  -- this was "<"
               -- skip to next time
               pragma Debug(Ada.Text_IO.Put (" skip "));
               Iterator := Next_In_Line;
               Next_In_Line := Next_In_Line.Next;
            else
               -- insert new time
               pragma Debug(Ada.Text_IO.Put (" insert "));
               New_Waiter := Task_Data.Sim_Wait; -- new Wait_Record;
               New_Waiter.Next := Next_In_Line;
               New_Waiter.Time := Next_Time;
               Next_In_Line := New_Waiter;
               if The_Current_Waiter = New_Waiter.Next then
                  The_Current_Waiter := Next_In_Line;
               else
                  Iterator.Next := Next_In_Line;
               end if;
               exit;
            end if;
         end loop;
      end Get_Waiter;

      function Get_Time return Duration is
      begin
         return Current_Time;
      end Get_Time;

      procedure Remove_Waiter is
         Old_Waiter : Wait_Access;
      begin
         pragma Debug(Ada.Text_IO.Put (" rem? "));
         if The_Current_Waiter /= null then
            pragma Debug(Ada.Text_IO.Put (" rem "));
            Old_Waiter := Current_Waiter;
            The_Current_Waiter := The_Current_Waiter.Next;
            Old_Waiter.Next := null;
            Old_Waiter.Time := 0.0;
         end if;
         Busy := False;
      end;

      function Current_Waiter return Wait_Access is
      begin
         return The_Current_Waiter;
      end;

      procedure Signal is
      begin
         if Busy then
            pragma Debug(Ada.Text_IO.Put (" busy "));
            return;
         end if;
         pragma Debug(Ada.Text_IO.Put (" sig? "));
         if The_Current_Waiter /= null then
            pragma Debug(Ada.Text_IO.Put (" sig "));
            Busy := True;
            The_Current_Waiter.W.Signal (The_Current_Waiter.Time);
            Remove_Waiter;
         end if;
      end;

   end Resource;

   function Sim_Now return Duration;

   procedure Set_Quit is
   begin
      if Trace_On then
         Quit_Was_Set := True;
         Ada.Text_Io.Close (Trace_File);
      end if;
      Os_Exit (0);
   end Set_Quit;

   task body Scheduler is
      Time_Out : Integer := 0;
      Check_Interval : Duration := 0.001;
      Max_Checks : constant Integer := 5000;
      Is_Sim_Local : Boolean;
      Time_Out_Increment : Integer;
      function Id is new Unit_Id;
   begin
      Agent_Id (Id);
      Check_Interval := Check_Interval * Getenv ("PACE_SIM_TICS", 1);
      Is_Sim_Local := not External_Clock;
      Time_Out_Increment := Boolean'Pos (Is_Sim_Local);
      accept Start;
      Ready_To_Run_Scheduler := True;
      -- Note: "May need to make sure that Sim_Now is set in case Pace.Now calls are made
      ---       so as to properly override changes in time scale or pause/resume behavior"
      -- if Simulated then
      --    Pace.Set_Clock (Sim_Now'Access);
      -- end if;
      loop
         delay Check_Interval;
         if not Simulated then
            Put_Line ("Exiting SIM SCHEDULER, PACE_SIM=0", 2);
            exit;
         elsif Resource.Current_Waiter = null then
            Time_Out := Time_Out + Time_Out_Increment;
            pragma Debug(Ada.Text_IO.Put (" nul "));
            exit when Time_Out > Max_Checks;
         elsif Is_Sim_Local or else -- get the external clock time
               Protected_Time.Get > Resource.Current_Waiter.Time then
            Time_Out := 0;
            Resource.Signal;
            -- Current_Waiter.W.Signal (Current_Waiter.Time);
         end if;
         exit when Run_Until_Time /= 0.0 and then Now > Run_Until_Time;
      end loop;
      if Simulated then -- All tasks blocked for time-out interval
         Set_Quit;
      elsif Run_Until_Time /= 0.0 then
         Wait_Until (Run_Until_Time);
         Set_Quit;
      end if;
      Put_Line ("SCHEDULER EXITS", 2);
   exception
      when others =>
         Error ("Exception in Sim Scheduler");
   end Scheduler;

   protected Run_Enable is
      function Running return Boolean;
      entry Pause;
      procedure Toggle;
   private
      Is_Running : Boolean := True;
      Time_Paused : Duration := 0.0;
   end;


   No_Wait : Boolean := False;

   procedure Wait (Time : in Duration) is
   begin
      if Simulated then
         declare
            Object : Wait_Access;
         begin
            Resource.Get_Waiter (Time, Object, Current);
            Object.W.Wait_For;
         end;
      elsif not No_Wait then
         if Run_Enable.Running then
            null;
         else
            Run_Enable.Pause;
         end if;
         delay Time_Scale * Time - Latency;
      end if;
   end Wait;

   procedure Wait_Until (Time : in Duration) is
      use Rt;
   begin
      if Simulated then
         if Time > Now then
            Wait (Time - Now);
         end if;
      elsif not No_Wait then
         if Run_Enable.Running then
            null;
         else
            Run_Enable.Pause;
         end if;
         if Time_Scale = 1.0 then
            delay until Start_Time + To_Time_Span (Time);
         else
            delay Time_Scale * (Time - Sim_Now);
         end if;
      end if;
   end Wait_Until;

   procedure Timer_Start (Time : in Duration) is
      Task_Data : Task_Resource := T_Attr.Value;
   begin
      Task_Data.Timer := Now + Time;
      T_Attr.Set_Value (Task_Data);
   end Timer_Start;

   function Timer_Expired return Boolean is
   begin
      return Now > T_Attr.Value.Timer;
   end Timer_Expired;

   function Sim_Now return Duration is
      use Rt;
   begin
      if Simulated then
         return Resource.Get_Time;
      elsif not No_Wait then
         if Ready_To_Run_Scheduler then
            if Time_Scale = 1.0 then
               return To_Duration (Clock - Start_Time);
            else
               return To_Duration (Clock - Start_Time) / Time_Base;
            end if;
         else
            return 0.0;
         end if;
      else
         return 0.0;
      end if;
   end Sim_Now;

   protected body Run_Enable is
      function Running return Boolean is
      begin
         return Is_Running;
      end;

      entry Pause when Is_Running is
      begin
         Put_Line ("Halt control released");
      end;

      procedure Toggle is
         Diff : Duration;
         use Rt;
      begin
         if Is_Running then
            Time_Paused := Sim_Now;
         else
            Diff := Sim_Now - Time_Paused;
            Start_Time := Start_Time + To_Time_Span(Diff);
         end if;
         Is_Running := not Is_Running;
         Put_Line ("Halt control to " & Boolean'Image(Running));
         -- Need to set the clock override at the top level so that pauses accounted for
         Pace.Set_Clock (Sim_Now'Access);
      end;
   end;

   protected body Protected_Time is
      procedure Set (Val : in Duration) is
      begin
         Sim_Time := Val;
      end Set;

      function Get return Duration is
      begin
         return Sim_Time;
      end Get;
   end Protected_Time;

   procedure Set_Time (Value : in Duration) is
   begin
      Protected_Time.Set (Value);
   end Set_Time;

   procedure Set_Time_Scale (Value : in Duration) is
   begin
      if Value > 0.0 then
         if not Ready_To_Run_Scheduler then
            Time_Base := Value;
         end if;
         Time_Scale := Value;
      end if;
      Pace.Set_Clock (Sim_Now'Access);
   end Set_Time_Scale;

   --
   -- Auxilliary Functions
   --

   procedure Exit_To_OS (Status : in Integer);
   pragma Import (C, Exit_To_OS, "exit");  -- 0 => OK, 1 => Error

   procedure Exit_To_OS_Now (Status : in Integer);
   pragma Import (C, Exit_To_OS_Now, "_exit");  -- 0 => OK, 1 => Error

   protected Exit_Waiter is
      entry Suspend (Status : out Integer);
      procedure Trigger (Status : in Integer;
                         Pending : out Boolean);
   private
      Ready : Boolean := False;
      State : Integer;
   end;

   protected body Exit_Waiter is
      entry Suspend (Status : out Integer) when Ready is
      begin
         Status := State;
      end;

      procedure Trigger (Status : in Integer;
                         Pending : out Boolean) is
      begin
         Pending := Suspend'Count > 0;
         State := Status;
         Ready := True;
      end;
   end;


   package Exit_Queue is new Pace.Queue(Channel_Msg);
   package Exit_Q is new Exit_Queue.Guarded;

   procedure Os_On_Exit (Call : in Msg'Class) is
   begin
      Exit_Q.Put (+Call);
   end Os_On_Exit;

   procedure Os_Exit (Status : in Integer) is
      Pending : Boolean;
   begin
      Exit_Waiter.Trigger (Status, Pending);
      if Pending then  -- If there is a client waiting let that handle exit
         Pace.Log.Put_Line ("Other Agents pending to clean up before OS Exit");
      else
         if Getenv ("_EXIT", "0") = "1" then
            Exit_To_OS_Now (Status);
         else
            Exit_To_OS (Status);
         end if;
      end if;
   end Os_Exit;

   procedure Os_Wait (Status : out Integer) is
      Exit_Msg : Channel_Msg;
   begin
      Exit_Waiter.Suspend (Status);
      while Exit_Q.Is_Ready loop
         Exit_Q.Get (Exit_Msg);
         Pace.Input (+Exit_Msg);
      end loop;
   end Os_Wait;



   Model_Display : Display_Proc := null; -- Alternate display
--   Mx : aliased Pace.Semaphore.Mutex;

   procedure Put_Line (Text : in String; Value : in Integer := 0) is
--      L : Pace.Semaphore.Lock(Mx'Access);
      function Debug_Line (Text : in String) return String is
         Buffer : String (1..30) := (others => ' ');
      begin
         Ada.Strings.Fixed.Overwrite (Buffer, 1, T_Attr.Value.Name.all); 
         return Buffer & ":: " & Text;
      end Debug_Line;
   begin
      if Config_Debugging then
         if T_Attr.Value.Debug = -Value or   -- Only one level
           T_Attr.Value.Debug >= Value then  -- Range of levels
            if Model_Display = null then
               Ada.Text_Io.Put_Line (Debug_Line (Text));
            else
               Model_Display (Debug_Line (Text));
            end if;
         end if;
      elsif Value = -Debug_Level or
        (Value >= 0 and Value <= Debug_Level) then
         if Model_Display = null then
            Ada.Text_Io.Put_Line (Text);
         else
            Model_Display (Text);
         end if;
      end if;
   end Put_Line;

   procedure Set_Display (To : in Display_Proc) is
--      L : Pace.Semaphore.Lock(Mx'Access);
   begin
      Model_Display := To;
   end Set_Display;

   function Get_Display return Display_Proc is
--      L : Pace.Semaphore.Lock(Mx'Access);
   begin
      return Model_Display;
   end Get_Display;

   function Task_Storage (Name : in String) return Integer is
      use Pace.Config;
   begin
      return Get_Integer ("task_storage", Parse (Name));
   exception
      when Not_Found =>
         return 50_000; -- big enough for most apps
   end Task_Storage;

   function Task_Priority (Name : in String) return Integer is
      use Pace.Config;
   begin
      return Get_Integer ("task_priority", Parse (Name));
   exception
      when Not_Found =>
         return System.Default_Priority;
   end Task_Priority;


   procedure Pause_Resume (Force_Resume : Boolean := False) is
   begin
      if Force_Resume then
         if Is_Paused then
            Put_Line ("Forcing execution to resume.");
            Run_Enable.Toggle;
         else
            Put_Line ("Execution in progress, resuming execution not needed.");
         end if;
      else
         if Is_Paused then
            Put_Line ("Execution toggled to resume.");
         else
            Put_Line ("Execution toggled to pause.");
         end if;
         Run_Enable.Toggle;
      end if;
   end;

   function Is_Paused return Boolean is
   begin
      return not Run_Enable.Running;
   end Is_Paused;
   
   protected body Counter is
      procedure Increment (Value : out Long_Integer) is
      begin
         Count := Count + 1;
         Value := Count;
      end Increment;
   end Counter;

   protected File_Interrupt is
      procedure Handle_Size_Overrun;
      --pragma Attach_Handler(Handle_Size_Overrun, 25); --=> SIGXFSZ File Size Limit
   end;

   protected body File_Interrupt is
      procedure Handle_Size_Overrun is
      begin
         Encountered_Shell_Filesize_Limit := True;
      end;
   end;


begin
   No_Wait := Getenv ("PACE_NO_WAIT", 0) = 1;
   Simulated := Getenv ("PACE_SIM", 0) = 1;
   Set_Time_Scale (Duration (Getenv ("PACE_TIME_SCALE", 1.0)));
   Display_Debug := Getenv ("PACE_DISPLAY_DEBUG", 0) = 1;
   Run_Until_Time := Duration (Getenv ("PACE_RUN_TIME", 0.0)) / Time_Scale;
   Latency := Duration (Getenv ("PACE_LATENCY", 0.0));
   Debug_Level := Integer'Value(Pace.Getenv("PACE_DEBUG_LEVEL", "0"));
exception
   when others =>
      Display ("ERROR: Pace.Log elaboration");
------------------------------------------------------------------------------
-- $id: pace-log.adb,v 1.3 05/12/2003 22:08:50 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Log;

