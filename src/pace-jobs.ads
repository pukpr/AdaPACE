with Str;
with Ada.Containers.Hashed_Sets;

package Pace.Jobs is

   pragma Elaborate_Body;

   -- A poll-free implementation of a one-at-a-time scheduler.  If
   -- a job tries to execute when another another one is already executing
   -- (aka the job is displaced), then it will execute as soon as the other
   -- one is done.  If multiple jobs are displaced then one of them will
   -- be chosen at random to go next.

   type Job_Status is (
      Pending,
      Pending_Displaced,
      Running,
      Completed,
      Cancelled);

   type Job is new Pace.Msg with record
      Unique_Id : Str.Bstr.Bounded_String;
      -- desired start time.. if 0.0 then start as soon as possible
      Start_Time        : Duration;
      Actual_Start_Time : Duration;  -- the time the job actually started at
      -- if false then it is okay to start the job after the start_time
      -- if true then the job must start at the start_time
      No_Later_Than     : Boolean  := False;
      Expected_Duration : Duration := 20.0;  -- for displaying to crew only
      -- the action to dispatch on when job starts
      -- It is necessary that an Input method be defined for Action
      -- and that the end of this Input method signifies the end
      -- of the Action
      Action : Pace.Channel_Msg;
      Status : Job_Status := Pending;
   end record;
   -- adds job to scheduler... dispatch to with a surrogate task
   procedure Input (Obj : in Job);

   -- returns a copy of the currently running job,
   -- or Null_Job if there are no jobs running
   function Get_Running_Job return Job;

   -- returns a copy of the job with the given unique_id or Null_Job if not
   --found
   function Get_Job (Unique_Id : Str.Bstr.Bounded_String) return Job;

   function Hash (Item : Job) return Ada.Containers.Hash_Type;

   function "=" (L, R : Job) return Boolean;

   Null_Job : constant Job :=
      Job'
     (Pace.Msg with
      Unique_Id         => Str.Bstr.Null_Bounded_String,
      Start_Time        => 0.0,
      Actual_Start_Time => 0.0,
      No_Later_Than     => False,
      Expected_Duration => 0.0,
      Action            => Null_Channel_Msg,
      Status            => Pending);

   -- cancels a pending job and removes it from the set of jobs
   -- no affect on running or completed jobs
   procedure Cancel_Job (Unique_Id : Str.Bstr.Bounded_String);

   package Job_Set_Pkg is new Ada.Containers.Hashed_Sets (Element_Type => Job,
                                                          Hash => Hash,
                                                          Equivalent_Elements => "=",
                                                          "=" => "=");

   -- returns a Set representing a copy of all the jobs
   -- (copy in order to be reentrant safe)
   -- an iterator of the container will not be in any particular order!
   procedure Get_Jobs (Copy_Job_Set : out Job_Set_Pkg.Set);

   function Is_Job_Executing return Boolean;

   -- Clears out all jobs, effectively restarting the scheduler
   -- A running job will finish to completion
   procedure Restart_Scheduler;

   -- to be used as the job id (or part of the job id)
   -- increments, so guarantees uniqueness between jobs
   function Get_Next_Id_Counter return String;

end Pace.Jobs;
