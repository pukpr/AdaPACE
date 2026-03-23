with AUnit.Test_Cases.Registration;
use AUnit.Test_Cases.Registration;

with AUnit.Assertions; use AUnit.Assertions;

with Pace;
with Pace.Log;
with Pace.Jobs;
with Pace.Surrogates;
with Uio.Pace_Jobs;
with Str;
with Ada.Containers;

package body Uut.Pace_Jobs is

   use Pace.Jobs;
   use Str;

   procedure Test_Normal_Operation (R : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Cancel (R : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Simple_Overlapping (R : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Same_Start_Time (R : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Clear (R : in out Aunit.Test_Cases.Test_Case'Class);
   procedure Test_Copy (R : in out Aunit.Test_Cases.Test_Case'Class);
   procedure Test_Invalid_Start_Time (R : in out Aunit.Test_Cases.Test_Case'Class);
   procedure Test_No_Later_Than_Time (R : in out Aunit.Test_Cases.Test_Case'Class);

   Jobs : array (1 .. 20) of Job;

   A_Length : Duration := 30.0;    -- 1/2 a minute
   type A_Action is new Pace.Msg with null record;
   procedure Input (Obj : A_Action);
   procedure Input (Obj : A_Action) is
   begin
      Pace.Log.Wait (A_Length);
   end Input;
   B_Length : Duration := 60.0;   -- 1 minute
   type B_Action is new Pace.Msg with null record;
   procedure Input (Obj : B_Action);
   procedure Input (Obj : B_Action) is
   begin
      Pace.Log.Wait (B_Length);
   end Input;
   C_Length : Duration := 180.0;   -- 3 minutes
   type C_Action is new Pace.Msg with null record;
   procedure Input (Obj : C_Action);
   procedure Input (Obj : C_Action) is
   begin
      Pace.Log.Wait (C_Length);
   end Input;
   D_Length : Duration := 600.0;   -- 10 minutes
   type D_Action is new Pace.Msg with null record;
   procedure Input (Obj : D_Action);
   procedure Input (Obj : D_Action) is
   begin
      Pace.Log.Wait (D_Length);
   end Input;
   E_Length : Duration := 18000.0;   -- 5 hours
   type E_Action is new Pace.Msg with null record;
   procedure Input (Obj : E_Action);
   procedure Input (Obj : E_Action) is
   begin
      Pace.Log.Wait (E_Length);
   end Input;

   -- time at which each test starts
   Begin_Time : Duration;

   procedure Set_Up (T : in out Test_Case) is
      use Pace;
      A : A_Action;
      B : B_Action;
      C : C_Action;
      D : D_Action;
      E : E_Action;
   begin
      for I in 1 .. Jobs'Length loop
         Jobs (I).Unique_Id := S2b (Get_Next_Id_Counter);
         case (I mod 5) is
            when 1 => Jobs (I).Action := +A;
            Jobs (I).Expected_Duration := A_Length;
            when 2 => Jobs (I).Action := +B;
            Jobs (I).Expected_Duration := B_Length;
            when 3 => Jobs (I).Action := +C;
            Jobs (I).Expected_Duration := C_Length;
            when 4 => Jobs (I).Action := +D;
            Jobs (I).Expected_Duration := D_Length;
            when others => Jobs (I).Action := +E;
            Jobs (I).Expected_Duration := E_Length;
         end case;
         Jobs (I).Status := Pending;
      end loop;
      Begin_Time := Pace.Now;
   end Set_Up;

   procedure Tear_Down (T : in out Test_Case) is
   begin
      Pace.Jobs.Restart_Scheduler;
   end Tear_Down;


   procedure No_Job is
   begin
      Assert (not Is_Job_Executing, "There should be no jobs executing yet, but there is a job executing.");
   end No_Job;

   procedure Is_Job is
   begin
      Assert (Is_Job_Executing, "There should be a job executing, but there isn't one.");
   end Is_Job;

   procedure Status_Job (Unique_Id : Bstr.Bounded_String; Status : Job_Status) is
      use Str.Bstr;
      J : Job := Get_Job (Unique_Id);
   begin
      Assert (J.Status = Status, "Expected status of job " & B2s (Unique_Id) & " to be " & Status'Img & ", but was " & J.Status'Img);
   end Status_Job;

   procedure Expect_Job (Unique_Id : Bstr.Bounded_String) is
      use Str.Bstr;
   begin
      Assert (Get_Running_Job.Unique_Id = Unique_Id, "Expected running job to be " & B2s (Unique_Id) & ", but actual running job is " & B2s (Get_Running_Job.Unique_Id));
      Status_Job (Unique_Id, Running);
   end Expect_Job;

   function Get_Start_Time (Wait_Time : Duration) return Duration is
   begin
      return Pace.Now + Wait_Time;
   end Get_Start_Time;

   procedure Test_Normal_Operation (R : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Jobs (1).Start_Time := Get_Start_Time (0.0);
      Jobs (2).Start_Time := Get_Start_Time (41.0);
      Jobs (3).Start_Time := Get_Start_Time (2000.0);
      Jobs (4).Start_Time := Get_Start_Time (3000.0);
      Jobs (5).Start_Time := Get_Start_Time (4000.0);

      Pace.Surrogates.Input (Jobs (1));
      Pace.Surrogates.Input (Jobs (2));
      Pace.Surrogates.Input (Jobs (3));
      Pace.Surrogates.Input (Jobs (4));
      Pace.Surrogates.Input (Jobs (5));

      Pace.Log.Wait_Until (Begin_Time + 1.0);
      Expect_Job (Jobs (1).Unique_Id);

      Pace.Log.Wait_Until (Begin_Time + 40.5);
      No_Job;
      Status_Job (Jobs (1).Unique_Id, Completed);
      Pace.Log.Wait_Until (Begin_Time + 41.1);
      Expect_Job (Jobs (2).Unique_Id);

      Pace.Log.Wait_Until (Begin_Time + 1999.0);
      No_Job;
      Status_Job (S2b ("2"), Completed);
      Pace.Log.Wait_Until (Begin_Time + 2000.1);
      Expect_Job (Jobs (3).Unique_Id);

      Pace.Log.Wait_Until (Begin_Time + 2999.9);
      No_Job;
      Status_Job (Jobs (3).Unique_Id, Completed);
      Pace.Log.Wait_Until (Begin_Time + 3001.0);
      Expect_Job (Jobs (4).Unique_Id);

      Pace.Log.Wait_Until (Begin_Time + 3999.9);
      No_Job;
      Status_Job (Jobs (4).Unique_Id, Completed);
      Pace.Log.Wait_Until (Begin_Time + 4005.1);
      Expect_Job (Jobs (5).Unique_Id);

      Pace.Log.Wait_Until (Begin_Time + 4000.0 + 18000.0 + 1.0);
      Status_Job (Jobs (5).Unique_Id, Completed);
      No_Job;

   end Test_Normal_Operation;

   procedure Test_Cancel (R : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Jobs (1).Start_Time := Get_Start_Time (10.0);
      Jobs (2).Start_Time := Get_Start_Time (41.0);

      Pace.Surrogates.Input (Jobs (1));
      Pace.Surrogates.Input (Jobs (2));

      -- cancel a pending job
      Pace.Log.Wait (1.0);
      Cancel_Job (Jobs (1).Unique_Id);
      Pace.Log.Wait_Until (Begin_Time + 11.0);
      No_Job;

      -- check that canceling a running job does nothing
      Pace.Log.Wait_Until (Begin_Time + 42.0);
      Cancel_Job (Jobs (2).Unique_Id);
      Expect_Job (Jobs (2).Unique_Id);
      Pace.Log.Wait_Until (Begin_Time + 101.1);
      Status_Job (Jobs (2).Unique_Id, Completed);
      No_Job;

   end Test_Cancel;


   procedure Test_Simple_Overlapping (R : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Jobs (1).Start_Time := Get_Start_Time (12.0);
      Jobs (2).Start_Time := Get_Start_Time (10.0);

      Pace.Surrogates.Input (Jobs (1));
      Pace.Surrogates.Input (Jobs (2));

      Pace.Log.Wait_Until (Begin_Time + 10.1);
      Expect_Job (Jobs (2).Unique_Id);
      Status_Job (Jobs (1).Unique_Id, Pending);

      Pace.Log.Wait_Until (Begin_Time + 70.1);
      Expect_Job (Jobs (1).Unique_Id);
      Status_Job (Jobs (2).Unique_Id, Completed);

      Pace.Log.Wait_Until (Begin_Time + 101.0);
      Status_Job (Jobs (1).Unique_Id, Completed);
      No_Job;
   end Test_Simple_Overlapping;

   procedure Test_Same_Start_Time (R : in out AUnit.Test_Cases.Test_Case'Class) is
      use Str.Bstr;
   begin
      Jobs (1).Start_Time := Get_Start_Time (10.0);
      Jobs (2).Start_Time := Jobs (1).Start_Time;

      Pace.Surrogates.Input (Jobs (1));
      Pace.Surrogates.Input (Jobs (2));

      Pace.Log.Wait_Until (Begin_Time + 10.1);

      Is_Job;
      declare
         J : Job := Get_Running_Job;
      begin
         if J.Unique_Id = Jobs (1).Unique_Id then
            Status_Job (Jobs (2).Unique_Id, Pending_Displaced);
            Pace.Log.Wait_Until (Begin_Time + 40.1);
            Status_Job (Jobs (1).Unique_Id, Completed);
            Status_Job (Jobs (2).Unique_Id, Running);
            Pace.Log.Wait_Until (Begin_Time + 101.0);
            Status_Job (Jobs (2).Unique_Id, Completed);
         else
            Status_Job (Jobs (1).Unique_Id, Pending_Displaced);
            Pace.Log.Wait_Until (Begin_Time + 70.1);
            Status_Job (Jobs (2).Unique_Id, Completed);
            Status_Job (Jobs (1).Unique_Id, Running);
            Pace.Log.Wait_Until (Begin_Time + 101.0);
            Status_Job (Jobs (1).Unique_Id, Completed);
         end if;
      end;
      No_Job;
   end Test_Same_Start_Time;

   procedure Test_Clear (R : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      Jobs (1).Start_Time := Get_Start_Time (10.0);
      Jobs (2).Start_Time := Get_Start_Time (41.0);
      Jobs (3).Start_Time := Get_Start_Time (2000.0);
      Jobs (4).Start_Time := Get_Start_Time (3000.0);

      Pace.Surrogates.Input (Jobs (1));
      Pace.Surrogates.Input (Jobs (2));
      Pace.Surrogates.Input (Jobs (3));
      Pace.Surrogates.Input (Jobs (4));

      Pace.Log.Wait_Until (Begin_Time + 1000.0);

      Pace.Jobs.Restart_Scheduler;

      Pace.Log.Wait_Until (Begin_Time + 2001.0);
      No_Job;

      Pace.Log.Wait_Until (Begin_Time + 3001.0);
      No_Job;

   end Test_Clear;

   procedure Test_Copy (R : in out Aunit.Test_Cases.Test_Case'Class) is
      use Job_Set_Pkg;
      use Ada.Containers;
      Set_Copy : Set;
      Iter : Cursor;
      Counter : Integer := 0;
   begin
      Jobs (1).Start_Time := Get_Start_Time (10.0);
      Jobs (2).Start_Time := Get_Start_Time (40.0);
      Pace.Surrogates.Input (Jobs (1));
      Pace.Surrogates.Input (Jobs (2));

      Pace.Log.Wait (1.0);

      Pace.Jobs.Get_Jobs (Set_Copy);

      Jobs (3).Start_Time := Get_Start_Time (100.0);
      Pace.Surrogates.Input (Jobs (3));

      Pace.Log.Wait (1.0);

      Assert (Job_Set_Pkg.Length (Set_Copy) = 2, "Length of copied set should be 2, but is " & Job_Set_Pkg.Length (Set_Copy)'Img);

      Iter := First (Set_Copy);
      while Iter /= No_Element loop
         Counter := Counter + 1;
         Next (Iter);
      end loop;
      Assert (Counter = 2, "Unable to iterate through copied set successfully!  Counter should be 2, but actually is " & Counter'Img);

      Pace.Log.Wait_Until (Begin_Time + 1000.0);
      No_Job;

   end Test_Copy;

   procedure Test_Invalid_Start_Time (R : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      Jobs (1).Start_Time := Get_Start_Time (10.0);
      Pace.Log.Wait (11.0);
      Pace.Surrogates.Input (Jobs (1));
      Pace.Log.Wait (1.0);
      No_Job;
   end Test_Invalid_Start_Time;

   procedure Test_No_Later_Than_Time (R : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      Jobs (1).Start_Time := Get_Start_Time (10.0);
      Jobs (1).No_Later_Than := True;
      Pace.Surrogates.Input (Jobs (1));

      Jobs (2).Start_Time := Get_Start_Time (5.0);
      Pace.Surrogates.Input (Jobs (2));

      Pace.Log.Wait_Until (Begin_Time + 5.1);
      Expect_Job (Jobs (2).Unique_Id);

      Pace.Log.Wait_Until (Begin_Time + 11.0);
      Expect_Job (Jobs (2).Unique_Id);

      Pace.Log.Wait_Until (Begin_Time + 66.0);
      Status_Job (Jobs (2).Unique_Id, Completed);
      No_Job;
      Status_Job (Jobs (1).Unique_Id, Cancelled);
   end Test_No_Later_Than_Time;


   --  Register test routines to call:
   procedure Register_Tests (T : in out Test_Case) is
   begin
      --  Repeat for each test routine.
      Register_Routine (T, Test_Normal_Operation'Access, "Test_Normal_Operation");
      Register_Routine (T, Test_Cancel'Access, "Test_Cancel");
      Register_Routine (T, Test_Simple_Overlapping'Access, "Test_Simple_Overlapping");
      Register_Routine (T, Test_Same_Start_Time'Access, "Test_Same_Start_Time");
      Register_Routine (T, Test_Clear'Access, "Test_Clear");
      Register_Routine (T, Test_Copy'Access, "Test_Copy");
      Register_Routine (T, Test_Invalid_Start_Time'Access, "Test_Invalid_Start_Time");
      Register_Routine (T, Test_No_Later_Than_Time'Access, "Test_No_Later_Than_Time");
   end Register_Tests;

   --  Identifier of test case:
   function Name (T : Test_Case) return String_Access is
   begin
      return  new String'("Uut.Pace_Jobs");
   end Name;

end Uut.Pace_Jobs;
