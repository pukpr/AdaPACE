with Ada.Numerics.Elementary_Functions;
with Sal.Gen_Math.Gen_Dof_3;
with Sal.Gen_Math.Gen_Scalar;
with Ada.Text_Io;

package body Hal.Rotations is

   use Ada.Numerics.Elementary_Functions;


   -- transposes a Rotation_Matrix
   function Transpose (M : Rotation_Matrix) return Rotation_Matrix is
      M_Transpose : Rotation_Matrix := (X => (M (X, A), M (Y, A), M (Z, A)),
                                        Y => (M (X, B), M (Y, B), M (Z, B)),
                                        Z => (M (X, C), M (Y, C), M (Z, C)));
   begin
      return M_Transpose;
   end Transpose;

   function Multiply (P : in Position; M : in Rotation_Matrix)
                     return Position is
      Rp : Position;
   begin
      Rp.X := P.X * M (X, A) + P.Y * M (X, B) + P.Z * M (X, C);
      Rp.Y := P.X * M (Y, A) + P.Y * M (Y, B) + P.Z * M (Y, C);
      Rp.Z := P.X * M (Z, A) + P.Y * M (Z, B) + P.Z * M (Z, C);
      return Rp;
   end Multiply;

   function Multiply (R : in Orientation; M : in Rotation_Matrix)
                      return Orientation is
      Result : Orientation;
   begin
      Result.A := R.A * M (X, A) + R.B * M (X, B) + R.C * M (X, C);
      Result.B := R.A * M (Y, A) + R.B * M (Y, B) + R.C * M (Y, C);
      Result.C := R.A * M (Z, A) + R.B * M (Z, B) + R.C * M (Z, C);
      return Result;
   end Multiply;

   function Multiply (M : Rotation_Matrix;
                      N : Rotation_Matrix) return Rotation_Matrix is
      Result : Rotation_Matrix := (X => (M(X,A)*N(X,A) + M(X,B)*N(Y,A) + M(X,C)*N(Z,A),
                                         M(X,A)*N(X,B) + M(X,B)*N(Y,B) + M(X,C)*N(Z,B),
                                         M(X,A)*N(X,C) + M(X,B)*N(Y,C) + M(X,C)*N(Z,C)),
                                   Y => (M(Y,A)*N(X,A) + M(Y,B)*N(Y,A) + M(Y,C)*N(Z,A),
                                         M(Y,A)*N(X,B) + M(Y,B)*N(Y,B) + M(Y,C)*N(Z,B),
                                         M(Y,A)*N(X,C) + M(Y,B)*N(Y,C) + M(Y,C)*N(Z,C)),
                                   Z => (M(Z,A)*N(X,A) + M(Z,B)*N(Y,A) + M(Z,C)*N(Z,A),
                                         M(Z,A)*N(X,B) + M(Z,B)*N(Y,B) + M(Z,C)*N(Z,B),
                                         M(Z,A)*N(X,C) + M(Z,B)*N(Y,C) + M(Z,C)*N(Z,C)));


   begin
      return Result;
   end Multiply;

   function Rx (Theta : in Float) return Rotation_Matrix is  -- Roll
      R : Rotation_Matrix := (X => (1.0, 0.0, 0.0),
                              Y => (0.0, Cos (Theta), -Sin (Theta)),
                              Z => (0.0, Sin (Theta), Cos (Theta)));
   begin
      return R;
   end Rx;

   function Ry (Theta : in Float) return Rotation_Matrix is   -- Pitch
      R : Rotation_Matrix := (X => (Cos (Theta), 0.0, Sin (Theta)),
                              Y => (0.0, 1.0, 0.0),
                              Z => (-Sin (Theta), 0.0, Cos (Theta)));
   begin
      return R;
   end Ry;

   function Rz (Theta : in Float) return Rotation_Matrix is  -- Yaw
      R : Rotation_Matrix := (X => (Cos (Theta), -Sin (Theta), 0.0),
                              Y => (Sin (Theta), Cos (Theta), 0.0),
                              Z => (0.0, 0.0, 1.0));
   begin
      return R;
   end Rz;

   function Rx (P : in Position; A : in Float; Invert : in Boolean := False) return Position is
      R : Rotation_Matrix := Rx (A);
   begin
      if Invert then
         R := Transpose (R);
      end if;
      return Multiply (P, R);
   end Rx;

   function Ry (P : in Position; B : in Float; Invert : in Boolean := False) return Position is
      R : Rotation_Matrix := Ry (B);
   begin
      if Invert then
         R := Transpose (R);
      end if;
      return Multiply (P, R);
   end Ry;

   function Rz (P : in Position; C : in Float; Invert : in Boolean := False) return Position is
      R : Rotation_Matrix := Rz (C);
   begin
      if Invert then
         R := Transpose (R);
      end if;
      return Multiply (P, R);
   end Rz;

   function Rn (P : in Position; 
                R : in Orientation; 
                E : in Euler_Index;
                Invert : in Boolean := False) return Position is
   begin
      case E is
         when A =>
            return Rx (P, R.A, Invert);
         when B =>
            return Ry (P, R.B, Invert);
         when C =>
            return Rz (P, R.C, Invert);
      end case;
   end Rn;

