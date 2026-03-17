with Ada.Numerics.Elementary_Functions;
with Text_IO;

package body Hal.Motion is

   use Ada.Numerics.Elementary_Functions;

   function Initialize
     (Goal         : in Float;
      V_Lim        : in Float;
      A_Lim        : in Float;
      Omega        : in Float;
      Damp         : in Float;
      Thresh       : in Float;
      Time         : in Duration := 0.0;
      Iterations   : in Integer  := 10;
      Deccel_Ratio : in Float    := -1.0)
      return         Shaper_1
   is
   begin
      return
        (V_Lim      => V_Lim,
         A_Lim      => A_Lim,
         Omega      => Omega,
         Damp       => Damp,
         Thresh     => Thresh,
         Goal       => Goal,
         Accel      => 0.0,
         Veloc      => 0.0,
         Time       => Time,
         X          => 0.0,
         Iterations => Iterations,
         D_Lim      => Deccel_Ratio * A_Lim);
   end Initialize;

   procedure State
     (Obj   : in out Shaper_1;
      Time  : in Duration;
      Value : out Dynamics)
   is
      A, V, X, Dt : Float;
      Complete    : Boolean := False;
   begin  -- a := omega * (goal - x - damp*v)

      Dt := Float (Time - Obj.Time) / Float (Obj.Iterations);

      for I in  1 .. Obj.Iterations loop
         A := Obj.Omega * (Obj.Goal - Obj.X - Obj.Damp * Obj.Veloc);
         if A > Obj.A_Lim then
            A := Obj.A_Lim;
         elsif A < Obj.D_Lim then
            A := Obj.D_Lim;
         end if;

         V := Obj.Veloc + A * Dt;
         if V > Obj.V_Lim then
            V := Obj.V_Lim;
         elsif V <= -Obj.V_Lim then -- this should not happen
            V := -Obj.V_Lim;
         end if;

         X := Obj.X + 0.5 * (Obj.Veloc + V) * Dt;

         Obj.X     := X;
         Obj.Veloc := V;
         Obj.Accel := A;
         if X > Obj.Goal - Obj.Thresh then
            Complete := True;
            Obj.Time := Time - Duration (Float (Obj.Iterations - I) * Dt);
            exit;
         end if;
      end loop;
      if not Complete then
         Obj.Time := Time;
      end if;
      Value :=
        (X        => Obj.X,
         V        => Obj.Veloc,
         A        => Obj.Accel,
         Time     => Obj.Time,
         Complete => Complete);
   end State;

   ----------------------------------------------------------------------------
   ---
   -- This algorithm is taken from the control algorithm developed
   -- inside MatrixX by the controls engineers. See the notes
   -- in the SDF.
   ----------------------------------------------------------------------------
   ---

   function Beta (This : Shaper_2) return Float is
   begin
      return This.Max_Deceleration / (This.Gain ** 2);
   end Beta;

   procedure Update (This : in out Shaper_2; Position_Command : in Float) is

      Velocity_Change  : Float;  -- Delta velocity between samples
      Velocity         : Float;           -- Temporary variable to hold
                                          --calculated velocity
      Next_Velocity    : Float;     -- Temporary estimate of next velocity
                                    --command
      Acceleration     : Float;     -- Temporary variable to hold acceleration
                                    --command
      Integrator_Value : Float; -- Temporary value of integrator
      Position_Error   : Float;
      Target_Velocity  : Float;

   begin -- Update
      Target_Velocity := This.Commanded_Velocity;
      Position_Error  := This.Commanded_Position - Position_Command;

      if (abs Position_Error) >= Beta (This) then

         Velocity :=
           Sqrt
                (2.0 *
                 This.Max_Deceleration *
                 (abs (Position_Error) - (Beta (This) / 2.0))) +
           Target_Velocity;

         Next_Velocity := 2.0 *
                          This.Max_Deceleration *
                          (abs (Position_Error) -
                           (Velocity * This.Sample_Delay) -
                           (Beta (This) / 2.0));

         if Next_Velocity > 0.0 then     -- Next step is parabolic

            Next_Velocity := Sqrt (Next_Velocity) + Target_Velocity;

            Acceleration :=
              Float'Copy_Sign (1.0, Position_Error) *
              Float'Copy_Sign (1.0, (Next_Velocity - Velocity)) *
              This.Max_Deceleration *
              abs (Position_Error - This.Previous_Error) /
              This.Sample_Delay /
              (Velocity - Target_Velocity);

         else
            Acceleration := 0.0;
         end if;

         Velocity := Float'Copy_Sign (1.0, Position_Error) * Velocity;

         Integrator_Value := 0.0;

         This.Closed_Loop_Status := False;

      elsif abs (Position_Error) >= 0.0 then

         -- compute integrator and anti-windup

         Integrator_Value := This.Previous_Integrator_Value +
                             This.Integrator_Gain *
                             This.Sample_Delay *
                             (This.Previous_Error + Position_Error) /
                             2.0;

         if abs Integrator_Value > This.Integrator_Limit then
            Integrator_Value := Float'Copy_Sign (1.0, Integrator_Value) *
                                This.Integrator_Limit;
         end if;

         -- compute command

         Velocity :=
           Float'Copy_Sign (1.0, Position_Error) *
           (This.Gain * (abs Position_Error) + Target_Velocity) +
           Integrator_Value;

         Acceleration            := 0.0;
         This.Closed_Loop_Status := True;

      else
         Velocity                :=
            Float'Min (Target_Velocity, This.Gain * (abs Position_Error));
         Acceleration            := 0.0;
         Integrator_Value        := 0.0;
         Velocity                := Float'Copy_Sign (1.0, Position_Error) *
                                    Velocity;
         This.Closed_Loop_Status := True;
      end if;

      if abs Velocity > This.Max_Velocity then
         Velocity     := This.Max_Velocity * Float'Copy_Sign (1.0, Velocity);
         Acceleration := 0.0;
      end if;

      -- Limit acceleration during first part of trajectory
      Velocity_Change := Velocity - This.Previous_Velocity;
      if abs Velocity_Change > This.Max_Velocity_Change and
         Velocity_Change * Position_Error > 0.0
      then
         Velocity     := This.Previous_Velocity +
                         This.Max_Velocity_Change *
                         Float'Copy_Sign (1.0, Velocity_Change);
         Acceleration := Float'Copy_Sign (1.0, Velocity_Change) *
                         This.Max_Acceleration;

         -- Check for Trapezoid
         if abs (Velocity + Acceleration * This.Sample_Delay) >
            This.Max_Velocity
         then

            Acceleration :=
              Float'Copy_Sign (1.0, Acceleration) *
              (This.Max_Velocity - abs (Velocity)) /
              This.Sample_Delay;

         else -- Triangular switch check
            Next_Velocity := 2.0 *
                             This.Max_Deceleration *
                             (abs Position_Error -
                              abs Velocity * This.Sample_Delay -
                              Beta (This) / 2.0);

            if Next_Velocity > 0.0 then     -- Next step is parabolic

               Next_Velocity := Sqrt (Next_Velocity) + Target_Velocity;

               -- if abs (Next_Velocity) - abs (Velocity) <
               --  This.Max_Acceleration * This.Sample_Delay then
               if abs (Float'Copy_Sign (1.0, Position_Error) *
                       Next_Velocity -
                       Velocity) <
                  This.Max_Velocity_Change
               then

                  Acceleration :=
                    Float'Copy_Sign
                         (1.0,
                          Next_Velocity *
                          Float'Copy_Sign (1.0, Position_Error) -
                          Velocity) *
                    abs (Next_Velocity - abs (Velocity)) /
                    This.Sample_Delay;

               end if;

            end if;

         end if;

      end if;

      -- Check for position command change during profile
      if Position_Command /= This.Previous_Position_Command then
         if abs This.Previous_Velocity > 0.05 * This.Max_Velocity then
            Acceleration := 0.0;
         end if;
      end if;

      -- compute final output
      This.Commanded_Velocity     := Velocity;
      This.Commanded_Acceleration := Acceleration;

      -- setup for next iteration
      This.Previous_Velocity         := This.Commanded_Velocity;
      This.Previous_Error            := Position_Error;
      This.Previous_Position_Command := Position_Command;
      This.Previous_Integrator_Value := Integrator_Value;

   end Update;

   function Initialize
     (The_Max_Velocity     : in Float;
      The_Gain             : in Float;
      The_Max_Acceleration : in Float;
      The_Max_Deceleration : in Float;
      The_Integrator_Gain  : in Float;
      The_Integrator_Limit : in Float;
      The_Sample_Delay     : in Float)
      return                 Shaper_2
   is
   begin
      return
        (Max_Velocity              => The_Max_Velocity,
         Max_Velocity_Change       => The_Max_Acceleration *
                                      The_Sample_Delay,
         Gain                      => The_Gain,
         Max_Acceleration          => The_Max_Acceleration,
         Max_Deceleration          => The_Max_Deceleration,
         Integrator_Gain           => The_Integrator_Gain,
         Integrator_Limit          => The_Integrator_Limit,
         Sample_Delay              => The_Sample_Delay,
         Previous_Velocity         => 0.0,
         Previous_Error            => 0.0,
         Previous_Position_Command => 0.0,
         Previous_Integrator_Value => 0.0,
         Commanded_Velocity        => 0.0,
         Commanded_Acceleration    => 0.0,
         Commanded_Position        => 0.0,
         Closed_Loop_Status        => False);

   end Initialize;

   procedure Reset (This : in out Shaper_2) is
   begin
      This.Previous_Velocity         := 0.0;
      This.Previous_Error            := 0.0;
      This.Previous_Position_Command := 0.0;
      This.Previous_Integrator_Value := 0.0;
   end Reset;

   procedure Current_Output
     (This                 : in Shaper_2;
      Velocity_Command     : out Float;
      Acceleration_Command : out Float;
      Closed_Loop          : out Boolean)
   is
   begin
      Velocity_Command     := This.Commanded_Velocity;
      Acceleration_Command := This.Commanded_Acceleration;
      Closed_Loop          := This.Closed_Loop_Status;
   end Current_Output;

   function Soonest_Stop
     (This             : Shaper_2;
      Current_Position : Float)
      return             Float
   is
      Delta_Position : Float;
   begin
      if (abs This.Previous_Velocity) <= Beta (This) * This.Gain then
         Delta_Position := This.Previous_Velocity / This.Gain;
      else
         Delta_Position := Float'Copy_Sign (1.0, This.Previous_Velocity) *
                           (This.Previous_Velocity ** 2 /
                            (2.0 * This.Max_Deceleration) +
                            (Beta (This) / 2.0));
      end if;
      return Current_Position + Delta_Position;
   end Soonest_Stop;

   procedure Set_Commanded_Position
     (This               : in out Shaper_2;
      Commanded_Position : in Float)
   is
   begin
      This.Commanded_Position := Commanded_Position;
   end Set_Commanded_Position;

end Hal.Motion;
