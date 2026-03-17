with Ada.Numerics.Long_Elementary_Functions;
with Hal.Eq_Solver;

package body PBM.Trajectory is
   use Ada.Numerics.Long_Elementary_Functions;

   G : constant Long_Float := Long_Float (Pbm.Gravity);
   NP : constant Long_Float := 10_000_000.0; -- North Pole Northing, meter definition

   ------------------------
   -- Calculate_Location --
   ------------------------

   procedure Calculate_Location
     (Target   : in out Object;
      Time     : in Duration;
      Isection : in Terrain_Intersection;
      Easting  : out Long_Float;
      Northing : out Long_Float;
      Altitude : out Long_Float;
      Speed    : out Long_Float;
      Landed   : out Boolean;
      Attack   : out Long_Float)
   is
      DT         : Long_Float       := Long_Float (Target.Delta_T);
      Num        : constant Integer :=
         Integer (Long_Float'Floor (Long_Float (Time - Target.Time) / DT));
      T          : Duration         := Target.Time;
      E          : Long_Float       := Target.Easting;
      N          : Long_Float       := Target.Northing;
      U          : Long_Float       := Target.Altitude;
      SE, SN, SU : Long_Float;
      AE, AN, AU : Long_Float := 0.0;
   begin
      SE := Target.Speed * Cos (Target.Elevation) * Sin (Target.Heading);
      SN := Target.Speed * Cos (Target.Elevation) * Cos (Target.Heading);
      SU := Target.Speed * Sin (Target.Elevation);
      for I in  1 .. Num loop
         if I = Num then
            DT := Long_Float (Time - T);
         end if;
         E  := E + SE * DT + 0.5 * AE * DT * DT + abs(NP - N)*Target.Coriolis_Drag;
         N  := N + SN * DT + 0.5 * AN * DT * DT;
         U  := U + SU * DT + 0.5 * AU * DT * DT;
         AE := - abs(Target.Speed * SE) * Target.Air_Drag;
         AN := - abs(Target.Speed * SN) * Target.Air_Drag;
         AU := - abs(Target.Speed * SU) * Target.Air_Drag - G;
         SE := SE + AE * DT;
         SN := SN + AN * DT;
         SU := SU + AU * DT;
         T  := T + Target.Delta_T;
         exit when Isection (E, N, U, SU < 0.0);
      end loop;
      Target.Time     := T;
      Easting         := E;
      Target.Easting  := E;
      Northing        := N;
      Target.Northing := N;
      Altitude        := U;
      Target.Altitude := U;
      if SU = 0.0 then
         Attack := 0.0;
      else
         Attack := Arctan (X => Sqrt (SE * SE + SN * SN), Y => SU);
      end if;
      Target.Elevation := Attack;
      Speed            := Sqrt (SE * SE + SN * SN + SU * SU);
      Target.Speed     := Speed;
      Landed           := Isection (E, N, U, SU<0.0);
   end Calculate_Location;



   --------------------------------------------------------------
   -- Complex Drag-Induced Ballistics -- no coriolis
   --------------------------------------------------------------

   procedure Calculate_Firing_Angle (Theta           : out Long_Float;
                                     Actual_Distance : out Long_Float;
                                     Cycles          : out Integer;
                                     Radial_Distance : in Long_Float;
                                     Altitude_Change : in Long_Float;
                                     Muzzle_Velocity : in Long_Float;
                                     Low_El, High_El : in Long_Float;
                                     Air_Drag        : in Long_Float := 0.0;
                                     Delta_Time      : in Duration := 0.01;
                                     High_Quadrant   : in Boolean    := True;
                                     Accuracy_EPS    : in Long_Float := 0.1) is

      function Impact
         (Easting, Northing, Altitude : Long_Float;
          Falling : Boolean) return Boolean is
      begin
         -- If we can use CTDB here, it would be a bit more accurate?
         -- Otherwise we need to know the altitude of the target
         return Altitude < Altitude_Change;
      end;

      -- Constraint on balllistics trajectory
      procedure Constraint (Theta : in Long_Float; 
                            Dist : out Long_Float) is
         Landed : Boolean;
         Attack : Long_Float := Theta;
         Speed : Long_Float := Muzzle_Velocity;
         Alt : Long_Float := 0.0;
         E : Long_Float := 0.0; -- This is relative
         N : Long_Float := 0.0;
         Time : Duration := 0.0;
         Traj : Object;
      begin
         Dist := 0.0;
         loop
            Traj.Air_Drag := Air_Drag; --.000086;
            Traj.Altitude := Alt;
            Traj.Speed := Speed;
            Traj.Easting :=  E;
            Traj.Northing := N;
            Traj.Heading := 0.0;
            Traj.Elevation := Attack;
            Traj.Time := Time;
            Traj.Delta_T := Delta_Time;
            Time := Time + 1000.0; -- Need loop if this time is not sufficient
            Calculate_Location
              (Target    => Traj,
               Time      => Time,  -- seconds from initial starting
               Isection  => Impact'Unrestricted_Access,
               Easting   => E,  -- absolute
               Northing  => N,  -- absolute
               Altitude  => Alt,
               Speed     => Speed,
               Landed    => Landed,
               Attack    => Attack); -- attack angle in radians
            Dist := Sqrt(E*E + N*N);
            exit when Attack < 0.0 and Landed;
         end loop;
         -- pragma Debug (Text_IO.Put_Line (Landed'Img & Dist'Img & Alt'Img));
      end Constraint;

      -- Typically, 2 solutions will result, use this to pick
      function Condition (Theta, Xm : in Long_Float) return Boolean is
      begin
         if High_Quadrant then
            -- Greater than 45 degrees solution
            return Theta >= Ada.Numerics.Pi / 4.0;
         else
            return Theta <= Ada.Numerics.Pi / 4.0;
         end if;
      end Condition;

      procedure Check is new Hal.Eq_Solver (
         Float_Type => Long_Float,
         X0 => Low_El,
         X1 => High_El,
         Eps => Accuracy_EPS,
         Constraint => Constraint,
         Condition => Condition);
   begin
      Check (Radial_Distance, Theta, Actual_Distance, Cycles);
   end;

end Pbm.Trajectory;
