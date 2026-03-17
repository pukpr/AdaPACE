

generic
   Machine_Name : in String;
   type State_Name is (<>);
   Start_State : in State_Name := State_Name'First;
   Done_State : in State_Name := State_Name'Last;
   Circular : in Boolean := False;

package Hal.Generic_State_Machine is

   ----------------------------------------------------------------------------
   -- Returns the current state of the state machine.
   --
   function Current return State_Name;

   ----------------------------------------------------------------------------
   -- Resets the current state of the state machine to the Start State.
   --
   procedure Reset;

   ----------------------------------------------------------------------------
   -- Sets the state of the state machine to the next sequential state.
   -- For non-circular state machines, if the current state is the last state,
   -- no action is taken.
   -- For circular state machines, if the current state is the last state, 
   -- a Reset is performed.
   --
   procedure Update;

   ----------------------------------------------------------------------------
   -- Sets the current state to the requested New_State.
   --
   procedure Set (New_State : in State_Name);

   ----------------------------------------------------------------------------
   -- Determines if the current is equal to the Start State (i.e. Reset).
   --
   function Is_Reset return Boolean;

   ----------------------------------------------------------------------------
   -- Determines if the current state is equal to the Done State.
   --
   function Is_Done return Boolean;

   ----------------------------------------------------------------------------
   -- Returns the name of the state machine
   --
   function State_Machine_Name return String;


end Hal.Generic_State_Machine;

