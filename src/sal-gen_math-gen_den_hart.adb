--  Abstract:
--
--  see spec
--
--  References:
--
--  [1] Derive_Mult.mac
--
--  MODIFICATION HISTORY:
--    (kept for sentimental reasons)
--
--  Jan. 17, 1991       Dana Miller     Created
--  27 Jan 1992 Stephe Leake
--     Match spec changes
--  15 June 1992        Stephe Leake
--     Match spec changes, use [.DERIVE]MANIPULATOR_MATH.MAC for all
--     bodies.
--   8 July 1992        Stephe Leake
--     match changes to Math_6_DOF spec
--   August 5, 1992     Victoria Buckland
--     After much headache, finally realized to change temporary
--     quaternion object assignments in Partial_Jacobian to reflect their
--     object names.  (ex. Qx_Qy is  2.0*Qx*Qy  NOT  2.0*Qs_Qx; bug due to
--     Stephe!)
--  30 Nov 1993 Stephe Leake
--     match spec changes
--  18 Jul 1994     Victoria Buckland
--     match spec changes
--  21 May 2002     Stephe Leake
--     match spec changes

package body Sal.Gen_Math.Gen_Den_Hart is

   function To_Pose
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Pose_Type
   is
      use Math_Scalar, Math_Dof_3;
      Half_Trig_Alpha : constant Trig_Pair_Type :=
         Half_Trig (Param.Trig_Alpha);
      Half_Trig_Theta : Trig_Pair_Type;
      D               : Real_Type;
   begin
      case Param.Class is
         when Prismatic =>
            Half_Trig_Theta := Half_Trig (Param.Trig_Theta);
            D               := Position;
         when Revolute =>
            Half_Trig_Theta := Half_Trig (Sin_Cos (Position));
            D               := Param.D;
      end case;

      return
        (Translation => (Param.A,
                         -Sin (Param.Trig_Alpha) * D,
                         Cos (Param.Trig_Alpha) * D),
         Rotation    =>
  Unchecked_Unit_Quaternion
    (S => Cos (Half_Trig_Alpha) * Cos (Half_Trig_Theta),
     X => Sin (Half_Trig_Alpha) * Cos (Half_Trig_Theta),
     Y => -Sin (Half_Trig_Alpha) * Sin (Half_Trig_Theta),
     Z => Cos (Half_Trig_Alpha) * Sin (Half_Trig_Theta)));
   end To_Pose;

   function To_Inverse_Pose
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Pose_Type
   is
      use Math_Scalar, Math_Dof_3;
      Half_Trig_Alpha : constant Trig_Pair_Type :=
         Half_Trig (Param.Trig_Alpha);
      Half_Trig_Theta : Trig_Pair_Type;
      Trig_Theta      : Trig_Pair_Type;
      D               : Real_Type;
   begin
      case Param.Class is
         when Prismatic =>
            Trig_Theta      := Param.Trig_Theta;
            Half_Trig_Theta := Half_Trig (Trig_Theta);
            D               := Position;
         when Revolute =>
            Trig_Theta      := Sin_Cos (Position);
            Half_Trig_Theta := Half_Trig (Trig_Theta);
            D               := Param.D;
      end case;

      return
        (Translation => (-Param.A * Cos (Trig_Theta),
                         Param.A * Sin (Trig_Theta),
                         -D),
         Rotation    =>
  Unchecked_Unit_Quaternion
    (S => -Cos (Half_Trig_Alpha) * Cos (Half_Trig_Theta),
     X => Sin (Half_Trig_Alpha) * Cos (Half_Trig_Theta),
     Y => -Sin (Half_Trig_Alpha) * Sin (Half_Trig_Theta),
     Z => Cos (Half_Trig_Alpha) * Sin (Half_Trig_Theta)));
   end To_Inverse_Pose;

   function To_Rate_Transform
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Rate_Transform_Type
   is
      use Math_Scalar, Math_Dof_3;
      Theta : Trig_Pair_Type;
      Alpha : constant Trig_Pair_Type := Param.Trig_Alpha;
      D     : Real_Type;
      A     : constant Real_Type      := Param.A;
   begin
      case Param.Class is
         when Prismatic =>
            Theta := Param.Trig_Theta;
            D     := Position;
         when Revolute =>
            Theta := Sin_Cos (Position);
            D     := Param.D;
      end case;

      return Math_Dof_6.Unchecked_Rate_Transform
               (Rot       =>
        ((Cos (Theta),
          Cos (Alpha) * Sin (Theta),
          Sin (Alpha) * Sin (Theta)),
         (-Sin (Theta),
          Cos (Alpha) * Cos (Theta),
          Sin (Alpha) * Cos (Theta)),
         (0.0, -Sin (Alpha), Cos (Alpha))),
                Rot_Cross =>
        (X => (X => -D * Sin (Theta),
               Y => Cos (Alpha) * D * Cos (Theta) -
                    A * Sin (Alpha) * Sin (Theta),
               Z => A * Cos (Alpha) * Sin (Theta) +
                    Sin (Alpha) * D * Cos (Theta)),
         Y => (X => -D * Cos (Theta),
               Y => -Cos (Alpha) * D * Sin (Theta) -
                    A * Sin (Alpha) * Cos (Theta),
               Z => A * Cos (Alpha) * Cos (Theta) -
                    Sin (Alpha) * D * Sin (Theta)),
         Z => (X => 0.0, Y => -A * Cos (Alpha), Z => -A * Sin (Alpha))));
   end To_Rate_Transform;

   function To_Inverse_Rate_Transform
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Rate_Transform_Type
   is
      use Math_Scalar, Math_Dof_3;
      Theta : Trig_Pair_Type;
      Alpha : constant Trig_Pair_Type := Param.Trig_Alpha;
      D     : Real_Type;
      A     : constant Real_Type      := Param.A;
   begin
      case Param.Class is
         when Prismatic =>
            Theta := Param.Trig_Theta;
            D     := Position;
         when Revolute =>
            Theta := Sin_Cos (Position);
            D     := Param.D;
      end case;

      return Math_Dof_6.Unchecked_Rate_Transform
               (Rot       =>
        ((Cos (Theta), -Sin (Theta), 0.0),
         (Cos (Alpha) * Sin (Theta),
          Cos (Alpha) * Cos (Theta),
          -Sin (Alpha)),
         (Sin (Alpha) * Sin (Theta),
          Sin (Alpha) * Cos (Theta),
          Cos (Alpha))),
                Rot_Cross =>
        (X => (X => -D * Sin (Theta), Y => -D * Cos (Theta), Z => 0.0),
         Y => (X => Cos (Alpha) * D * Cos (Theta) -
                    A * Sin (Alpha) * Sin (Theta),
               Y => -Cos (Alpha) * D * Sin (Theta) -
                    A * Sin (Alpha) * Cos (Theta),
               Z => -A * Cos (Alpha)),
         Z => (X => A * Cos (Alpha) * Sin (Theta) +
                    Sin (Alpha) * D * Cos (Theta),
               Y => A * Cos (Alpha) * Cos (Theta) -
                    Sin (Alpha) * D * Sin (Theta),
               Z => -A * Sin (Alpha))));
   end To_Inverse_Rate_Transform;

   function To_Wrench_Transform
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Wrench_Transform_Type
   is
      use Math_Scalar, Math_Dof_3;
      Theta : Trig_Pair_Type;
      Alpha : constant Trig_Pair_Type := Param.Trig_Alpha;
      D     : Real_Type;
      A     : constant Real_Type      := Param.A;
   begin
      case Param.Class is
         when Prismatic =>
            Theta := Param.Trig_Theta;
            D     := Position;
         when Revolute =>
            Theta := Sin_Cos (Position);
            D     := Param.D;
      end case;

      return Math_Dof_6.Unchecked_Wrench_Transform
               (Rot       =>
        ((Cos (Theta),
          Cos (Alpha) * Sin (Theta),
          Sin (Alpha) * Sin (Theta)),
         (-Sin (Theta),
          Cos (Alpha) * Cos (Theta),
          Sin (Alpha) * Cos (Theta)),
         (0.0, -Sin (Alpha), Cos (Alpha))),
                Rot_Cross =>
        (X => (X => -D * Sin (Theta),
               Y => Cos (Alpha) * D * Cos (Theta) -
                    A * Sin (Alpha) * Sin (Theta),
               Z => A * Cos (Alpha) * Sin (Theta) +
                    Sin (Alpha) * D * Cos (Theta)),
         Y => (X => -D * Cos (Theta),
               Y => -Cos (Alpha) * D * Sin (Theta) -
                    A * Sin (Alpha) * Cos (Theta),
               Z => A * Cos (Alpha) * Cos (Theta) -
                    Sin (Alpha) * D * Sin (Theta)),
         Z => (X => 0.0, Y => -A * Cos (Alpha), Z => -A * Sin (Alpha))));
   end To_Wrench_Transform;

   function To_Inverse_Wrench_Transform
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Wrench_Transform_Type
   is
      use Math_Scalar, Math_Dof_3;
      Theta : Trig_Pair_Type;
      Alpha : constant Trig_Pair_Type := Param.Trig_Alpha;
      D     : Real_Type;
      A     : constant Real_Type      := Param.A;
   begin
      case Param.Class is
         when Prismatic =>
            Theta := Param.Trig_Theta;
            D     := Position;
         when Revolute =>
            Theta := Sin_Cos (Position);
            D     := Param.D;
      end case;

      return Math_Dof_6.Unchecked_Wrench_Transform
               (Rot       =>
        ((Cos (Theta), -Sin (Theta), 0.0),
         (Cos (Alpha) * Sin (Theta),
          Cos (Alpha) * Cos (Theta),
          -Sin (Alpha)),
         (Sin (Alpha) * Sin (Theta),
          Sin (Alpha) * Cos (Theta),
          Cos (Alpha))),
                Rot_Cross =>
        (X => (X => -D * Sin (Theta), Y => -D * Cos (Theta), Z => 0.0),
         Y => (X => Cos (Alpha) * D * Cos (Theta) -
                    A * Sin (Alpha) * Sin (Theta),
               Y => -Cos (Alpha) * D * Sin (Theta) -
                    A * Sin (Alpha) * Cos (Theta),
               Z => -A * Cos (Alpha)),
         Z => (X => A * Cos (Alpha) * Sin (Theta) +
                    Sin (Alpha) * D * Cos (Theta),
               Y => A * Cos (Alpha) * Cos (Theta) -
                    Sin (Alpha) * D * Sin (Theta),
               Z => -A * Sin (Alpha))));
   end To_Inverse_Wrench_Transform;

   function Partial_Jacobian
     (Ti_T_Obj : Math_Dof_6.Pose_Type)
      return     Math_Dof_6.Dual_Cart_Vector_Type
   is
      use Math_Dof_3;
      Tx : constant Real_Type := Ti_T_Obj.Translation (X);
      Ty : constant Real_Type := Ti_T_Obj.Translation (Y);
      Qs : constant Real_Type := S (Ti_T_Obj.Rotation);
      Qx : constant Real_Type := X (Ti_T_Obj.Rotation);
      Qy : constant Real_Type := Y (Ti_T_Obj.Rotation);
      Qz : constant Real_Type := Z (Ti_T_Obj.Rotation);

      Qs_Qx : constant Real_Type := 2.0 * Qs * Qx;
      Qs_Qy : constant Real_Type := 2.0 * Qs * Qy;
      Qs_Qz : constant Real_Type := 2.0 * Qs * Qz;
      Qx2   : constant Real_Type := 2.0 * Qx * Qx;
      Qx_Qy : constant Real_Type := 2.0 * Qx * Qy;
      Qx_Qz : constant Real_Type := 2.0 * Qx * Qz;
      Qy2   : constant Real_Type := 2.0 * Qy * Qy;
      Qy_Qz : constant Real_Type := 2.0 * Qy * Qz;
      Qz2   : constant Real_Type := 2.0 * Qz * Qz;

   begin
      return
        (Math_Dof_6.Tx => (Qz2 + Qy2 - 1.0) * Ty + (Qx_Qy + Qs_Qz) * Tx,
         Math_Dof_6.Ty => (Qs_Qz - Qx_Qy) * Ty + (1.0 - Qz2 - Qx2) * Tx,
         Math_Dof_6.Tz => (-Qx_Qz - Qs_Qy) * Ty + (Qy_Qz - Qs_Qx) * Tx,
         Math_Dof_6.Rx => Qx_Qz - Qs_Qy,
         Math_Dof_6.Ry => Qy_Qz + Qs_Qx,
         Math_Dof_6.Rz => 1.0 - Qy2 - Qx2);
   end Partial_Jacobian;

   function Mult
     (Left           : in Math_Dof_6.Pose_Type;
      Right          : in Den_Hart_Type;
      Right_Position : in Real_Type)
      return           Math_Dof_6.Pose_Type
   is
      use Math_Dof_3.Cart_Vector_Ops;
      use Math_Dof_3;
      Right_Pose : constant Math_Dof_6.Pose_Type :=
         To_Pose (Right, Right_Position);
   begin
      return
        (Translation => Left.Translation +
                        Left.Rotation * Right_Pose.Translation,
         Rotation    => Left.Rotation * Right_Pose.Rotation);
   end Mult;

   function Mult
     (Left          : in Den_Hart_Type;
      Left_Position : in Real_Type;
      Right         : in Math_Dof_6.Pose_Type)
      return          Math_Dof_6.Pose_Type
   is
      use Math_Scalar, Math_Dof_3;
      Half_Trig_Alpha : constant Trig_Pair_Type :=
         Half_Trig (Left.Trig_Alpha);
      Half_Trig_Theta : Trig_Pair_Type;
      Trig_Theta      : Trig_Pair_Type;
      D               : Real_Type;
      Left_Rot        : Unit_Quaternion_Type;
   begin
      case Left.Class is
         when Prismatic =>
            Half_Trig_Theta := Half_Trig (Left.Trig_Theta);
            D               := Left_Position;
         when Revolute =>
            Trig_Theta      := Sin_Cos (Left_Position);
            Half_Trig_Theta := Half_Trig (Trig_Theta);
            D               := Left.D;
      end case;

      --  Extracted from body of To_Pose (Den_Hart, Position)
      Left_Rot :=
         Unchecked_Unit_Quaternion
           (S => Cos (Half_Trig_Alpha) * Cos (Half_Trig_Theta),
            X => Sin (Half_Trig_Alpha) * Cos (Half_Trig_Theta),
            Y => -Sin (Half_Trig_Alpha) * Sin (Half_Trig_Theta),
            Z => Cos (Half_Trig_Alpha) * Sin (Half_Trig_Theta));

      return
        (Translation => --  [1] see Result[1]
        (X => Left.A -
              Sin (Trig_Theta) * Right.Translation (Y) +
              Cos (Trig_Theta) * Right.Translation (X),
         Y => -Sin (Left.Trig_Alpha) * (D + Right.Translation (Z)) +
              Cos (Left.Trig_Alpha) *
              (Sin (Trig_Theta) * Right.Translation (X) +
               Cos (Trig_Theta) * Right.Translation (Y)),

         Z => Cos (Left.Trig_Alpha) * (D + Right.Translation (Z)) +
              Sin (Left.Trig_Alpha) *
              (Sin (Trig_Theta) * Right.Translation (X) +
               Cos (Trig_Theta) * Right.Translation (Y))),

         Rotation    => Left_Rot * Right.Rotation);
   end Mult;

end Sal.Gen_Math.Gen_Den_Hart;
