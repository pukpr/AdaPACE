with Pace.Log;
with Pace.Socket.Publisher;

with Aunit.Test_Cases.Registration; use Aunit.Test_Cases.Registration;
with Aunit.Assertions; use Aunit.Assertions;
package body Uut.Pubs is 

   type Status is new Pace.Msg with
      record
         Data : Integer := 1;
      end record;
      
   procedure Input (Obj : in Status);


   type My_Status1 is new Status with null record;
   procedure Input (Obj : in My_Status1);

   type My_Status2 is new Status with null record;
   procedure Input (Obj : in My_Status2);

   type My_Status3 is new Status with null record;
   procedure Input (Obj : in My_Status3);

   function Passed return Boolean;

   task Agent is
      pragma Task_Name (Pace.Log.Name);
      entry Start;
   end Agent;
   
   List : Pace.Socket.Publisher.Subscription_List (10);
   Loops : constant := 100;
   Amount : Integer := 0;

   protected Sync is
      entry Wait_Complete;
      procedure Signal_Complete;
   private
      Completed : Boolean := False;
   end Sync;

   protected body Sync is
      entry Wait_Complete when Completed is
      begin
         null;
      end Wait_Complete;
      procedure Signal_Complete is
      begin
         Completed := True;
      end Signal_Complete;
   end Sync;
   
   task body Agent is
      Local_Status : Status;
   begin
      Pace.Log.Agent_ID (Pace.Log.Name);
      accept Start;
      for I in 1..Loops loop
         -- delay 0.1;
         Local_Status.Data := I;
         Pace.Socket.Publisher.Publish (List, Local_Status);
      end loop;
   end Agent;

   procedure Input (Obj : in Status) is
   begin
      Pace.Socket.Publisher.Subscribe (List, Obj);
   end;

   procedure Input (Obj : in My_Status1) is
   begin
      Pace.Log.Put_Line ("1" & Obj.Data'Img, 9);
   end;

   procedure Input (Obj : in My_Status2) is
   begin
      Pace.Log.Put_Line ("2" & Obj.Data'Img, 9);
   end;

   procedure Input (Obj : in My_Status3) is
   begin
      Pace.Log.Put_Line ("3" & Obj.Data'Img, 9);
      Amount := Obj.Data;
      if Amount = Loops then
         Sync.Signal_Complete;
      end if;
   end;

   function Passed return Boolean is
   begin
      return Loops = Amount;
   end;

   procedure Test_Pubsub (T : in out Aunit.Test_Cases.Test_Case'Class) is
      M0 : status;
      M1 : My_Status1;
      M2 : My_Status2;
      M3 : My_Status3;
      Check : Boolean;
   begin
      Pace.Log.Put_Line ("Test_Pubs .. if this test updates to 100 it passes.");
      
      -- Subscribe FIRST to avoid race condition
      Input (Status(M1));
      Input (Status(M2));
      Input (Status(M3));

      Agent.Start;
      
      -- Wait for completion instead of delay
      Sync.Wait_Complete;
      
      Check := Passed;

      Assert (Check, "If this test fails, likely the dispatching didn't work.");

   end Test_Pubsub;

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Pace_Pubs");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Pubsub'Access, "Test_Pubsub");
   end Register_Tests;

end;
