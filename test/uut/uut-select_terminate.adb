with Ada.Text_Io;
with Pace.Log;

with Aunit.Test_Cases.Registration; use Aunit.Test_Cases.Registration;

with Aunit.Assertions; use Aunit.Assertions;

package body Uut.Select_Terminate is

   function Id is new Pace.Log.Unit_Id;

   task B is
      entry Do_It;
      entry Do_More;
   end B;

   task body B is
   begin
      Pace.Log.Agent_Id (Id & "B");
      loop
         select
            accept Do_It do
               null;
            end Do_It;
         or
            accept Do_More do
               null;
            end Do_More;
         or
            terminate;
         end select;

      end loop;
   exception
      when E: others =>
         Ada.Text_Io.Put_Line ("Caught Exception!");
   end B;

   task A is
      entry Start;
   end A;

   Counter : Integer := 0;

   task body A is
   begin
      Pace.Log.Agent_Id (Id & "A");
      accept Start;
      Counter := Counter + 1;
      B.Do_It;
      Counter := Counter + 1;
      B.Do_It;
      Counter := Counter + 1;
      B.Do_It;
      Counter := Counter + 1;

   exception
      when E: others =>
         Ada.Text_Io.Put_Line ("Caught Exception!");
   end A;

   procedure Test_Select_Terminate (T : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      A.Start;
      for I in 1 .. 10 loop
         Pace.Log.Wait (0.25);
         Assert (Counter = 4, "Expected counter to be 4 but actually is " & Counter'Img & ".  Select with terminate operation has failed.");
      end loop;
   end Test_Select_Terminate;

   -- Name --
   ----------

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Select_Terminate");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T,
                        Test_Select_Terminate'Access,
                        "Test_Select_Terminate");
   end Register_Tests;

end Uut.Select_Terminate;
