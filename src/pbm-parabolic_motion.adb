with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics;
with Pace.Log;
with Hal.Eq_Solver;

package body Pbm.Parabolic_Motion is

   use Ada.Numerics.Elementary_Functions;
   use Ada.Numerics;
   use Hal;

   procedure Calculate_Location (Theta : in Float; Initial_Velocity : in Float;
                                 Time : in Duration;
                                 Delta_Vertical : out Float; Delta_Horizontal : out Float;
                                 Tangent_Angle : out Float) is
   begin
      Delta_Horizontal := Initial_Velocity * Cos (Theta) * Float (Time);
      Delta_Vertical := Initial_Velocity * Sin (Theta) * Float (Time) - 0.5 * Gravity * Float (Time) * Float (Time);
      if Cos (Theta) /= 0.0 then
         -- this equals arctan ( vertical_velocity at time t / initial horizontal velocity )
         Tangent_Angle := -Arctan ((Initial_Velocity * Sin (Theta) - Gravity * Float (Time)) /
                                   (Initial_Velocity * Cos (Theta)));
      else
         Tangent_Angle := -Pi / 2.0;
      end if;
   end Calculate_Location;

   procedure Calculate_Velocity (Theta : in Float;
                                 Source_X : in Float;
                                 Source_Y : in Float;
                                 Destination_Radius : in Float;
                                 Destination_Phi : in Float;
                                 Initial_Velocity : out Float) is
      Destination_X : Float := Destination_Radius * Cos (Destination_Phi) + Source_X;
      Destination_Y : Float := Destination_Radius * Sin (Destination_Phi) + Source_Y;
      Distance : Float := Sqrt ((Source_X - Destination_X) * (Source_X - Destination_X) +
                                (Source_Y - Destination_Y) * (Source_Y - Destination_Y));

   begin
      if Theta > 0.0 then -- guarding against divide by zero or sqrt of negative
         if Distance < 0.0 then
            Pace.Log.Put_Line ("distance is less than zero!");
         end if;
         Initial_Velocity := Sqrt ((Gravity * Distance) / Sin (2.0 * Theta));
      else
         Pace.Log.Put_Line ("theta is less than or equal to zero!");
         Initial_Velocity := 0.0;
      end if;
   exception
      when E : Argument_Error =>
         Pace.Log.Put_Line ("argument error!! probably negative in sqrt!");
   end Calculate_Velocity;

   function Time_In_Air
              (Distance : in Float; Angle : in Float; Velocity : in Float)
              return Float is
   begin
      return Distance / (Cos (Angle) * Velocity);
   end Time_In_Air;

   function Total_Time_In_Air (Angle : in Float;
                               Velocity : in Float;
                               Vertical_Distance : in Float) return Float is
   begin
      Pace.Log.Put_Line
                      ("velocity is " & Float'Image (Velocity) &
                       " and angle is " & Float'Image (Angle) &
                       " and vert_dist is " & Float'Image (Vertical_Distance), 9);
      return ((Velocity * Sin (Angle) +
               Sqrt (Velocity * Velocity * Sin (Angle) * Sin (Angle) -
                     2.0 * Gravity * Vertical_Distance)) / Gravity);
   exception
      when E: Ada.Numerics.Argument_Error =>
         Pace.Log.Put_Line
           ("Argument Error thrown inside Total_Time_In_Air.  Sqrt of a negative number.  The angle of the gun is not high enough to hit the target.");
         raise Bad_Elevation_Angle;
   end Total_Time_In_Air;

   function Distance_Traveled
              (Angle : in Float; Velocity : in Float; Time : in Float)
              return Float is
   begin
      return Cos (Angle) * Velocity * Time;
   end Distance_Traveled;

   function Initial_Velocity
              (Angle : in Float; Distance : in Float) return Float is
   begin
      return Sqrt ((Gravity * Distance) / Sin (2.0 * Angle));
   end Initial_Velocity;

   function Initial_Velocity (Angle : in Float;
                              Horizontal_Distance : in Float;
                              Vertical_Distance : in Float) return Float is
   begin
      Pace.Log.Put_Line ("inside init velocity... angle is " & Angle'Img & " and hor dist is " & Horizontal_Distance'Img & " and vert dist is " & Vertical_Distance'Img, 9);
      return (Sqrt (Gravity * Horizontal_Distance * Horizontal_Distance /
                    (2.0 * Cos (Angle) * Cos (Angle) *
                     (Horizontal_Distance * Tan (Angle) - Vertical_Distance))));
   exception
      when E: Ada.Numerics.Argument_Error =>
         Pace.Log.Put_Line
           ("Argument Error thrown inside Initial_Velocity.  Sqrt of a negative number.  The angle of the gun is not high enough to hit the target.");
         raise Bad_Elevation_Angle;
   end Initial_Velocity;


   procedure Calculate_Firing_Angle
     (Theta           : out Float;
      Actual_Change   : out Float;
      Cycles          : out Integer;
      Radial_Distance : in Float;
      Altitude_Change : in Float;
      Muzzle_Velocity : in Float;
      Low_El, High_El : in Float;
      High_Quadrant   : in Boolean := True;
      Accuracy_EPS    : in Float   := 0.1) is

      subtype LFloat is Long_Float;

      -- Typically, 2 solutions will result, use this to pick
      function Condition (Theta, Xm : in LFloat) return Boolean is
      begin
         if High_Quadrant then
            -- Greater than 45 degrees solution
            return Theta >= Ada.Numerics.Pi / 4.0;
         else
            return Theta <= Ada.Numerics.Pi / 4.0;
         end if;
      end Condition;

      procedure Constraint (Theta : in LFloat; Ym : out LFloat) is
         use Ada.Numerics.Long_Elementary_Functions;
         VX : constant LFloat := LFloat(Muzzle_Velocity) * Cos (Theta);
         RD : constant LFloat := LFloat(Radial_Distance);
      begin
         Ym := RD * Tan (Theta) - LFloat(Gravity) * (RD*RD/2.0)/VX/VX;
      end Constraint;

      procedure Check is new Hal.Eq_Solver (
         Float_Type => LFloat,
         X0 => LFloat(Low_El),
         X1 => LFloat(High_El),
         Eps => LFloat(Accuracy_EPS),
         Constraint => Constraint,
         Condition => Condition);

   begin
      Check (LFloat(Altitude_Change), LFloat(Theta),
             LFloat(Actual_Change), Cycles);
   end;

   procedure Elevation_Calculation (Initial_Velocity : in Float;
                                    Horizontal_Distance : in Float;
                                    Vertical_Distance : in Float;
                                    Success : out Boolean;
                                    Elevation : out Float;
                                    Low_El : in Float := 0.0;
                                    High_El : in Float := Ada.Numerics.Pi / 2.0;
                                    Accuracy_Eps : in Float := 0.1; -- precision on theta radians
                                    Vertical_Tolerance : in Float := 10.0;
                                    High_Quadrant : in Boolean := True) is

      Cycles : Integer;
      Actual_Change : Float;

   begin
      Pace.Log.Put_Line ("calling iterative solver with velocity " & Initial_Velocity'Img & " and hdist " & Horizontal_Distance'Img & " and vdist " & Vertical_Distance'Img & " and high_quad " & High_Quadrant'Img, 9);
      Calculate_Firing_Angle (
         Theta            => Elevation,
         Actual_Change    => Actual_Change,
         Cycles           => Cycles,
         Radial_Distance  => Horizontal_Distance,
         Altitude_Change  => Vertical_Distance,
         Muzzle_Velocity  => Initial_Velocity,
         Low_El           => Low_El,
         High_El          => High_El,
         High_Quadrant    => High_Quadrant,
         Accuracy_Eps     => Accuracy_Eps
         );

      Pace.Log.Put_Line ("Parabolic iteration cycles" & Cycles'Img &
                         " Actual" & Actual_Change'Img &
                         " Vertical" & Vertical_Distance'Img, 9);
      Success := abs (Vertical_Distance - Actual_Change) < Vertical_Tolerance;
   exception
      when E: Ada.Numerics.Argument_Error =>
         Success := False;
         Elevation := 0.0;
   end Elevation_Calculation;



   function Get_Horizontal_Distance (Target_Easting, Target_Northing, Source_Easting, Source_Northing : Float) return Float is
      Delta_A, Delta_B : Float;
   begin
      Delta_A := abs (Target_Northing - Source_Northing);
      Delta_B := abs (Target_Easting - Source_Easting);
      return (Sqrt (Delta_A * Delta_A + Delta_B * Delta_B));
   end Get_Horizontal_Distance;

end Pbm.Parabolic_Motion;
