

package body Hal.Generic_State_Machine is

   State : State_Name := Start_State;

   function Current return State_Name is
   begin -- Current
      return State;
   end Current;


   procedure Reset is
   begin -- Reset
      State := Start_State;
   end Reset;


   procedure Update is
   begin -- Update
      if State /= State_Name'Last then
         State := State_Name'Succ (State);
      elsif Circular then
         Reset;
      end if;
   end Update;


   procedure Set (New_State : in State_Name) is
   begin -- Set
      State := New_State;
   end Set;


   function Is_Reset return Boolean is
   begin -- Is_Reset
      return State = Start_State;
   end Is_Reset;


   function Is_Done return Boolean is
   begin -- Is_Done
      return State = Done_State;
   end Is_Done;

   function State_Machine_Name return String is
   begin
      return Machine_Name;
   end State_Machine_Name;


end Hal.Generic_State_Machine;
