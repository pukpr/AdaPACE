package Hal.Motion is

   pragma Elaborate_Body;

   --------------------------------------------
   -- MOTION -- second order motion dynamics
   --------------------------------------------

   type Dynamics is
      record
         X, V, A : Float;    -- distance + velocity + acceleration terms
         Time : Duration;    -- time output
         Complete : Boolean; -- reached (Goal - Thresh)
      end record;

   type Shaper_1 (<>) is private; -- instantiate with Initialize

   function Initialize (Goal : in Float;
                        V_Lim : in Float;  -- Velocity Limit
                        A_Lim : in Float;  -- Acceleration Limit
                        Omega : in Float;  -- Accel "gain" per distance
                        Damp : in Float;   -- Damping on velocity
                        Thresh : in Float; -- Proximity to goal
                        Time : in Duration := 0.0;        -- starting time
                        Iterations : in Integer := 10;    -- sub calculations
                        Deccel_Ratio : in Float := -1.0   -- A_Lim flipped
                        ) return Shaper_1;

   procedure State (Obj : in out Shaper_1;
                    Time : in Duration;  -- current time
                    Value : out Dynamics);

---------

   type Shaper_2 (<>) is private;

   function Initialize
              (The_Max_Velocity : in Float;
               The_Gain : in Float;
               The_Max_Acceleration : in Float;   -- units/sec2 (position units)
               The_Max_Deceleration : in Float;   -- units/sec2 (position units)
               The_Integrator_Gain : in Float;
               The_Integrator_Limit : in Float;
               The_Sample_Delay : in Float) -- seconds
              return Shaper_2;

   -- Resets the shaper algorithm internal state. This should be used
   -- when a amplifier is enabled.
   procedure Reset (This : in out Shaper_2);

   -- Calculates a new commanded velocity. This procedure should 
   -- only be called once per control algorithm update.
   --
   -- Exceptions raised: Constraint_Error -  on algorithm overflow.
   --                    Not_Initialized.
   procedure Update (This : in out Shaper_2; Position_Command : in Float);

   -- Returns the current output of the shaper algorithm.
   -- This procedure can be called multiple times between calls
   -- to Update without affecting the output value.
   -- 
   -- Exceptions raised: Constraint_Error -  on algorithm overflow.
   --                    Not_Initialized.
   procedure Current_Output (This : in Shaper_2;
                             Velocity_Command : out Float;
                             Acceleration_Command : out Float;
                             Closed_Loop : out Boolean);

   -- Returns the position attainable by following the normal
   -- deceleration curve.
   function Soonest_Stop
              (This : Shaper_2; Current_Position : Float) return Float;

   procedure Set_Commanded_Position
               (This : in out Shaper_2; Commanded_Position : in Float);


private


   type Shaper_1 is
      record
         V_Lim : Float;
         A_Lim : Float;
         Omega : Float;
         Damp : Float;
         D_Lim : Float;

         -- End state
         Goal : Float;
         Thresh : Float;

         -- Current values
         Time : Duration;
         X : Float;
         Veloc : Float;
         Accel : Float;

         -- Iteration Accuracy
         Iterations : Integer;

      end record;


   type Shaper_2 is
      record
         Max_Velocity : Float;
         Max_Velocity_Change : Float;
         Gain : Float;
         Max_Acceleration : Float;   -- units/sec2 (position units)
         Max_Deceleration : Float;   -- units/sec2 (position units)
         Integrator_Gain : Float;
         Integrator_Limit : Float;
         Sample_Delay : Float; -- seconds
         Previous_Velocity : Float;
         Previous_Error : Float;
         Previous_Position_Command : Float;
         Previous_Integrator_Value : Float;
         Commanded_Velocity : Float;
         Commanded_Acceleration : Float;
         Commanded_Position : Float;
         Closed_Loop_Status : Boolean;
      end record;

------------------------------------------------------------------------------
-- $version: 2 $
-- $history: Common $
-- $view: /prog/shared/modsim/ctd/ssom/ssom.ss/integ.wrk $
------------------------------------------------------------------------------

end Hal.Motion;