--    function R3_Fixed (P : in Position; 
--                         R : in Orientation; 
--                         Invert : Boolean := False;
--                         Order : in Rotation_Order := Default_Order ) return Position is
--    begin
--       -- can't just pass invert boolean along since there is a different order...
--       if Invert then
--          return Ry (Rx (Rz (P, R.C, True), R.A, True), R.B, True);
--       else
--          return Rz (Ry (Rx (P, R.A), R.B), R.C);
--       end if;
--    end R3_Fixed;

   function R3_Terrain (P : in Position; 
                        R : in Orientation; 
                        Invert : Boolean := False;
                        Order : in Rotation_Order := Default_Order ) return Position is
   begin
      -- can't just pass invert boolean along since there is a different order...
      if Invert then
         return Rn (Rn (Rn (P, R, Order(3), True), R, Order(2), True), R, Order(1), True);
      else
         return Rn (Rn (Rn (P, R, Order(1),False), R, Order(2),False), R, Order(3),False);
      end if;
   end R3_Terrain;

   function Convert_Vector (In_Vec : Position;
                            First : Rotation_Matrix;
                            Second : Rotation_Matrix;
                            Third : Rotation_Matrix) return Position is
      Vec1 : Position := Multiply (In_Vec, First);
      Vec2 : Position := Multiply (Vec1, Second);
      Vec3 : Position := Multiply (Vec2, Third);
   begin
      --Ada.Text_Io.Put_Line ("In_Vec = " & To_Str (In_Vec));
      --Ada.Text_Io.Put_Line ("Vec1 = " & To_Str (Vec1));
      --Ada.Text_Io.Put_Line ("Vec2 = " & To_Str (Vec2));
      --Ada.Text_Io.Put_Line ("Vec3 = " & To_Str (Vec3));
      return Multiply (Multiply (Multiply (In_Vec, First), Second), Third);
   end Convert_Vector;

   function R3_Div (P : in Position; R : in Orientation; Invert : Boolean := False) return Position is
   begin
      -- can't just pass invert boolean along since there is a different order...
      if Invert then
         return Rz (Rx (Ry (P, R.B, True), R.A, True), R.C, True);
      else
         return Ry (Rx (Rz (P, R.C), R.A), R.B);
      end if;
   end R3_Div;

