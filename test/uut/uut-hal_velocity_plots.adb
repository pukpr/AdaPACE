with Aunit.Test_Cases.Registration;
use Aunit.Test_Cases.Registration;

with Aunit.Assertions;
use Aunit.Assertions;

with Ada.Text_Io;
with Hal.Velocity_Plots;
with Hal.Bounded_Assembly;
with Ada.Containers;

package body Uut.Hal_Velocity_Plots is

   procedure Test_Insert (R : in out Aunit.Test_Cases.Test_Case'Class);

   procedure Test_Insert (R : in out Aunit.Test_Cases.Test_Case'Class) is
      use Hal.Velocity_Plots;
      use Ada.Containers;

      Plot_Data : Velocity_Plot_Data;
      Vel : Velocity_Vector.Vector;
   begin
      Plot_Data.Delta_Time := 0.1;
      for I in 1 .. 10 loop
         Velocity_Vector.Append (Vel, 1.0);
      end loop;
      Plot_Data.Velocities := Vel;
      Add_Plot_Data (Hal.Bounded_Assembly.To_Bounded_String ("testing"),
                     Plot_Data);

      declare
         Assemblies : Assembly_Vector.Vector := Get_Assembly_List;
      begin
         Assert (Assembly_Vector.Length (Assemblies) = 1, "Inserted plot data for 1 assembly.  The size of the assembly list should be 1, but instead it is " & Assembly_Vector.Length (Assemblies)'Img);
      end;

   end Test_Insert;

   --  Register test routines to call:
   procedure Register_Tests (T : in out Test_Case) is
   begin
      --  Repeat for each test routine.
      Register_Routine
        (T, Test_Insert'Access, "Test_Insert");
   end Register_Tests;

   --  Identifier of test case:
   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Uut.Hal_Velocity_Plots");
   end Name;

end Uut.Hal_Velocity_Plots;
