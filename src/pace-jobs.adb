with Pace.Log;
with Pace.Semaphore;
with Pace.Strings;
with Ada.Strings.Unbounded.Hash;

package body Pace.Jobs is

   -- represents the currently running job, or Null_Job when nothing is running
   Current_Job : Job := Null_Job;

   -- when no_later_than is set, this is the number of seconds a job must
   --start within
   -- the start_time before being cancelled
   Start_Time_Range : constant Duration := 2.0;

   Id_Counter : Natural := 0;

   use Pace.Semaphore;
   use Str;
   Execution_Mutex : aliased Mutex;

   ------------------------------------ the set of jobs
   ----------------------------
   function Hash (Item : Job) return Ada.Containers.Hash_Type is
   begin
      return Ada.Strings.Unbounded.Hash (B2u (Item.Unique_Id));
   end Hash;

   function "=" (L, R : Job) return Boolean is
      use Str.Bstr;
   begin
      if L.Unique_Id = R.Unique_Id then
         return True;
      else
         return False;
      end if;
   end "=";

   use Job_Set_Pkg;
   Job_Set : Set;
   -------------------------------------------------------------------------

   -- wrapper around the appropriate methods to make Job_Set reentrant safe
   protected Guarded_Jobs is
      procedure Insert (J : Job);
      procedure Cancel_Job (Unique_Id : Bstr.Bounded_String);
      procedure Change_Status
        (Unique_Id : Bstr.Bounded_String;
         Status    : Job_Status);
      procedure Set_Start_Time (Unique_Id : Bstr.Bounded_String);
      function Get_Job (Unique_Id : Bstr.Bounded_String) return Job;
      procedure Get_Jobs (Copy_Job_Set : out Job_Set_Pkg.Set);
      function Get_Status
        (Unique_Id : Bstr.Bounded_String)
         return      Job_Status;
      procedure Clear_Jobs;
   end Guarded_Jobs;
   protected body Guarded_Jobs is

      procedure Insert (J : Job) is
      begin
         Insert (Job_Set, J);
      end Insert;

      function Get_Job (Unique_Id : Bstr.Bounded_String) return Job is
         J    : Job;
         Iter : Cursor;
      begin
         J.Unique_Id := Unique_Id;
         Iter        := Find (Job_Set, J);
         if Iter = No_Element then
            return Null_Job;
         else
            return Element (Iter);
         end if;
      end Get_Job;

      procedure Set_Start_Time (Unique_Id : Bstr.Bounded_String) is
         New_Job : Job;
         Iter : Cursor;
      begin
         New_Job.Unique_Id := Unique_Id;
         Iter := Find (Job_Set, New_Job);
         New_Job := Element (Iter);
         New_Job.Actual_Start_Time := Pace.Now;
         Replace_Element (Job_Set, Iter, New_Job);
      end Set_Start_Time;

      function Get_Status
        (Unique_Id : Bstr.Bounded_String)
         return      Job_Status
      is
      begin
         return Get_Job (Unique_Id).Status;
      end Get_Status;

      procedure Cancel_Job (Unique_Id : Bstr.Bounded_String) is
         use Str.Bstr;
         J : Job := Get_Job (Unique_Id);
      begin
         -- only affects pending jobs
         if J.Unique_Id /= Null_Job.Unique_Id and
            (J.Status = Pending or J.Status = Pending_Displaced)
         then
            Change_Status (Unique_Id, Cancelled);
         end if;
      end Cancel_Job;

      procedure Get_Jobs (Copy_Job_Set : out Job_Set_Pkg.Set) is
         -- equals does shallow copy only, so must manually do this
         Iter : Cursor := First (Job_Set);
      begin
         --while Iter /= Back (Job_Set) loop
         while Iter /= No_Element loop
            Insert (Copy_Job_Set, Element (Iter));
            Next (Iter);
         end loop;
      end Get_Jobs;

      procedure Change_Status
        (Unique_Id : Bstr.Bounded_String;
         Status    : Job_Status)
      is
         New_Job : Job;
         Iter : Cursor;
      begin
         New_Job.Unique_Id := Unique_Id;
         Iter := Find (Job_Set, New_Job);
         New_Job := Element (Iter);
         New_Job.Status := Status;
         Replace_Element (Job_Set, Iter, New_Job);
      end Change_Status;

      procedure Clear_Jobs is
      begin
         Clear (Job_Set);
         Current_Job := Null_Job;
      end Clear_Jobs;

   end Guarded_Jobs;

   ----------------------------------------------------------------------------
   ------

   procedure Input (Obj : in Job) is
      Time_To_Wait : Duration;
      Tolerance    : Duration := 0.1;

      -- return false if job was cancelled or schedule has been restarted
      function Continue_On return Boolean is
      begin
         if Guarded_Jobs.Get_Job (Obj.Unique_Id) = Null_Job or
            Guarded_Jobs.Get_Status (Obj.Unique_Id) = Cancelled
         then
            return False;
         else
            return True;
         end if;
      end Continue_On;

   begin
      if Obj.Start_Time = 0.0 then
         -- then start as soon as possible
         Guarded_Jobs.Insert (Obj);
      else
         if Obj.Start_Time + Tolerance < Pace.Now then
            Pace.Display
              ("start_time is " &
               Obj.Start_Time'Img &
               " which is less than now ( " &
               Pace.Now'Img &
               ")");
            return;
         else
            Time_To_Wait := Obj.Start_Time - Pace.Now;
            if Time_To_Wait < 0.0 then
               -- in case time_to_wait took advantage of the tolerance
               Time_To_Wait := 0.0;
            end if;
         end if;
         Guarded_Jobs.Insert (Obj);
         Pace.Log.Wait (Time_To_Wait);
      end if;

      if Continue_On then
         -- multiple jobs may end up waiting for the lock at this point
         Guarded_Jobs.Change_Status (Obj.Unique_Id, Pending_Displaced);
         declare
            L : Lock (Execution_Mutex'Access);
         begin
            -- if no_later_than check the start_time_range, and if out of
            --range then
            -- cancel the job
            if Obj.No_Later_Than and
               (Pace.Now > (Obj.Start_Time + Start_Time_Range))
            then
               Cancel_Job (Obj.Unique_Id);
            end if;

            if Continue_On then
               Guarded_Jobs.Change_Status (Obj.Unique_Id, Running);
               Current_Job := Guarded_Jobs.Get_Job (Obj.Unique_Id);
               Guarded_Jobs.Set_Start_Time (Obj.Unique_Id);
               Pace.Dispatching.Input (+Obj.Action);
               Guarded_Jobs.Change_Status (Obj.Unique_Id, Completed);
               Current_Job := Null_Job;
            end if;
         end;
      end if;
      Pace.Log.Trace (Obj);
   exception
      when E : Constraint_Error =>
         -- Most likely the set was cleared and the status of a non-existing
         --job
         -- was attempted to be changed through a pointer.. since set was
         --cleared
         -- we can just exit here without logging an exception
         Pace.Display ("Job is quitting since the set was cleared!");
   end Input;

   procedure Get_Jobs (Copy_Job_Set : out Job_Set_Pkg.Set) is
   begin
      Guarded_Jobs.Get_Jobs (Copy_Job_Set);
   end Get_Jobs;

   function Get_Job (unique_id : Bstr.Bounded_String) return Job is
   begin
      return Guarded_Jobs.Get_Job (Unique_Id);
   end Get_Job;

   procedure Cancel_Job (unique_id : Bstr.Bounded_String) is
   begin
      Guarded_Jobs.Cancel_Job (Unique_Id);
   end Cancel_Job;

   function Is_Job_Executing return Boolean is
      use Str.Bstr;
   begin
      if Current_Job.Unique_Id = Null_Job.Unique_Id then
         return False;
      else
         return True;
      end if;
   end Is_Job_Executing;

   function Get_Running_Job return Job is
   begin
      return Current_Job;
   end Get_Running_Job;

   procedure Restart_Scheduler is
   begin
      Guarded_Jobs.Clear_Jobs;
   end Restart_Scheduler;

   function Get_Next_Id_Counter return String is
   begin
      Id_Counter := Id_Counter + 1;
      return Pace.Strings.Trim (Id_Counter);
   end Get_Next_Id_Counter;

end Pace.Jobs;