--    qW : array (Sequence) of Float := (-1.0, +1.0, -1.0, +1.0, -1.0, +1.0);
--    qX : array (Sequence) of Float := (-1.0, +1.0, -1.0, -1.0, +1.0, +1.0);
--    qY : array (Sequence) of Float := (+1.0, +1.0, -1.0, +1.0, -1.0, -1.0);
--    qZ : array (Sequence) of Float := (-1.0, -1.0, +1.0, +1.0, -1.0, +1.0);

   package SGM is new Sal.Gen_Math(Float);
   package SGMGS is new SGM.Gen_Scalar(Ada.Numerics.Elementary_Functions);
   package DOF is new SGM.Gen_Dof_3 (Ada.Numerics.Elementary_Functions,
                                     SGMGS);
   use DOF;

   procedure To_Quaternion (Yaw, Pitch, Roll : in Float;
                            W, X, Y, Z : out Float;
                            Latitude, Longitude : in Float := 0.0;
                            Seq : in Sequence := Default) is
      Q, Q1 : DOF.Unit_Quaternion_Type;
      E, E1 : DOF.Zyx_Euler_Type := (Yaw, Pitch, Roll);
   begin

      Q := DOF.To_Unit_Quaternion (E);

      if Latitude /= 0.0 or Longitude /= 0.0 then
         E1 := (Longitude, Ada.Numerics.PI/2.0 - Latitude, 0.0);
         Q1 := DOF.To_Unit_Quaternion (E1);
         Q := DOF."*" (Q1, Q);
      end if;

      X := Dof.X(Q);
      Y := Dof.Y(Q);
      Z := Dof.Z(Q);
      W := Dof.S(Q);
      -- Division is (Z, X, Y, W) with Euler of (Pitch, Yaw, Roll)
   end;

   procedure To_Euler (W, X, Y, Z : in Float;
                       Yaw, Pitch, Roll : out Float;
                       Latitude, Longitude : in Float := 0.0) is
      Q, Q1 : DOF.Unit_Quaternion_Type;
      E, E1 : DOF.Zyx_Euler_Type;
   begin

      Q := DOF.To_Unit_Quaternion (X, Y, Z, W);

      if Latitude /= 0.0 or Longitude /= 0.0 then
         E1 := (Longitude, Ada.Numerics.PI/2.0 - Latitude, 0.0);
         Q1 := DOF.To_Unit_Quaternion (E1);
         Q1 := DOF.Unit_Quaternion_Inverse (Q1);
         Q := DOF."*" (Q1, Q);
      end if;
      E := DOF.To_Zyx_Euler (Q);
      Yaw := E.Theta_Z;
      Pitch := E.Theta_Y;
      Roll := E.Theta_X;
   end;

   function To_Euler_Orientation (Q : Unit_Quaternion_Type) return Hal.Orientation is
      Euler : Zyx_Euler_Type := To_Zyx_Euler (Q);
      Result : Orientation := (Euler.Theta_Y, Euler.Theta_Z, Euler.Theta_X);
   begin
      return Result;
   end To_Euler_Orientation;

   -- this uses the SLERP method (Spherical Linear Interpolation)
   -- qm = q_from * sin((1-t)*Theta)/sin(Theta) + q_to * sin(t*Theta)/(sin Theta)
   -- where qm is the interpolated quaternion at time t, as t ranges between 0.0 (at q_from)
   -- to 1.0 (at q_to)
   -- Theta is half the angle between q_to and q_from calculated by:
   -- Theta = arccos (wa*wb + xa*xb + ya*yb+ za*zb)  where a refers to the q_from values
   -- and b refers to the q_to values
   function Interpolate_Quat (Num : in Integer; -- number of interpolations
                              Start : in Hal.Orientation;
                              Final : in Hal.Orientation) return Ori_Arr is
      Slerp : Ori_Arr (1 .. Num);
      Theta : Float;
      Sin_Theta : Float;
      T : Float; -- the interpolation point between 0.0 and 1.0
      From_Scalar : Float;
      To_Scalar : Float;
      W, X, Y, Z : Float;
      Q_From, Q_To, Q_T : Unit_Quaternion_Type;
   begin

      declare
         Euler_From : Zyx_Euler_Type := (Start.B, Start.A, Start.C);
         Euler_To : Zyx_Euler_Type := (Final.B, Final.A, Final.C);
      begin
         -- convert euler orientations to quaternion
         Q_From := To_Unit_Quaternion (Euler_From);
         Q_To := To_Unit_Quaternion (Euler_To);

         -- choose shorter path by choosing the smaller one of...
         declare
            Mag_Diff_Pos : Float :=
              (DOF.S(Q_From)-DOF.S(Q_To))*(DOF.S(Q_From)-DOF.S(Q_To)) +
              (DOF.X(Q_From)-DOF.X(Q_To))*(DOF.X(Q_From)-DOF.X(Q_To)) +
              (DOF.Y(Q_From)-DOF.Y(Q_To))*(DOF.Y(Q_From)-DOF.Y(Q_To)) +
              (DOF.Z(Q_From)-DOF.Z(Q_To))*(DOF.Z(Q_From)-DOF.Z(Q_To));
            Mag_Diff_Neg : Float :=
              (DOF.S(Q_From)+DOF.S(Q_To))*(DOF.S(Q_From)+DOF.S(Q_To)) +
              (DOF.X(Q_From)+DOF.X(Q_To))*(DOF.X(Q_From)+DOF.X(Q_To)) +
              (DOF.Y(Q_From)+DOF.Y(Q_To))*(DOF.Y(Q_From)+DOF.Y(Q_To)) +
              (DOF.Z(Q_From)+DOF.Z(Q_To))*(DOF.Z(Q_From)+DOF.Z(Q_To));
         begin
            if Mag_Diff_Neg < Mag_Diff_Pos then
               Q_To := To_Unit_Quaternion (DOF.X(Q_To), DOF.Y(Q_To), DOF.Z(Q_To), DOF.S(Q_To));
               -- Pace.Log.Put_Line ("switching to negated Q_to to do shorter path");
            end if;
         end;
      end;

      Theta := Arccos (DOF.S (Q_From) * DOF.S (Q_To) + DOF.X (Q_From) * DOF.X (Q_To) + DOF.Y (Q_From) * DOF.Y (Q_To) + DOF.Z (Q_From) * DOF.Z (Q_To));
      Sin_Theta := Sin (Theta);

      -- set the first and last quaternions
      Slerp (1) := Start;
      Slerp (Num) := Final;

      -- normalize num to a scale of 0 to 1.0 by keeping a counter and dividing it by num
      for I in 2 .. Num - 1 loop
         T := Float (I) / Float (Num);
         From_Scalar := Sin ((1.0-T)*Theta) / Sin_Theta;
         To_Scalar := Sin (T*Theta) / Sin_Theta;

         W := From_Scalar * DOF.S (Q_From) + To_Scalar * DOF.S (Q_To);
         X := From_Scalar * DOF.X (Q_From) + To_Scalar * DOF.X (Q_To);
         Y := From_Scalar * DOF.Y (Q_From) + To_Scalar * DOF.Y (Q_To);
         Z := From_Scalar * DOF.Z (Q_From) + To_Scalar * DOF.Z (Q_To);

         -- should be normalized already... just need in this type for conversion purposes
         Q_T := To_Unit_Quaternion (X, Y, Z, W);

         Slerp (I) := To_Euler_Orientation (Q_T);
         --Pace.Log.Put_Line ("t is " & T'Img & To_Str (Slerp (I)));
      end loop;
      --Pace.Log.Put_Line ("theta is " & Theta'Img);

      return Slerp;
   end Interpolate_Quat;

   -- This can be used to go from an absolute reference frame to a relative reference
   -- frame (set Invert to true) or vice-versa (set Invert to false).
   procedure Adjust_For_Pitch_And_Roll (In_El : in Float; -- the input elevation (radians)
                                        In_Az : in Float; -- the input azimuth (radians)
                                        Pitch : in Float; -- radians
                                        Roll : in Float; -- radians
                                        Yaw : in Float;  -- radians
                                        Invert : in Boolean;  -- should be true for abs to rel
                                        Out_El : out Float; -- the output elevation (radians)
                                        Out_Az : out Float; -- the output azimuth (radians)
                                        Order : in Rotation_Order := Default_Order) is
      Pos : Hal.Position := (1.0, 0.0, 0.0);
   begin

      -- Obtain input position vector (no roll component) in the SSOM vehicle CS
      -- (So negate Azimuth but not Elevation since it is a special case)
      Pos := R3_Terrain (P      => Pos, 
                         R      => (A => 0.0,
                                    B => In_El,
                                    C => -In_Az), 
                         Invert => False,
                         Order  => Order);

      -- Do the inverse transformation in SSOM vehicle CS and obtain the Output location
      Pos := R3_Terrain (P      => Pos,
                         R      => (A => Roll,
                                    B => Pitch,
                                    C => Yaw),
                         Invert => Invert,
                         Order  => Order);

      -- Convert from SSOM CS to VE CS
      declare
         Temp_Pos : constant Hal.Position := Pos;
      begin
         Pos := (-Temp_Pos.Y, -Temp_Pos.Z, Temp_Pos.X);
      end;

      -- use trig to get relative elevation and azimuth in VE CS
      Out_El := Arctan (Pos.Y, Sqrt (Pos.X * Pos.X + Pos.Z * Pos.Z));
      Out_Az := Arctan (Pos.X, Pos.Z);

   end Adjust_For_Pitch_And_Roll;


   procedure To_Axis (W, X, Y, Z : in Float;
                      To, Up : out Position) is
      Q : DOF.Unit_Quaternion_Type;
      T, U : DOF.Unit_Vector_Type;
   begin
      Q := DOF.To_Unit_Quaternion (X, Y, Z, W);
      T := DOF.X_Axis (Q);
      U := DOF.Z_Axis (Q);
      To.X := DOF.X (T);
      To.Y := DOF.Y (T);
      To.Z := DOF.Z (T);
      Up.X := DOF.X (U);
      Up.Y := DOF.Y (U);
      Up.Z := DOF.Z (U);
   end;

   procedure To_Axis (Yaw, Pitch, Roll : in Float;
                      To, Up : out Position) is
      W, X, Y, Z : Float;
   begin
      To_Quaternion (Yaw => Yaw,
                     Pitch => Pitch,
                     Roll => Roll,
                     W => W,
                     X => X,
                     Y => Y,
                     Z => Z);
      To_Axis (W, X, Y, Z, To, Up);
   end;

   function Extract_YXZ (Tm : Rotation_Matrix) return Orientation is
      -- taken from 3D Game Engine Design, pg. 21 (Moline's book)
      -- NOTE: had to negate the else condition lines!
      use Ada.Numerics.Elementary_Functions;
      use Ada.Numerics;

      Tx : Float := Arcsin (-Tm(Y, C));
      Ty : Float;
      Tz : Float;
   begin
      if Tx < Pi/2.0 then
         if Tx > -Pi/2.0 then
            Ty := Arctan (Tm(X,C), Tm(Z,C));
            Tz := Arctan (Tm(Y,A), Tm(Y,B));
         else
            -- not a unique solution
            Ty := Arctan (-Tm(X,B), Tm(X,A));  -- this is negated in the book
            Tz := 0.0;
         end if;
      else
         -- not a unique solution
         Ty := -Arctan (-Tm(X,B), Tm(X,A)); -- this is positive in the book
         Tz := 0.0;
      end if;
      return Orientation'(Tx, Ty, Tz);
   end Extract_YXZ;

   function Convert_Euler_To_Yxz (First : Rotation_Matrix;
                                  Second : Rotation_Matrix;
                                  Third : Rotation_Matrix;
                                  Inverse : Boolean) return Orientation is
      Tm : Rotation_Matrix := Multiply (Multiply (First, Second), Third);
   begin
      if Inverse then
         -- the transpose of a rotation matrix equals its inverse
         return Extract_Yxz (Transpose (Tm));
      else
         return Extract_Yxz (Tm);
      end if;
   end Convert_Euler_To_Yxz;

   function Convert_Euler (Conv_Type : Euler_Conversion;
                           Ori : Orientation;
                           Inverse : Boolean := False) return Orientation is
   begin
      if Conv_Type = Xyz_To_Yxz then
         --return EulerXYZ_To_EulerYXZ (Ori, Inverse);
         return Convert_Euler_To_Yxz (Rx (Ori.A), Ry (Ori.B), Rz (Ori.C), Inverse);
      elsif Conv_Type = Yzx_To_Yxz then
         --return EulerXYZ_To_EulerYXZ (Ori, Inverse);
         return Convert_Euler_To_Yxz (Ry (Ori.B), Rz (Ori.C), Rx (Ori.A), Inverse);
      elsif Conv_Type = Xzy_To_Yxz then
         return Convert_Euler_To_Yxz (Rx (Ori.A), Rz (Ori.C), Ry (Ori.B), Inverse);
      elsif Conv_Type = Yxz_To_Yxz then
         return Ori;
      elsif Conv_Type = Zxy_To_Yxz then
         return Convert_Euler_To_Yxz (Rz (Ori.C), Rx (Ori.A), Ry (Ori.B), Inverse);
      elsif Conv_Type = Zyx_To_Yxz then
         return Convert_Euler_To_Yxz (Rz (Ori.C), Ry (Ori.B), Rx (Ori.A), Inverse);
      else
         return Ori;
      end if;
   end Convert_Euler;

   procedure Convert_Euler_C (Conv_Type : Euler_Conversion;
                              In_A, In_B, In_C : in Float;
                              Out_A, Out_B, Out_C : out Float;
                              Inverse : Boolean) is
      Ori_Out : Orientation := Convert_Euler (Conv_Type, Orientation'(In_A, In_B, In_C), Inverse);
   begin
      Out_A := Ori_Out.A;
      Out_B := Ori_Out.B;
      Out_C := Ori_Out.C;
   end Convert_Euler_C;

   procedure Convert_Vector_Xyz_To_Yxz_C (In_X, In_Y, In_Z : in Float;
                                          In_A, In_B, In_C : in Float;
                                          Out_X, Out_Y, Out_Z : out Float) is
      Result : Position;
   begin
      Result := Convert_Vector (Position'(In_X, In_Y, In_Z),
                                Rz (In_C),
                                Rx (In_A),
                                Ry (In_B));
      Out_X := Result.X;
      Out_Y := Result.Y;
      Out_Z := Result.Z;
   end Convert_Vector_Xyz_To_Yxz_C;

   -- $Id: hal-rotations.adb,v 1.22 2006/06/19 17:09:35 ludwiglj Exp $
end Hal.Rotations;
