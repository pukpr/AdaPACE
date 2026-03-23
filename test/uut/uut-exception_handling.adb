with Ada.Text_Io;

with Aunit.Test_Cases.Registration; use Aunit.Test_Cases.Registration;

with Aunit.Assertions; use Aunit.Assertions;

with Pace.Log;

package body Uut.Exception_Handling is

   function Id is new Pace.Log.Unit_Id;

   Caught_Constraint_Error : Boolean := False;
   Caught_Manual_Raise : Boolean := False;

   type Greetings is (Hi, Bye);

   task Agent is
      entry Do_Dynamic_Constraint_Error;
      entry Do_Manual_Raise;
   end Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         select

            accept Do_Dynamic_Constraint_Error do
               declare
                  Greet : Greetings;
                  S : String := "hello";
               begin
                  Greet := Greetings'Value (S);
                  Ada.Text_Io.Put_Line ("shouldn't see this!");
               exception
                  when E : Constraint_Error =>
                     Caught_Constraint_Error := True;
               end;
            end Do_Dynamic_Constraint_Error;

         or

            accept Do_Manual_Raise do
               declare
               begin
                  raise Constraint_Error;
               exception
                  when E : Constraint_Error =>
                     Caught_Manual_Raise := True;
               end;
            end Do_Manual_Raise;

         end select;
      end loop;

   exception
      when E : others =>
         Ada.Text_Io.Put_Line ("In final exception block!");
         Assert (False, "Reached the final exception block of the agent which should not happen!");
   end Agent;

   procedure Test_Dynamic_Constraint_Error (T : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      Agent.Do_Dynamic_Constraint_Error;
      Assert (Caught_Constraint_Error, "Did not catch constraint_error as expected!");
   end Test_Dynamic_Constraint_Error;

   procedure Test_Manual_Raise (T : in out Aunit.Test_Cases.Test_Case'Class) is
   begin
      Agent.Do_Manual_Raise;
      Assert (Caught_Manual_Raise, "Did not catch the manually raised exception as expected!");
   end Test_Manual_Raise;

   -- Name --
   ----------

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Exception_Handling");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T,
                        Test_Dynamic_Constraint_Error'Access,
                        "Test_Dynamic_Constraint_Error");
      Register_Routine (T,
                        Test_Manual_Raise'Access,
                        "Test_Manual_Raise");
   end Register_Tests;

end Uut.Exception_Handling;
