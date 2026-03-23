with Pace.Notify;
with Pace.Log;

with Aunit.Test_Cases.Registration; use Aunit.Test_Cases.Registration;

with Aunit.Assertions; use Aunit.Assertions;

package body Uut.Pace_Notify_Release is

   -----------------------------------------------------------------------------

   type D_Signal is new Pace.Notify.Subscription with null record;

   task No_Ack_Agent is
      entry Start;
   end No_Ack_Agent;
   task body No_Ack_Agent is
      Msg : D_Signal;
   begin
      accept Start;
      Msg.Ack := False;
      Input (Msg);
   end No_Ack_Agent;

   procedure Test_No_Ack (T : in out Aunit.Test_Cases.Test_Case'Class) is
   begin

      Pace.Log.Put_Line ("if it hangs then the test fails...");

      No_Ack_Agent.Start;

      -- wait for the d_signal to be triggered without an ack
      Pace.Log.Wait (2.0);

      declare
         Msg : D_Signal;
      begin
         Inout (Msg);
      end;

      Assert (True, "test passed.  if one of the tasks hangs then test ahs failed!");

   end Test_No_Ack;

   type N1 is new Pace.Notify.Subscription with null record;

   Im_State : Integer := 0;
   task Immediate is
      entry Start;
      entry Onwards;
   end Immediate;
   task body Immediate is
   begin
      Pace.Log.Agent_ID ("immediate");
      accept Start;
      Im_State := 1;

      declare
         Msg : N1;
      begin
         Inout (Msg);
      end;

      Im_State := 2;

      accept Onwards;

      Pace.Log.Wait (1.0);

      declare
         Msg : N1;
      begin
         Inout (Msg);
      end;

      Im_State := 3;

   end Immediate;

   procedure Test_Immediate (T : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      Pace.Log.Put_Line ("doing test immediate");

      -- the test that succeeds (uses immediate)
      declare
         Msg : N1;
      begin
         Msg.Immediate := True;
         Input (Msg);
      end;

      Pace.Log.Put_Line ("past first immediate");

      Immediate.Start;

      Pace.Log.Wait (1.0);

      Assert (Im_State = 1, "Failed. The immediate notify must have entered the queue, because Im_state is not 1.");

      declare
         Msg : N1;
      begin
         Msg.Immediate := True;
         Input (Msg);
      end;

      Pace.Log.Put_Line ("past second notify");

      -- the test that fails (doesn't use immediate)

      Immediate.Onwards;

      declare
         Msg : N1;
      begin
         Input (Msg);
      end;

   end Test_Immediate;

   StateB : Integer := 0;
   task Inout_Noack is
      entry Start;
      entry Onwards;
   end Inout_Noack;
   task body Inout_Noack is
   begin
      Pace.Log.Agent_ID ("inout noack");
      accept Start;
      StateB := 1;

      declare
         Msg : N1;
      begin
         Input (Msg);
      end;

      StateB := 2;

      accept Onwards;

      Pace.Log.wait (1.0);

      declare
         Msg : N1;
      begin
         Input (Msg);
      end;

      StateB := 3;

   end Inout_Noack;

   procedure Test_Inout_Noack (T : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      Pace.Log.Put_Line ("Testing the use of no ack for inout, which is analagous to the immediate for input.");

      -- the test that succeeds (uses immediate)
      declare
         Msg : N1;
      begin
         Msg.Ack := False;
         Inout (Msg);
      end;

      Pace.Log.Put_Line ("past first inout noack");

      Inout_Noack.Start;

      Pace.Log.Wait (1.0);

      Assert (StateB = 1, "Failed. The inout with no ack notify must have entered the queue, because state is not 1.");

      declare
         Msg : N1;
      begin
         Msg.Ack := False;
         Inout (Msg);
      end;

      Pace.Log.Put_Line ("past second notify");

      -- the test that fails has an ack
      Inout_Noack.Onwards;

      declare
         Msg : N1;
      begin
         Inout (Msg);
      end;

   end Test_Inout_Noack;


   type N2 is new Pace.Notify.Subscription with null record;
   task Asynch_Input is
      entry Start;
      entry Done;
   end Asynch_Input;

   task Asynch_Inout is
      entry Start;
      entry Done;
   end Asynch_Inout;

   task body Asynch_Input is
   begin
      Pace.Log.Agent_ID ("asynch input");

      accept Start;

      delay 0.05;
      declare
         Msg : N2;
      begin
         Msg.Ack := False;
         Input (Msg);
      end;

      accept Done;

   end Asynch_Input;

   task body Asynch_Inout is
   begin
      Pace.Log.Agent_ID ("asynch inout");

      accept Start;

      -- simultaneous arrival
      declare
         Msg : N2;
      begin
         Inout (Msg);
      end;

      accept Done;

   end Asynch_Inout;

   procedure Test_Asynchronous_Simultaneous (T : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      Pace.Log.Put_Line ("Test_Asynchronous_Simultaneous ..  if this test does not block then it passes.");
      -- note that this test will fail if:
      -- 1) remove the lock in pace-msg_io Await and Send
      -- 2) a context switch occurs inside the if s.t. both Await and Send
      -- instantiate a mailbox. This can be forced by inserting a delay 1.0 in
      -- the Await  if statement immediately before the mailbox instantiation
      -- input arrives first
      Asynch_Input.Start;
      Asynch_Inout.Start;

      Asynch_Input.Done;
      Asynch_Inout.Done;

      Assert (True, "If this test completes and doesn't block then the test passes.");
      Pace.Log.Put_Line ("Test_Asynchronous_Simultaneous ..  is done and did not block");

   end Test_Asynchronous_Simultaneous;

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Pace_Notify_Release");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Immediate'Access, "Test_Immediate");
      Register_Routine (T, Test_Inout_Noack'Access, "Test_Inout_Noack");
      Register_Routine (T, Test_Asynchronous_Simultaneous'Access, "Test_Asynchronous_Simultaneous");
   end Register_Tests;

   -- $Id: uut-pace_notify_release.adb,v 1.5 2005/08/30 16:38:34 ludwiglj Exp $
end Uut.Pace_Notify_Release;
