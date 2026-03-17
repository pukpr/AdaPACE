-- Abstract:
--
-- see spec
--
-- Copyright (C) 2001, 2002, 2003 Stephen Leake.  All Rights Reserved.
--
-- This library is free software; you can redistribute it and/or
-- modify it under terms of the GNU General Public License as
-- published by the Free Software Foundation; either version 2, or (at
-- your option) any later version. This library is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY; without even
-- the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE. See the GNU General Public License for more details. You
-- should have received a copy of the GNU General Public License
-- distributed with this program; see file COPYING. If not, write to
-- the Free Software Foundation, 59 Temple Place - Suite 330, Boston,
-- MA 02111-1307, USA.
--
-- As a special exception, if other files instantiate generics from
-- this unit, or you link this unit with other files to produce an
-- executable, this  unit  does not  by itself cause  the resulting
-- executable to be covered by the GNU General Public License. This
-- exception does not however invalidate any other reasons why the
-- executable file  might be covered by the  GNU Public License.
--
package body Sal.Gen_Math.Gen_Dof_3 is

   ----------------
   -- more Cart_Vector operations

   function Mag (Item : in Cart_Vector_Type) return Real_Type is
   begin
      return Elementary.Sqrt
               (Item (X) * Item (X) +
                Item (Y) * Item (Y) +
                Item (Z) * Item (Z));
   end Mag;

   function Cross
     (Left, Right : in Cart_Vector_Type)
      return        Cart_Vector_Type
   is
   begin
      return
        (Left (Y) * Right (Z) - Left (Z) * Right (Y),
         Left (Z) * Right (X) - Left (X) * Right (Z),
         Left (X) * Right (Y) - Left (Y) * Right (X));
   end Cross;

   -------------------
   -- unit vectors

   function X (Item : in Unit_Vector_Type) return Real_Type is
   begin
      return Item (X);
   end X;

   function Y (Item : in Unit_Vector_Type) return Real_Type is
   begin
      return Item (Y);
   end Y;

   function Z (Item : in Unit_Vector_Type) return Real_Type is
   begin
      return Item (Z);
   end Z;

   function To_Unit_Vector
     (Item : in Cart_Vector_Type)
      return Unit_Vector_Type
   is
      Magnitude : constant Real_Type := Mag (Item);
   begin
      -- (x, y, z) / magnitude is guaranteed < 1.0, so we only need to
      -- check for precisely 0.0.
      if Magnitude > 0.0 then
         return
           (Item (X) / Magnitude,
            Item (Y) / Magnitude,
            Item (Z) / Magnitude);
      else
         raise Non_Normalizable_Unit_Vector;
      end if;
   end To_Unit_Vector;

   function To_Unit_Vector (X, Y, Z : in Real_Type) return Unit_Vector_Type is
   begin
      return To_Unit_Vector (Cart_Vector_Type'(X, Y, Z));
   end To_Unit_Vector;

   function To_Cart_Vector
     (Item : in Unit_Vector_Type)
      return Cart_Vector_Type
   is
   begin
      return (Item (X), Item (Y), Item (Z));
   end To_Cart_Vector;

   function Normalize (Item : in Unit_Vector_Type) return Unit_Vector_Type is
   begin
      return To_Unit_Vector
               (Cart_Vector_Type'(Item (X), Item (Y), Item (Z)));
   end Normalize;

   function Unchecked_Unit_Vector
     (Item : in Cart_Vector_Type)
      return Unit_Vector_Type
   is
   begin
      return (Item (X), Item (Y), Item (Z));
   end Unchecked_Unit_Vector;

   function Unchecked_Unit_Vector
     (X, Y, Z : in Real_Type)
      return    Unit_Vector_Type
   is
   begin
      return (X, Y, Z);
   end Unchecked_Unit_Vector;

   function "-" (Item : in Unit_Vector_Type) return Unit_Vector_Type is
   begin
      return (-Item (X), -Item (Y), -Item (Z));
   end "-";

   function "*"
     (Left  : in Unit_Vector_Type;
      Right : in Real_Type)
      return  Cart_Vector_Type
   is
   begin
      return (Right * Left (X), Right * Left (Y), Right * Left (Z));
   end "*";

   function "*"
     (Left  : in Real_Type;
      Right : in Unit_Vector_Type)
      return  Cart_Vector_Type
   is
   begin
      return (Left * Right (X), Left * Right (Y), Left * Right (Z));
   end "*";

   function "*"
     (Left  : in Unit_Quaternion_Type;
      Right : in Unit_Vector_Type)
      return  Unit_Vector_Type
   is
   begin
      return Unchecked_Unit_Vector
               (Left * (Right (X), Right (Y), Right (Z)));
   end "*";

   function "/"
     (Left  : in Unit_Vector_Type;
      Right : in Real_Type)
      return  Cart_Vector_Type
   is
   begin
      return (Left (X) / Right, Left (Y) / Right, Left (Z) / Right);
   end "/";

   function Dot
     (Left  : in Unit_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Real_Type
   is
   begin
      return Left (X) * Right (X) +
             Left (Y) * Right (Y) +
             Left (Z) * Right (Z);
   end Dot;

   function Dot
     (Left  : in Unit_Vector_Type;
      Right : in Cart_Vector_Type)
      return  Real_Type
   is
   begin
      return Left (X) * Right (X) +
             Left (Y) * Right (Y) +
             Left (Z) * Right (Z);
   end Dot;

   function Dot
     (Left  : in Cart_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Real_Type
   is
   begin
      return Left (X) * Right (X) +
             Left (Y) * Right (Y) +
             Left (Z) * Right (Z);
   end Dot;

   function Cross
     (Left  : in Unit_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Cart_Vector_Type
   is
   begin
      return
        (Left (Y) * Right (Z) - Left (Z) * Right (Y),
         Left (Z) * Right (X) - Left (X) * Right (Z),
         Left (X) * Right (Y) - Left (Y) * Right (X));
   end Cross;

   function Cross
     (Left  : in Unit_Vector_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type
   is
   begin
      return
        (Left (Y) * Right (Z) - Left (Z) * Right (Y),
         Left (Z) * Right (X) - Left (X) * Right (Z),
         Left (X) * Right (Y) - Left (Y) * Right (X));
   end Cross;

   function Cross
     (Left  : in Cart_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Cart_Vector_Type
   is
   begin
      return
        (Left (Y) * Right (Z) - Left (Z) * Right (Y),
         Left (Z) * Right (X) - Left (X) * Right (Z),
         Left (X) * Right (Y) - Left (Y) * Right (X));
   end Cross;

   ---------------
   -- magnitude and axis

   function "-" (Item : in Mag_Axis_Type) return Mag_Axis_Type is
   begin
      return (-Item.Mag, Item.Axis);
   end "-";

   function "*"
     (Left  : in Real_Type;
      Right : in Mag_Axis_Type)
      return  Mag_Axis_Type
   is
   begin
      return (Left * Right.Mag, Right.Axis);
   end "*";

   function "*"
     (Left  : in Mag_Axis_Type;
      Right : in Real_Type)
      return  Mag_Axis_Type
   is
   begin
      return (Left.Mag * Right, Left.Axis);
   end "*";

   function "/"
     (Left  : in Mag_Axis_Type;
      Right : in Real_Type)
      return  Mag_Axis_Type
   is
   begin
      return (Left.Mag / Right, Left.Axis);
   end "/";

   function To_Cart_Vector
     (Mag_Axis : in Mag_Axis_Type)
      return     Cart_Vector_Type
   is
   begin
      return Mag_Axis.Mag * Mag_Axis.Axis;
   end To_Cart_Vector;

   function To_Mag_Axis
     (Cart_Vector : in Cart_Vector_Type)
      return        Mag_Axis_Type
   is
      Magnitude : constant Real_Type := Mag (Cart_Vector);
   begin
      -- (x, y, z) / magnitude is guaranteed < 1.0, so we only need to
      -- check for precisely 0.0
      if Magnitude > 0.0 then
         return
           (Magnitude,
            (Cart_Vector (X) / Magnitude,
             Cart_Vector (Y) / Magnitude,
             Cart_Vector (Z) / Magnitude));
      else
         return (0.0, X_Unit);
      end if;
   end To_Mag_Axis;

   function To_Mag_Axis
     (Left, Right : in Unit_Vector_Type)
      return        Mag_Axis_Type
   is
      use Math_Scalar;
      Temp_Cross : constant Cart_Vector_Type := Cross (Left, Right);
      Temp_Dot   : constant Real_Type        := Left * Right;
      Magnitude  : constant Real_Type        :=
         Atan2 (Unchecked_Trig_Pair (Mag (Temp_Cross), Temp_Dot));
   begin
      if Magnitude > 0.0 then
         return (Mag => Magnitude, Axis => To_Unit_Vector (Temp_Cross));
      else
         return (0.0, X_Unit);
      end if;
   end To_Mag_Axis;

   -------------
   -- Quaternions

   function X (Item : in Unit_Quaternion_Type) return Real_Type is
   begin
      return Item.X;
   end X;

   function Y (Item : in Unit_Quaternion_Type) return Real_Type is
   begin
      return Item.Y;
   end Y;

   function Z (Item : in Unit_Quaternion_Type) return Real_Type is
   begin
      return Item.Z;
   end Z;

   function S (Item : in Unit_Quaternion_Type) return Real_Type is
   begin
      return Item.S;
   end S;

   function To_Unit_Quaternion
     (X, Y, Z, S : in Real_Type)
      return       Unit_Quaternion_Type
   is
      Mag : constant Real_Type :=
         Elementary.Sqrt (X * X + Y * Y + Z * Z + S * S);
   begin
      -- Element / Mag is guaranteed < 1.0, so we only have to worry about
      -- exactly 0.0.
      if Mag > 0.0 then
         return (X => X / Mag, Y => Y / Mag, Z => Z / Mag, S => S / Mag);
      else
         raise Non_Normalizable_Unit_Quaternion;
      end if;
   end To_Unit_Quaternion;

   function Unchecked_Unit_Quaternion
     (X, Y, Z, S : in Real_Type)
      return       Unit_Quaternion_Type
   is
   begin
      return (X => X, Y => Y, Z => Z, S => S);
   end Unchecked_Unit_Quaternion;

   function Mag_Axis_To_Unit_Quaternion
     (Mag_Axis : in Mag_Axis_Type)
      return     Unit_Quaternion_Type
   is
      -- [1], eqn 2.1.1-3
      use Math_Scalar;
      Half     : constant Trig_Pair_Type   := Sin_Cos (Mag_Axis.Mag / 2.0);
      Sin_Axis : constant Cart_Vector_Type := Sin (Half) * Mag_Axis.Axis;
   begin
      return
        (X => Sin_Axis (X),
         Y => Sin_Axis (Y),
         Z => Sin_Axis (Z),
         S => Cos (Half));
   end Mag_Axis_To_Unit_Quaternion;

   function Unit_Quaternion_To_Mag_Axis
     (Quaternion : in Unit_Quaternion_Type)
      return       Mag_Axis_Type
   is
      -- [1], eqn 2.1.1-5
      use Math_Scalar;
      Sin_Half : constant Real_Type :=
         Mag (Cart_Vector_Type'(Quaternion.X, Quaternion.Y, Quaternion.Z));
      Temp     : Unit_Quaternion_Type;
   begin
      if Sin_Half > 0.0 then
         if Quaternion.S < 0.0 then
            Temp :=
              (X => -Quaternion.X,
               Y => -Quaternion.Y,
               Z => -Quaternion.Z,
               S => -Quaternion.S);
         else
            Temp := Quaternion;
         end if;

         return
           (Mag  => Atan2
                      (Double_Trig (Unchecked_Trig_Pair (Sin_Half, Temp.S))),
            Axis =>
           Unit_Vector_Type'
           (Temp.X / Sin_Half,
            Temp.Y / Sin_Half,
            Temp.Z / Sin_Half));
      else
         return (0.0, X_Unit);
      end if;
   end Unit_Quaternion_To_Mag_Axis;

   function Rot_Vector_To_Unit_Quaternion
     (Rot_Vector : in Cart_Vector_Type)
      return       Unit_Quaternion_Type
   is
      use Math_Scalar;
      Angle     : constant Real_Type := Mag (Rot_Vector);
      Half_Trig : Trig_Pair_Type     := Sin_Cos (Angle / 2.0);
      Temp      : Real_Type;
   begin
      if Angle > 0.0 then
         if Cos (Half_Trig) < 0.0 then
            -- Angle > pi
            Half_Trig :=
              (Unchecked_Trig_Pair (-Sin (Half_Trig), -Cos (Half_Trig)));
         end if;

         Temp := Sin (Half_Trig) / Angle;
         return
           (X => Temp * Rot_Vector (X),
            Y => Temp * Rot_Vector (Y),
            Z => Temp * Rot_Vector (Z),
            S => Cos (Half_Trig));
      else
         --  Angle = 0.0
         return (X | Y | Z => 0.0, S => 1.0);
      end if;
   end Rot_Vector_To_Unit_Quaternion;

   function Unit_Quaternion_To_Rot_Vector
     (Quaternion : in Unit_Quaternion_Type)
      return       Cart_Vector_Type
   is
      -- [1], 2.1.1-5
      use Math_Scalar, Cart_Vector_Ops;
      Sin_Half : constant Real_Type :=
         Mag (Cart_Vector_Type'(Quaternion.X, Quaternion.Y, Quaternion.Z));
   begin
      if Sin_Half > 0.0 then
         if Quaternion.S < 0.0 then
            return (-2.0 *
                     Atan2 (Unchecked_Trig_Pair (Sin_Half, -Quaternion.S)) /
                     Sin_Half) *
                   Cart_Vector_Type'
              (Quaternion.X,
               Quaternion.Y,
               Quaternion.Z);
         else
            return (2.0 *
                    Atan2 (Unchecked_Trig_Pair (Sin_Half, Quaternion.S)) /
                    Sin_Half) *
                   Cart_Vector_Type'
              (Quaternion.X,
               Quaternion.Y,
               Quaternion.Z);
         end if;
      else
         return (0.0, 0.0, 0.0);
      end if;
   end Unit_Quaternion_To_Rot_Vector;

   function To_Unit_Quaternion
     (Angle : in Real_Type;
      Axis  : in Cart_Axis_Type)
      return  Unit_Quaternion_Type
   is
      -- [1], eqn 2.1.1-3
      use Math_Scalar;
      Half_Trig : constant Trig_Pair_Type := Sin_Cos (Angle / 2.0);
   begin
      case Axis is
         when X =>
            return
              (X => Sin (Half_Trig),
               Y => 0.0,
               Z => 0.0,
               S => Cos (Half_Trig));
         when Y =>
            return
              (X => 0.0,
               Y => Sin (Half_Trig),
               Z => 0.0,
               S => Cos (Half_Trig));
         when Z =>
            return
              (X => 0.0,
               Y => 0.0,
               Z => Sin (Half_Trig),
               S => Cos (Half_Trig));
      end case;
   end To_Unit_Quaternion;

   function X_Axis (Quat : in Unit_Quaternion_Type) return Unit_Vector_Type is
   begin
      -- [1], 2.1.1-7
      return (
        (X => 1.0 - 2.0 * (Quat.Y * Quat.Y + Quat.Z * Quat.Z),
         Y => 2.0 * (Quat.X * Quat.Y + Quat.S * Quat.Z),
         Z => 2.0 * (Quat.X * Quat.Z - Quat.S * Quat.Y)));
   end X_Axis;

   function Y_Axis (Quat : in Unit_Quaternion_Type) return Unit_Vector_Type is
   begin
      -- [1], 2.1.1-7
      return (
        (X => 2.0 * (Quat.X * Quat.Y - Quat.S * Quat.Z),
         Y => 1.0 - 2.0 * (Quat.X * Quat.X + Quat.Z * Quat.Z),
         Z => 2.0 * (Quat.Y * Quat.Z + Quat.S * Quat.X)));
   end Y_Axis;

   function Z_Axis (Quat : in Unit_Quaternion_Type) return Unit_Vector_Type is
   begin
      -- [1], 2.1.1-7
      return (
        (X => 2.0 * (Quat.X * Quat.Z + Quat.S * Quat.Y),
         Y => 2.0 * (Quat.Y * Quat.Z - Quat.S * Quat.X),
         Z => 1.0 - 2.0 * (Quat.Y * Quat.Y + Quat.X * Quat.X)));
   end Z_Axis;

   function Mag (Item : in Unit_Quaternion_Type) return Real_Type is
      -- [1], 2.1.1-5
      use Math_Scalar;
      Result : Real_Type;
      Two_Pi : constant Real_Type := 2.0 * Pi;
   begin
      Result := 2.0 *
                Atan2
                   (Unchecked_Trig_Pair
                       (Mag (Cart_Vector_Type'(Item.X, Item.Y, Item.Z)),
                        Item.S));
      if Result > Pi then
         return Result - Two_Pi;
      elsif Result < -Pi then
         return Result + Two_Pi;
      else
         return Result;
      end if;
   end Mag;

   function Unit_Quaternion_Inverse
     (Item : in Unit_Quaternion_Type)
      return Unit_Quaternion_Type
   is
   begin
      -- [1], 2.1.1-14
      return (X => Item.X, Y => Item.Y, Z => Item.Z, S => -Item.S);
   end Unit_Quaternion_Inverse;

   function "*"
     (Left, Right : in Unit_Quaternion_Type)
      return        Unit_Quaternion_Type
   is
   begin
      -- [1], 2.1.1-12
      return
        (X => Left.S * Right.X +
              Left.X * Right.S +
              Left.Y * Right.Z -
              Left.Z * Right.Y,
         Y => Left.S * Right.Y -
              Left.X * Right.Z +
              Left.Y * Right.S +
              Left.Z * Right.X,
         Z => Left.S * Right.Z +
              Left.X * Right.Y -
              Left.Y * Right.X +
              Left.Z * Right.S,
         S => Left.S * Right.S -
              Left.X * Right.X -
              Left.Y * Right.Y -
              Left.Z * Right.Z);
   end "*";

   function Inverse_Times
     (Left, Right : in Unit_Quaternion_Type)
      return        Unit_Quaternion_Type
   is
   begin
      return
        (X => -Left.S * Right.X +
              Left.X * Right.S +
              Left.Y * Right.Z -
              Left.Z * Right.Y,
         Y => -Left.S * Right.Y -
              Left.X * Right.Z +
              Left.Y * Right.S +
              Left.Z * Right.X,
         Z => -Left.S * Right.Z +
              Left.X * Right.Y -
              Left.Y * Right.X +
              Left.Z * Right.S,
         S => -Left.S * Right.S -
              Left.X * Right.X -
              Left.Y * Right.Y -
              Left.Z * Right.Z);
   end Inverse_Times;

   function Times_Inverse
     (Left, Right : in Unit_Quaternion_Type)
      return        Unit_Quaternion_Type
   is
   begin
      return
        (X => Left.S * Right.X -
              Left.X * Right.S +
              Left.Y * Right.Z -
              Left.Z * Right.Y,
         Y => Left.S * Right.Y -
              Left.X * Right.Z -
              Left.Y * Right.S +
              Left.Z * Right.X,
         Z => Left.S * Right.Z +
              Left.X * Right.Y -
              Left.Y * Right.X -
              Left.Z * Right.S,
         S => -Left.S * Right.S -
              Left.X * Right.X -
              Left.Y * Right.Y -
              Left.Z * Right.Z);
   end Times_Inverse;

   function "*"
     (Left  : in Unit_Quaternion_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type
   is
      A : constant Cart_Vector_Type :=
        (Left.Y * Right (Z) - Left.Z * Right (Y),
         Left.Z * Right (X) - Left.X * Right (Z),
         Left.X * Right (Y) - Left.Y * Right (X));
   begin
      return
        (Right (X) +
         2.0 * (Left.S * A (X) + Left.Y * A (Z) - Left.Z * A (Y)),
         Right (Y) +
         2.0 * (Left.S * A (Y) + Left.Z * A (X) - Left.X * A (Z)),
         Right (Z) +
         2.0 * (Left.S * A (Z) + Left.X * A (Y) - Left.Y * A (X)));
   end "*";

   function Inverse_Times
     (Left  : in Unit_Quaternion_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type
   is
      -- Same as "*", but with Left.S negated.
      A : constant Cart_Vector_Type :=
        (Left.Y * Right (Z) - Left.Z * Right (Y),
         Left.Z * Right (X) - Left.X * Right (Z),
         Left.X * Right (Y) - Left.Y * Right (X));
   begin
      return
        (Right (X) +
         2.0 * (-Left.S * A (X) + Left.Y * A (Z) - Left.Z * A (Y)),
         Right (Y) +
         2.0 * (-Left.S * A (Y) + Left.Z * A (X) - Left.X * A (Z)),
         Right (Z) +
         2.0 * (-Left.S * A (Z) + Left.X * A (Y) - Left.Y * A (X)));
   end Inverse_Times;

   function Inverse_Times
     (Left  : in Unit_Quaternion_Type;
      Right : in Unit_Vector_Type)
      return  Unit_Vector_Type
   is
      -- Same as "*", but with Left.S negated.
      A : constant Cart_Vector_Type :=
        (Left.Y * Right (Z) - Left.Z * Right (Y),
         Left.Z * Right (X) - Left.X * Right (Z),
         Left.X * Right (Y) - Left.Y * Right (X));
   begin
      return
        (Right (X) +
         2.0 * (-Left.S * A (X) + Left.Y * A (Z) - Left.Z * A (Y)),
         Right (Y) +
         2.0 * (-Left.S * A (Y) + Left.Z * A (X) - Left.X * A (Z)),
         Right (Z) +
         2.0 * (-Left.S * A (Z) + Left.X * A (Y) - Left.Y * A (X)));
   end Inverse_Times;

   function Rotate
     (Angle  : in Real_Type;
      Axis   : in Cart_Axis_Type;
      Vector : in Cart_Vector_Type)
      return   Cart_Vector_Type
   is
      use Math_Scalar;
      Trig_A : constant Trig_Pair_Type := Sin_Cos (Angle);
      Cos_A  : Real_Type renames Cos (Trig_A);
      Sin_A  : Real_Type renames Sin (Trig_A);
   begin
      -- from [1], 2.1.1-11, optimized. See DERIVE_MATH_3_DOF.MAC for
      --verification.
      case Axis is
         when X =>
            return
              (Vector (X),
               Cos_A * Vector (Y) - Sin_A * Vector (Z),
               Sin_A * Vector (Y) + Cos_A * Vector (Z));
         when Y =>
            return
              (Cos_A * Vector (X) + Sin_A * Vector (Z),
               Vector (Y),
               -Sin_A * Vector (X) + Cos_A * Vector (Z));
         when Z =>
            return
              (Cos_A * Vector (X) - Sin_A * Vector (Y),
               Sin_A * Vector (X) + Cos_A * Vector (Y),
               Vector (Z));
      end case;
   end Rotate;

   function Rotate
     (Sin_Cos : in Math_Scalar.Trig_Pair_Type;
      Axis    : in Cart_Axis_Type;
      Vector  : in Cart_Vector_Type)
      return    Cart_Vector_Type
   is
      use Math_Scalar;
   begin
      -- from [1], 2.1.1-11, optimized. See DERIVE_MATH_3_DOF.MAC for
      --verification.
      case Axis is
         when X =>
            return
              (Vector (X),
               Cos (Sin_Cos) * Vector (Y) - Sin (Sin_Cos) * Vector (Z),
               Sin (Sin_Cos) * Vector (Y) + Cos (Sin_Cos) * Vector (Z));

         when Y =>
            return
              (Cos (Sin_Cos) * Vector (X) + Sin (Sin_Cos) * Vector (Z),
               Vector (Y),
               -Sin (Sin_Cos) * Vector (X) + Cos (Sin_Cos) * Vector (Z));

         when Z =>
            return
              (Cos (Sin_Cos) * Vector (X) - Sin (Sin_Cos) * Vector (Y),
               Sin (Sin_Cos) * Vector (X) + Cos (Sin_Cos) * Vector (Y),
               Vector (Z));

      end case;
   end Rotate;

   ------------
   -- ZYX_EULER operations

   function To_Zyx_Euler
     (Quaternion : in Unit_Quaternion_Type)
      return       Zyx_Euler_Type
   is
      use Math_Scalar;

      Q : Unit_Quaternion_Type;

      Half_Sum_Zx, Half_Diff_Zx, Theta_Z, Theta_Y, Theta_X : Real_Type;

      Trig_Half_Sum_Zx, Trig_Half_Diff_Zx, Half_Trig_Z, Half_Trig_X :
        Trig_Pair_Type;

   begin
      -- force Q.S > 0.0 to match algorithm derivation.
      if Quaternion.S < 0.0 then
         Q :=
           (X => -Quaternion.X,
            Y => -Quaternion.Y,
            Z => -Quaternion.Z,
            S => -Quaternion.S);
      else
         Q := Quaternion;
      end if;

      if (Q.S + Q.Y) ** 2 + (Q.X - Q.Z) ** 2 < 3.0 * First_Order_Trig or
         (Q.S - Q.Y) ** 2 + (Q.X + Q.Z) ** 2 < 3.0 * First_Order_Trig
      then
         -- at the Euler angle singularity
         Theta_Y := Pi / 2.0;
         Theta_Z := 0.0;
         Theta_X := 2.0 * Atan2 (To_Trig_Pair (Q.X, Q.S));
      else
         Trig_Half_Sum_Zx  := To_Trig_Pair (Q.Z + Q.X, Q.S - Q.Y);
         Trig_Half_Diff_Zx := To_Trig_Pair (Q.Z - Q.X, Q.S + Q.Y);

         Half_Sum_Zx  := Atan2 (Trig_Half_Sum_Zx);
         Half_Diff_Zx := Atan2 (Trig_Half_Diff_Zx);

         Theta_Z := Half_Sum_Zx + Half_Diff_Zx;
         Theta_X := Half_Sum_Zx - Half_Diff_Zx;

         Half_Trig_Z := Half_Trig (Trig_Half_Sum_Zx + Trig_Half_Diff_Zx);
         Half_Trig_X := Half_Trig (Trig_Half_Sum_Zx - Trig_Half_Diff_Zx);

         Theta_Y :=
           2.0 *
           Atan2
              (To_Trig_Pair
                  (Cos (Half_Trig_Z) * Cos (Half_Trig_X) * Q.Y -
                   Sin (Half_Trig_Z) * Cos (Half_Trig_X) * Q.X -
                   Cos (Half_Trig_Z) * Sin (Half_Trig_X) * Q.Z +
                   Sin (Half_Trig_Z) * Sin (Half_Trig_X) * Q.S,
                   Cos (Half_Trig_Z) * Cos (Half_Trig_X) * Q.S +
                   Sin (Half_Trig_Z) * Cos (Half_Trig_X) * Q.Z +
                   Cos (Half_Trig_Z) * Sin (Half_Trig_X) * Q.X +
                   Sin (Half_Trig_Z) * Sin (Half_Trig_X) * Q.Y));
      end if;
      return (Theta_Z, Theta_Y, Theta_X);
   end To_Zyx_Euler;

   function To_Unit_Quaternion
     (Euler : in Zyx_Euler_Type)
      return  Unit_Quaternion_Type
   is
   begin
      return To_Unit_Quaternion (Euler.Theta_Z, Z) *
             To_Unit_Quaternion (Euler.Theta_Y, Y) *
             To_Unit_Quaternion (Euler.Theta_X, X);
   end To_Unit_Quaternion;

   function To_Celestial
     (N    : in Unit_Vector_Type)
      return Celestial_Coordinate_Type
   is
      -- See [2] section E.1. But first check for the singularity, use
      -- atan2, allow for round-off errors making the elements
      -- slightly greater than 1.0, and optimize for r = 1.0.
      use Math_Scalar, Elementary;
      Clipped_Z   : constant Real_Type :=
         Real_Type'Max (-1.0, Real_Type'Min (1.0, N (Z)));
      Declination : constant Real_Type := Pi / 2.0 - Arccos (Clipped_Z);
      Ra          : Real_Type;
   begin
      if N (X) = 0.0 and N (Y) = 0.0 then
         return (Right_Ascension => 0.0, Declination => Declination);
      else
         Ra := Atan2 (Unchecked_Trig_Pair (N (Y), N (X)));
         if Ra < 0.0 then
            Ra := Ra + 2.0 * Pi;
         end if;
         return (Right_Ascension => Ra, Declination => Declination);
      end if;
   end To_Celestial;

   function To_Unit_Vector
     (Celestial : in Celestial_Coordinate_Type)
      return      Unit_Vector_Type
   is
      use Math_Scalar;
      Trig_Ra    : constant Trig_Pair_Type :=
         Sin_Cos (Celestial.Right_Ascension);
      Trig_Theta : constant Trig_Pair_Type :=
         Sin_Cos (Pi / 2.0 - Celestial.Declination);
   begin
      -- see [2] section E.1, optimize for r = 1.0.
      return
        (X => Sin (Trig_Theta) * Cos (Trig_Ra),
         Y => Sin (Trig_Theta) * Sin (Trig_Ra),
         Z => Cos (Trig_Theta));
   end To_Unit_Vector;

   ---------------
   -- general matrices for random purposes.

   function Inverse
     (Item : in Cart_Array_Cart_Vector_Type)
      return Cart_Array_Cart_Vector_Type
   is
      Det : constant Real_Type :=
         (Item (X) (X) *
          ((Item (Y) (Y) * Item (Z) (Z)) -
           (Item (Y) (Z)) * (Item (Z) (Y)))) -
         (Item (X) (Y) *
          ((Item (Y) (X) * Item (Z) (Z)) -
           (Item (Y) (Z)) * (Item (Z) (X)))) +
         (Item (X) (Z) *
          ((Item (Y) (X) * Item (Z) (Y)) -
           (Item (Y) (Y)) * (Item (Z) (X))));

   begin
      return
        (X => (X =>
        ((Item (Y) (Y) * Item (Z) (Z)) -
         (Item (Y) (Z) * Item (Z) (Y))) /
        Det,
               Y =>
        -((Item (X) (Y) * Item (Z) (Z)) -
          (Item (X) (Z) * Item (Z) (Y))) /
         Det,
               Z =>
        ((Item (X) (Y) * Item (Y) (Z)) -
         (Item (X) (Z) * Item (Y) (Y))) /
        Det),

         Y => (X =>
        -((Item (Y) (X) * Item (Z) (Z)) -
          (Item (Y) (Z) * Item (Z) (X))) /
         Det,
               Y =>
        ((Item (X) (X) * Item (Z) (Z)) -
         (Item (X) (Z) * Item (Z) (X))) /
        Det,
               Z =>
        -((Item (X) (X) * Item (Y) (Z)) -
          (Item (X) (Z) * Item (Y) (X))) /
         Det),

         Z => (X =>
        ((Item (Y) (X) * Item (Z) (Y)) -
         (Item (Y) (Y) * Item (Z) (X))) /
        Det,
               Y =>
        -((Item (X) (X) * Item (Z) (Y)) -
          (Item (X) (Y) * Item (Z) (X))) /
         Det,
               Z =>
        ((Item (X) (X) * Item (Y) (Y)) -
         (Item (X) (Y) * Item (Y) (X))) /
        Det));
   end Inverse;

   ------------------
   -- rotation matrices

   function To_Cart_Array_Cart_Vector
     (Item : in Rot_Matrix_Type)
      return Cart_Array_Cart_Vector_Type
   is
   begin
      return Cart_Array_Cart_Vector_Type (Item);
   end To_Cart_Array_Cart_Vector;

   function To_Rot_Matrix
     (Item : in Cart_Array_Cart_Vector_Type)
      return Rot_Matrix_Type
   is
      -- This algorithm is not very good, because it ignores the third row.
      -- Ni = Normalized vector; Ui = unNormalized vector
      use Cart_Vector_Ops;
      Nx : Unit_Vector_Type;
      Ny : Unit_Vector_Type;
      Nz : Cart_Vector_Type;
      Uy : constant Cart_Vector_Type :=
        (Item (Y) (X),
         Item (Y) (Y),
         Item (Y) (Z));
   begin
      Nx :=
         To_Unit_Vector
           (Cart_Vector_Type'(Item (X) (X), Item (X) (Y), Item (X) (Z)));
      Ny := To_Unit_Vector (Uy - Nx * (Nx * Uy));
      Nz := Cross (Nx, Ny);
      return ((X (Nx), Y (Nx), Z (Nx)), (X (Ny), Y (Ny), Z (Ny)), Nz);
   exception
      when Non_Normalizable_Unit_Vector =>
         raise Non_Normalizable_Rot_Matrix;
   end To_Rot_Matrix;

   function Unchecked_Rot_Matrix
     (Item : in Cart_Array_Cart_Vector_Type)
      return Rot_Matrix_Type
   is
   begin
      return Rot_Matrix_Type (Item);
   end Unchecked_Rot_Matrix;

   function Unit_Quaternion_To_Rot_Matrix
     (Quaternion : in Unit_Quaternion_Type)
      return       Rot_Matrix_Type
   is
      -- [1], 2.1.1-7
      Q : Unit_Quaternion_Type renames Quaternion;
   begin
      return
        (X => (X => 1.0 - 2.0 * (Q.Z * Q.Z + Q.Y * Q.Y),
               Y => 2.0 * (Q.X * Q.Y - Q.S * Q.Z),
               Z => 2.0 * (Q.X * Q.Z + Q.S * Q.Y)),
         Y => (X => 2.0 * (Q.S * Q.Z + Q.X * Q.Y),
               Y => 1.0 - 2.0 * (Q.Z * Q.Z + Q.X * Q.X),
               Z => 2.0 * (Q.Y * Q.Z - Q.S * Q.X)),
         Z => (X => 2.0 * (Q.X * Q.Z - Q.S * Q.Y),
               Y => 2.0 * (Q.Y * Q.Z + Q.S * Q.X),
               Z => 1.0 - 2.0 * (Q.Y * Q.Y + Q.X * Q.X)));
   end Unit_Quaternion_To_Rot_Matrix;

   function Rot_Matrix_To_Unit_Quaternion
     (Rot_Matrix : in Rot_Matrix_Type)
      return       Unit_Quaternion_Type
   is
      M : Rot_Matrix_Type renames Rot_Matrix;
      A : constant Real_Type := M (X) (X) + M (Y) (Y) + M (Z) (Z);
      B : constant Real_Type := M (X) (X) - M (Y) (Y) - M (Z) (Z);
      C : constant Real_Type := -M (X) (X) + M (Y) (Y) - M (Z) (Z);
      D : constant Real_Type := -M (X) (X) - M (Y) (Y) + M (Z) (Z);
      E : Real_Type;
   begin

      if A >= Real_Type'Max (B, Real_Type'Max (C, D)) then
         E := 2.0 * Elementary.Sqrt (1.0 + A);
         return
           (X => (M (Z) (Y) - M (Y) (Z)) / E,
            Y => (M (X) (Z) - M (Z) (X)) / E,
            Z => (M (Y) (X) - M (X) (Y)) / E,
            S => E / 4.0);

      elsif B >= Real_Type'Max (A, Real_Type'Max (C, D)) then
         E := 2.0 * Elementary.Sqrt (1.0 + B);
         return
           (X => E / 4.0,
            Y => (M (X) (Y) + M (Y) (X)) / E,
            Z => (M (X) (Z) + M (Z) (X)) / E,
            S => (M (Z) (Y) - M (Y) (Z)) / E);

      elsif C >= Real_Type'Max (A, Real_Type'Max (B, D)) then
         E := 2.0 * Elementary.Sqrt (1.0 + C);
         return
           (X => (M (X) (Y) + M (Y) (X)) / E,
            Y => E / 4.0,
            Z => (M (Y) (Z) + M (Z) (Y)) / E,
            S => (M (X) (Z) - M (Z) (X)) / E);
      else
         E := 2.0 * Elementary.Sqrt (1.0 + D);
         return
           (X => (M (X) (Z) + M (Z) (X)) / E,
            Y => (M (Y) (Z) + M (Z) (Y)) / E,
            Z => E / 4.0,
            S => (M (Y) (X) - M (X) (Y)) / E);
      end if;
   end Rot_Matrix_To_Unit_Quaternion;

   function Mag_Axis_To_Rot_Matrix
     (Mag_Axis : in Mag_Axis_Type)
      return     Rot_Matrix_Type
   is
      -- [1], 2.1.1-4
      use Math_Scalar;
      Trig : constant Trig_Pair_Type := Sin_Cos (Mag_Axis.Mag);
      Sin  : Real_Type renames Math_Scalar.Sin (Trig);
      Cos  : Real_Type renames Math_Scalar.Cos (Trig);
      Vers : constant Real_Type      := 1.0 - Cos;
      N    : Unit_Vector_Type renames Mag_Axis.Axis;
   begin
      return
        (X => (X => Cos + N (X) * N (X) * Vers,
               Y => -N (Z) * Sin + N (X) * N (Y) * Vers,
               Z => N (Y) * Sin + N (X) * N (Z) * Vers),
         Y => (X => N (Z) * Sin + N (X) * N (Y) * Vers,
               Y => Cos + N (Y) * N (Y) * Vers,
               Z => -N (X) * Sin + N (Y) * N (Z) * Vers),
         Z => (X => -N (Y) * Sin + N (X) * N (Z) * Vers,
               Y => N (X) * Sin + N (Y) * N (Z) * Vers,
               Z => Cos + N (Z) * N (Z) * Vers));
   end Mag_Axis_To_Rot_Matrix;

   function Rot_Matrix_To_Mag_Axis
     (Rot_Matrix : in Rot_Matrix_Type)
      return       Mag_Axis_Type
   is
      use Math_Scalar, Cart_Vector_Ops;
      Temp_Axis : constant Cart_Vector_Type :=
        (Rot_Matrix (Z) (Y) - Rot_Matrix (Y) (Z),
         Rot_Matrix (X) (Z) - Rot_Matrix (Z) (X),
         Rot_Matrix (Y) (X) - Rot_Matrix (X) (Y));
      Cos_Mag   : constant Real_Type        :=
         (Rot_Matrix (X) (X) +
          Rot_Matrix (Y) (Y) +
          Rot_Matrix (Z) (Z) -
          1.0) *
         0.5;
      Sin_Mag   : constant Real_Type        := Mag (Temp_Axis) * 0.5;
   begin
      --  Note max (Temp_Axis) = 1.0, so division is only a problem if
      --  Sin_Mag is identically zero.
      if Sin_Mag > 0.0 then
         return
           (Mag  => Atan2 (Unchecked_Trig_Pair (Sin_Mag, Cos_Mag)),
            Axis => Unchecked_Unit_Vector (Temp_Axis / (2.0 * Sin_Mag)));

      else
         -- Magnitude is 0.0; pick arbitrary axis.
         return (0.0, X_Unit);
      end if;
   end Rot_Matrix_To_Mag_Axis;

   function Mag (Item : in Rot_Matrix_Type) return Real_Type is
      use Math_Scalar;
      Temp_Axis : constant Cart_Vector_Type :=
        (Item (Z) (Y) - Item (Y) (Z),
         Item (X) (Z) - Item (Z) (X),
         Item (Y) (X) - Item (X) (Y));
      Cos_Mag   : constant Real_Type        :=
         (Item (X) (X) + Item (Y) (Y) + Item (Z) (Z) - 1.0) * 0.5;
      Sin_Mag   : constant Real_Type        := Mag (Temp_Axis) * 0.5;
   begin
      if Sin_Mag > 0.0 then
         return Atan2 (To_Trig_Pair (Sin_Mag, Cos_Mag));
      elsif Cos_Mag > 0.0 then
         return 0.0;
      else
         return Pi;
      end if;
   end Mag;

   function Inverse (Item : in Rot_Matrix_Type) return Rot_Matrix_Type is
   begin
      -- [1], 2.1.1-13
      return
        ((Item (X) (X), Item (Y) (X), Item (Z) (X)),
         (Item (X) (Y), Item (Y) (Y), Item (Z) (Y)),
         (Item (X) (Z), Item (Y) (Z), Item (Z) (Z)));
   end Inverse;

   function Rot_Matrix_Times_Rot_Matrix
     (Left, Right : in Rot_Matrix_Type)
      return        Rot_Matrix_Type
   is
   begin
      return Rot_Matrix_Type (Cacv_Ops. "*"
                                 (Cart_Array_Cart_Vector_Type (Left),
                                  Cart_Array_Cart_Vector_Type (Right)));
   end Rot_Matrix_Times_Rot_Matrix;

   function Inverse_Times
     (Left, Right : in Rot_Matrix_Type)
      return        Rot_Matrix_Type
   is
   begin
      return Rot_Matrix_Type (Cacv_Ops.Transpose_Times
                                 (Cart_Array_Cart_Vector_Type (Left),
                                  Cart_Array_Cart_Vector_Type (Right)));
   end Inverse_Times;

   function Times_Inverse
     (Left, Right : in Rot_Matrix_Type)
      return        Rot_Matrix_Type
   is
   begin
      return Rot_Matrix_Type (Cacv_Ops.Times_Transpose
                                 (Cart_Array_Cart_Vector_Type (Left),
                                  Cart_Array_Cart_Vector_Type (Right)));
   end Times_Inverse;

   function Rot_Matrix_Times_Cacv
     (Left  : in Rot_Matrix_Type;
      Right : in Cart_Array_Cart_Vector_Type)
      return  Cart_Array_Cart_Vector_Type
   is
   begin
      return Cacv_Ops. "*" (Cart_Array_Cart_Vector_Type (Left), Right);
   end Rot_Matrix_Times_Cacv;

   function Cacv_Times_Rot_Matrix
     (Left  : in Cart_Array_Cart_Vector_Type;
      Right : in Rot_Matrix_Type)
      return  Cart_Array_Cart_Vector_Type
   is
   begin
      return Cacv_Ops. "*" (Left, Cart_Array_Cart_Vector_Type (Right));
   end Cacv_Times_Rot_Matrix;

   function Rot_Matrix_Times_Cart_Vector
     (Left  : in Rot_Matrix_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type
   is
   begin
      return Cacv_Ops. "*" (Cart_Array_Cart_Vector_Type (Left), Right);
   end Rot_Matrix_Times_Cart_Vector;

   function Inverse_Times
     (Left  : in Rot_Matrix_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type
   is
   begin
      return Cacv_Ops.Transpose_Times
               (Cart_Array_Cart_Vector_Type (Left),
                Right);
   end Inverse_Times;

   --------------
   -- inertias

   function To_Cart_Array_Cart_Vector
     (Item : in Inertia_Type)
      return Cart_Array_Cart_Vector_Type
   is
   begin
      return
        (X => (Item (Ixx), Item (Ixy), Item (Ixz)),
         Y => (Item (Ixy), Item (Iyy), Item (Iyz)),
         Z => (Item (Ixz), Item (Iyz), Item (Izz)));
   end To_Cart_Array_Cart_Vector;

   function "+" (Left, Right : in Inertia_Type) return Inertia_Type is
   begin
      return
        (Ixx => Left (Ixx) + Right (Ixx),
         Iyy => Left (Iyy) + Right (Iyy),
         Izz => Left (Izz) + Right (Izz),
         Ixy => Left (Ixy) + Right (Ixy),
         Ixz => Left (Ixz) + Right (Ixz),
         Iyz => Left (Iyz) + Right (Iyz));
   end "+";

   function "-" (Left, Right : in Inertia_Type) return Inertia_Type is
   begin
      return
        (Ixx => Left (Ixx) - Right (Ixx),
         Iyy => Left (Iyy) - Right (Iyy),
         Izz => Left (Izz) - Right (Izz),
         Ixy => Left (Ixy) - Right (Ixy),
         Ixz => Left (Ixz) - Right (Ixz),
         Iyz => Left (Iyz) - Right (Iyz));
   end "-";

   function "*"
     (Left  : in Inertia_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type
   is
   begin
      return
        (X => Left (Ixx) * Right (X) +
              Left (Ixy) * Right (Y) +
              Left (Ixz) * Right (Z),
         Y => Left (Ixy) * Right (X) +
              Left (Iyy) * Right (Y) +
              Left (Iyz) * Right (Z),
         Z => Left (Ixz) * Right (X) +
              Left (Iyz) * Right (Y) +
              Left (Izz) * Right (Z));
   end "*";

   function Inverse (Item : in Inertia_Type) return Inverse_Inertia_Type is
      --  See ../Maxima/derive_math_dof_3.maxima for derivation
      T_1 : constant Real_Type :=
         Item (Iyy) * Item (Izz) - Item (Iyz) * Item (Iyz);
      T_2 : constant Real_Type :=
         Item (Ixy) * Item (Iyz) - Item (Ixz) * Item (Iyy);
      T_3 : constant Real_Type :=
         Item (Ixz) * Item (Iyz) - Item (Ixy) * Item (Izz);
      T_4 : constant Real_Type :=
         1.0 / (Item (Ixx) * T_1 + Item (Ixy) * T_3 + Item (Ixz) * T_2);
      T_5 : constant Real_Type := T_3 * T_4;
      T_6 : constant Real_Type := T_2 * T_4;
      T_7 : constant Real_Type :=
         (Item (Ixy) * Item (Ixz) - Item (Ixx) * Item (Iyz)) * T_4;

   begin
      return
        (Ixx => T_1 * T_4,
         Ixy => T_5,
         Ixz => T_6,
         Iyy => (Item (Ixx) * Item (Izz) - Item (Ixz) * Item (Ixz)) *
                T_4,
         Iyz => T_7,
         Izz => (Item (Ixx) * Item (Iyy) - Item (Ixy) * Item (Ixy)) *
                T_4);
   end Inverse;

   function "*"
     (Left  : in Inverse_Inertia_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type
   is
   begin
      return
        (X => Left (Ixx) * Right (X) +
              Left (Ixy) * Right (Y) +
              Left (Ixz) * Right (Z),
         Y => Left (Ixy) * Right (X) +
              Left (Iyy) * Right (Y) +
              Left (Iyz) * Right (Z),
         Z => Left (Ixz) * Right (X) +
              Left (Iyz) * Right (Y) +
              Left (Izz) * Right (Z));
   end "*";

   function Unit_Quat_Times_Inertia
     (Left  : in Unit_Quaternion_Type;
      Right : in Inertia_Type)
      return  Inertia_Type
   is
   begin
      return Rot_Matrix_Times_Inertia (To_Rot_Matrix (Left), Right);
   end Unit_Quat_Times_Inertia;

   function Rot_Matrix_Times_Inertia
     (Left  : in Rot_Matrix_Type;
      Right : in Inertia_Type)
      return  Inertia_Type
   is
      use Cacv_Ops;
      Left_Matrix   : constant Cart_Array_Cart_Vector_Type :=
         Cart_Array_Cart_Vector_Type (Left);
      Middle_Matrix : constant Cart_Array_Cart_Vector_Type := To_Cacv (Right);
      Temp          : Cart_Array_Cart_Vector_Type;
   begin
      Temp := Times_Transpose (Left_Matrix * Middle_Matrix, Left_Matrix);
      return
        (Ixx => Temp (X) (X),
         Iyy => Temp (Y) (Y),
         Izz => Temp (Z) (Z),
         Ixy => Temp (X) (Y),
         Ixz => Temp (X) (Z),
         Iyz => Temp (Y) (Z));
   end Rot_Matrix_Times_Inertia;

   function Parallel_Axis
     (Total_Mass     : in Real_Type;
      Center_Of_Mass : in Cart_Vector_Type;
      Inertia        : in Inertia_Type)
      return           Inertia_Type
   is
   begin
      -- [1], 2.1.5-2,3,4
      return
        (Ixx => Inertia (Ixx) +
                Total_Mass *
                (Center_Of_Mass (Y) * Center_Of_Mass (Y) +
                 Center_Of_Mass (Z) * Center_Of_Mass (Z)),
         Iyy => Inertia (Iyy) +
                Total_Mass *
                (Center_Of_Mass (Z) * Center_Of_Mass (Z) +
                 Center_Of_Mass (X) * Center_Of_Mass (X)),
         Izz => Inertia (Izz) +
                Total_Mass *
                (Center_Of_Mass (X) * Center_Of_Mass (X) +
                 Center_Of_Mass (Y) * Center_Of_Mass (Y)),
         Ixy => Inertia (Ixy) -
                Total_Mass * Center_Of_Mass (X) * Center_Of_Mass (Y),
         Ixz => Inertia (Ixz) -
                Total_Mass * Center_Of_Mass (X) * Center_Of_Mass (Z),
         Iyz => Inertia (Iyz) -
                Total_Mass * Center_Of_Mass (Y) * Center_Of_Mass (Z));
   end Parallel_Axis;

end Sal.Gen_Math.Gen_Dof_3;
