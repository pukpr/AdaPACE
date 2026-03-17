with Pace.Time_Series;

package Gis.Dead_Reckoning is

   -- Updates state vector to enable calculation of velocity and acceleration

   type WRT_Time is -- WithRespectTo Time derivation values
   record
      DX, DY, DZ         : Float;         -- Position velocities
      DW, DA, DB, DC     : Float;     -- Quaternion velocities
      D2X, D2Y, D2Z      : Float;      -- Position accelerations
      D2W, D2A, D2B, D2C : Float; -- Quaternion accelerations
   end record;

   type State is private;
   
   procedure Update
     (Obj        : in out State;      -- Keeps track of history
      X, Y, Z    : in Float;      -- Position
      W, A, B, C : in Float;      -- Quaternion
      Time       : in Duration := Pace.Now);

   function Current (Obj : State) return WRT_Time;

   -- Call this before every update call (will delay until an absolute time)
   function Advance
     (Time                : Duration;
      Check_Frame_Overrun : Boolean := False)
      return                Duration renames Pace.Time_Series.Advance;

   function Delta_T (Obj : State; Back : Pace.Time_Series.History := 1) return Duration;

   function X (Obj : State) return Float;
   function Y (Obj : State) return Float;
   function Z (Obj : State) return Float;
   function W (Obj : State) return Float;
   function A (Obj : State) return Float;
   function B (Obj : State) return Float;
   function C (Obj : State) return Float;

   Initial : constant State;

   -- Assumes last values of velocity and acceleration 
   function Dead_Reckon_X  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float;
   function Dead_Reckon_Y  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float;
   function Dead_Reckon_Z  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float;
   function Dead_Reckon_W  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float;
   function Dead_Reckon_A  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float;
   function Dead_Reckon_B  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float;
   function Dead_Reckon_C  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float;


   -- Creates a set of parts (Assembly with Assembly_Name) which contain persistent 6DOF state
   --    1. "Set" adds to the set
   --    2. "Synchronize" sets the global 6DOF at the current time
   --    3. "Update" will callback "Render" at the current time based on extrapolation from last synch
   generic
      type Assembly is private;
      type Assembly_Name is private;  -- Must be definite type
      with function To_String (N : Assembly_Name;
                               Append_Nul : Boolean := True) return String;
      
      with procedure Render ( Part       : in Assembly;
                              X, Y, Z    : in Float;    -- Position
                              W, A, B, C : in Float);   -- Quaternion
   package Dead_Reckoner is
      procedure Synchronize ( Part       : in Assembly;
                              Part_Name  : in Assembly_Name;
                              X, Y, Z    : in Float;    -- Position
                              W, A, B, C : in Float);   -- Quaternion
      procedure Update;  -- Calls Render
      procedure Set (Part_Name : in Assembly_Name); -- Adds to database
   end Dead_Reckoner;

private

   use Pace.Time_Series;

   type State is record
      X, Y, Z    : Series;
      W, A, B, C : Series;

      -- Derivatives, i.e. velocity
      DX, DY, DZ     : Series;
      DW, DA, DB, DC : Series;
   end record;

   Initial : constant State  := (Empty, Empty, Empty, Empty, Empty, Empty, Empty, 
                                 Empty, Empty, Empty, Empty, Empty, Empty, Empty);

   -- $Id: gis-dead_reckoning.ads,v 1.4 2005/06/21 17:45:06 pukitepa Exp $
end Gis.Dead_Reckoning;
