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
package body Sal.Gen_Math.Gen_Dof_6 is

   -- Private subprograms

   function To_Rot_Cross
     (Inverse_Rot : in Math_Dof_3.Cart_Array_Cart_Vector_Type;
      Tran        : in Math_Dof_3.Cart_Vector_Type)
      return        Math_Dof_3.Cart_Array_Cart_Vector_Type
      --  return the Rot_Cross part of a propagator, given the inverse of the
      --rotation part of the pose.
   is
      use Math_Dof_3, Math_Scalar;
   begin
      return
        (X => (X => Inverse_Rot (X) (Z) * Tran (Y) -
                    Inverse_Rot (X) (Y) * Tran (Z),
               Y => Inverse_Rot (X) (X) * Tran (Z) -
                    Inverse_Rot (X) (Z) * Tran (X),
               Z => Inverse_Rot (X) (Y) * Tran (X) -
                    Inverse_Rot (X) (X) * Tran (Y)),
         Y => (X => Inverse_Rot (Y) (Z) * Tran (Y) -
                    Inverse_Rot (Y) (Y) * Tran (Z),
               Y => Inverse_Rot (Y) (X) * Tran (Z) -
                    Inverse_Rot (Y) (Z) * Tran (X),
               Z => Inverse_Rot (Y) (Y) * Tran (X) -
                    Inverse_Rot (Y) (X) * Tran (Y)),
         Z => (X => Inverse_Rot (Z) (Z) * Tran (Y) -
                    Inverse_Rot (Z) (Y) * Tran (Z),
               Y => Inverse_Rot (Z) (X) * Tran (Z) -
                    Inverse_Rot (Z) (Z) * Tran (X),
               Z => Inverse_Rot (Z) (Y) * Tran (X) -
                    Inverse_Rot (Z) (X) * Tran (Y)));
   end To_Rot_Cross;

   ----------
   -- public subprograms

   -- Dual_Float_Type operations

   function "<=" (Left, Right : in Dual_Real_Type) return Boolean is
   begin
      return Left (Tran) <= Right (Tran) and Left (Rot) <= Right (Rot);
   end "<=";

   ----------
   -- Dual_Cart_Vector_Type operations

   function Translation
     (Item : in Dual_Cart_Vector_Type)
      return Math_Dof_3.Cart_Vector_Type
   is
   begin
      return (Item (Tx), Item (Ty), Item (Tz));
   end Translation;

   function Rotation
     (Item : in Dual_Cart_Vector_Type)
      return Math_Dof_3.Cart_Vector_Type
   is
   begin
      return (Item (Rx), Item (Ry), Item (Rz));
   end Rotation;

   function Concat
     (Translation, Rotation : in Math_Dof_3.Cart_Vector_Type)
      return                  Dual_Cart_Vector_Type
   is
      use Math_Dof_3;
   begin
      return
        (Tx => Translation (X),
         Ty => Translation (Y),
         Tz => Translation (Z),
         Rx => Rotation (X),
         Ry => Rotation (Y),
         Rz => Rotation (Z));
   end Concat;

   function Mag (Item : in Dual_Cart_Vector_Type) return Dual_Real_Type is
   begin
      return
        (Elementary.Sqrt
            (Item (Tx) * Item (Tx) +
             Item (Ty) * Item (Ty) +
             Item (Tz) * Item (Tz)),
         Elementary.Sqrt
            (Item (Rx) * Item (Rx) +
             Item (Ry) * Item (Ry) +
             Item (Rz) * Item (Rz)));
   end Mag;

   function "*"
     (Left  : in Dual_Real_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
   begin
      return
        (Left (Tran) * Right (Tx),
         Left (Tran) * Right (Ty),
         Left (Tran) * Right (Tz),
         Left (Rot) * Right (Rx),
         Left (Rot) * Right (Ry),
         Left (Rot) * Right (Rz));
   end "*";

   function "*"
     (Left  : in Dual_Cart_Vector_Type;
      Right : in Dual_Real_Type)
      return  Dual_Cart_Vector_Type
   is
   begin
      return
        (Left (Tx) * Right (Tran),
         Left (Ty) * Right (Tran),
         Left (Tz) * Right (Tran),
         Left (Rx) * Right (Rot),
         Left (Ry) * Right (Rot),
         Left (Rz) * Right (Rot));
   end "*";

   function "/"
     (Left  : in Dual_Cart_Vector_Type;
      Right : in Dual_Real_Type)
      return  Dual_Cart_Vector_Type
   is
   begin
      return
        (Left (Tx) / Right (Tran),
         Left (Ty) / Right (Tran),
         Left (Tz) / Right (Tran),
         Left (Rx) / Right (Rot),
         Left (Ry) / Right (Rot),
         Left (Rz) / Right (Rot));
   end "/";

   function "*"
     (Left  : in Math_Dof_3.Unit_Quaternion_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3;
   begin
      return Left * Translation (Right) & Left * Rotation (Right);
   end "*";

   function Inverse_Times
     (Left  : in Math_Dof_3.Unit_Quaternion_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3;
   begin
      return Inverse_Times (Left, Translation (Right)) &
             Inverse_Times (Left, Rotation (Right));
   end Inverse_Times;

   ----------
   -- Pose_Type operations

   function To_Dual_Cart_Vector
     (Pose : in Pose_Type)
      return Dual_Cart_Vector_Type
   is
      use Math_Dof_3;
   begin
      return Pose.Translation & To_Rot_Vector (Pose.Rotation);
   end To_Dual_Cart_Vector;

   function To_Pose
     (Dual_Cart_Vector : in Dual_Cart_Vector_Type)
      return             Pose_Type
   is
      use Math_Dof_3;
   begin
      return
        (Translation (Dual_Cart_Vector),
         To_Unit_Quaternion (Rotation (Dual_Cart_Vector)));
   end To_Pose;

   function Mag (Item : in Pose_Type) return Dual_Real_Type is
      use Math_Dof_3;
   begin
      return (Mag (Item.Translation), Mag (Item.Rotation));
   end Mag;

   function Inverse (Item : in Pose_Type) return Pose_Type is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return
        (-(Inverse_Times (Item.Rotation, Item.Translation)),
         Inverse (Item.Rotation));
   end Inverse;

   function "*" (Left, Right : in Pose_Type) return Pose_Type is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return
        (Left.Translation + Left.Rotation * Right.Translation,
         Left.Rotation * Right.Rotation);
   end "*";

   function "*"
     (Left  : in Math_Dof_3.Unit_Quaternion_Type;
      Right : in Pose_Type)
      return  Pose_Type
   is
      use Math_Dof_3;
   begin
      return (Left * Right.Translation, Left * Right.Rotation);
   end "*";

   function "*"
     (Left  : in Pose_Type;
      Right : in Math_Dof_3.Unit_Quaternion_Type)
      return  Pose_Type
   is
      use Math_Dof_3;
   begin
      return (Left.Translation, Left.Rotation * Right);
   end "*";

   function "*"
     (Left  : in Pose_Type;
      Right : in Math_Dof_3.Cart_Vector_Type)
      return  Math_Dof_3.Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return Left.Translation + Left.Rotation * Right;
   end "*";

   function Inverse_Times (Left, Right : in Pose_Type) return Pose_Type is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return
        (Inverse_Times (Left.Rotation, Right.Translation) -
         Inverse_Times (Left.Rotation, Left.Translation),
         Inverse_Times (Left.Rotation, Right.Rotation));
   end Inverse_Times;

   function "-" (Left, Right : in Pose_Type) return Dual_Cart_Vector_Type is
      Diff : constant Pose_Type := Inverse_Times (Right, Left);
   begin
      return Diff.Translation & Math_Dof_3.To_Rot_Vector (Diff.Rotation);
   end "-";

   function "+"
     (Left  : in Pose_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Pose_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return
        (Left.Translation + Left.Rotation * Translation (Right),
         Left.Rotation * To_Unit_Quaternion (Rotation (Right)));
   end "+";

   function "+"
     (Left  : in Pose_Type;
      Right : in Math_Dof_3.Cart_Vector_Type)
      return  Pose_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return (Left.Translation + Left.Rotation * Right, Left.Rotation);
   end "+";

   function "-"
     (Left  : in Pose_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Pose_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
      -- see derive_math_6_dof.mac
      Delta_Rot : constant Unit_Quaternion_Type :=
         Times_Inverse
           (Left.Rotation,
            To_Unit_Quaternion (Rotation (Right)));
   begin
      return (Left.Translation - Delta_Rot * Translation (Right), Delta_Rot);
   end "-";

   function "+"
     (Left  : in Dual_Cart_Vector_Type;
      Right : in Pose_Type)
      return  Pose_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
      Left_Rot : constant Unit_Quaternion_Type :=
         To_Unit_Quaternion (Rotation (Left));
   begin
      return
        (Translation (Left) + Left_Rot * Right.Translation,
         Left_Rot * Right.Rotation);
   end "+";

   function "+"
     (Left  : in Math_Dof_3.Cart_Vector_Type;
      Right : in Pose_Type)
      return  Pose_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return (Left + Right.Translation, Right.Rotation);
   end "+";

   -----------
   -- wrench and rate transforms

   function Unchecked_Rate_Transform
     (Rot, Rot_Cross : Math_Dof_3.Cart_Array_Cart_Vector_Type)
      return           Rate_Transform_Type
   is
   begin
      return (Rot, Rot_Cross);
   end Unchecked_Rate_Transform;

   function Unchecked_Wrench_Transform
     (Rot, Rot_Cross : Math_Dof_3.Cart_Array_Cart_Vector_Type)
      return           Wrench_Transform_Type
   is
   begin
      return (Rot, Rot_Cross);
   end Unchecked_Wrench_Transform;

   function To_Rate_Transform
     (Item : in Pose_Type)
      return Rate_Transform_Type
   is
      use Math_Dof_3;
      Inverse_Rot : constant Cart_Array_Cart_Vector_Type :=
         To_Cacv (To_Rot_Matrix (Inverse (Item.Rotation)));
   begin
      return (Inverse_Rot, To_Rot_Cross (Inverse_Rot, Item.Translation));
   end To_Rate_Transform;

   function To_Wrench_Transform
     (Item : in Pose_Type)
      return Wrench_Transform_Type
   is
      use Math_Dof_3;
      Inverse_Rot : constant Cart_Array_Cart_Vector_Type :=
         To_Cacv (To_Rot_Matrix (Inverse (Item.Rotation)));
   begin
      return (Inverse_Rot, To_Rot_Cross (Inverse_Rot, Item.Translation));
   end To_Wrench_Transform;

   function To_Rate_Transform
     (Translation : in Math_Dof_3.Cart_Vector_Type;
      Rotation    : in Math_Dof_3.Rot_Matrix_Type)
      return        Rate_Transform_Type
   is
      use Math_Dof_3;
      Inverse_Rot : constant Cart_Array_Cart_Vector_Type :=
         To_Cacv (Inverse (Rotation));
   begin
      return (Inverse_Rot, To_Rot_Cross (Inverse_Rot, Translation));
   end To_Rate_Transform;

   function To_Wrench_Transform
     (Translation : in Math_Dof_3.Cart_Vector_Type;
      Rotation    : in Math_Dof_3.Rot_Matrix_Type)
      return        Wrench_Transform_Type
   is
      use Math_Dof_3;
      Inverse_Rot : constant Cart_Array_Cart_Vector_Type :=
         To_Cacv (Inverse (Rotation));
   begin
      return (Inverse_Rot, To_Rot_Cross (Inverse_Rot, Translation));
   end To_Wrench_Transform;

   function To_Dc_Array_Dcv
     (Item : in Rate_Transform_Type)
      return Dc_Array_Dcv_Type
   is
      use Math_Dof_3;
   begin
      return
        (Tx => Item.Rot (X) & Item.Rot_Cross (X),
         Ty => Item.Rot (Y) & Item.Rot_Cross (Y),
         Tz => Item.Rot (Z) & Item.Rot_Cross (Z),
         Rx => Zero_Cart_Vector & Item.Rot (X),
         Ry => Zero_Cart_Vector & Item.Rot (Y),
         Rz => Zero_Cart_Vector & Item.Rot (Z));
   end To_Dc_Array_Dcv;

   function To_Dc_Array_Dcv
     (Item : in Wrench_Transform_Type)
      return Dc_Array_Dcv_Type
   is
      use Math_Dof_3;
   begin
      return
        (Tx => Item.Rot (X) & Zero_Cart_Vector,
         Ty => Item.Rot (Y) & Zero_Cart_Vector,
         Tz => Item.Rot (Z) & Zero_Cart_Vector,
         Rx => Item.Rot_Cross (X) & Item.Rot (X),
         Ry => Item.Rot_Cross (Y) & Item.Rot (Y),
         Rz => Item.Rot_Cross (Z) & Item.Rot (Z));
   end To_Dc_Array_Dcv;

   function Inverse_Transpose
     (Right : in Rate_Transform_Type)
      return  Wrench_Transform_Type
   is
   begin
      return (Right.Rot, Right.Rot_Cross);
   end Inverse_Transpose;

   function Inverse_Transpose
     (Right : in Wrench_Transform_Type)
      return  Rate_Transform_Type
   is
   begin
      return (Right.Rot, Right.Rot_Cross);
   end Inverse_Transpose;

   function "*"
     (Left, Right : in Rate_Transform_Type)
      return        Rate_Transform_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops, Math_Dof_3.Cacv_Ops;
   begin
      return
        (Left.Rot * Right.Rot,
         Left.Rot * Right.Rot_Cross + Left.Rot_Cross * Right.Rot);
   end "*";

   function "*"
     (Left  : in Rate_Transform_Type;
      Right : in Dc_Array_Dcv_Type)
      return  Dc_Array_Dcv_Type
   is
      use Dc_Array_Dcv_Ops;
   begin
      return To_Dc_Array_Dcv (Left) * Right;
   end "*";

   function "*"
     (Left  : in Dc_Array_Dcv_Type;
      Right : in Rate_Transform_Type)
      return  Dc_Array_Dcv_Type
   is
      use Dc_Array_Dcv_Ops;
   begin
      return Left * To_Dc_Array_Dcv (Right);
   end "*";

   function "*"
     (Left, Right : in Wrench_Transform_Type)
      return        Wrench_Transform_Type
   is
      use Math_Dof_3.Cart_Vector_Ops, Math_Dof_3.Cacv_Ops;
   begin
      return
        (Left.Rot * Right.Rot,
         Left.Rot_Cross * Right.Rot + Left.Rot * Right.Rot_Cross);
   end "*";

   function "*"
     (Left  : in Wrench_Transform_Type;
      Right : in Dc_Array_Dcv_Type)
      return  Dc_Array_Dcv_Type
   is
      use Dc_Array_Dcv_Ops;
   begin
      return To_Dc_Array_Dcv (Left) * Right;
   end "*";

   function "*"
     (Left  : in Dc_Array_Dcv_Type;
      Right : in Wrench_Transform_Type)
      return  Dc_Array_Dcv_Type
   is
      use Dc_Array_Dcv_Ops;
   begin
      return Left * To_Dc_Array_Dcv (Right);
   end "*";

   function "*"
     (Left  : in Rate_Transform_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3.Cart_Vector_Ops, Math_Dof_3.Cacv_Ops;
   begin
      return (Left.Rot * Translation (Right) +
              Left.Rot_Cross * Rotation (Right)) &
             Left.Rot * Rotation (Right);
   end "*";

   function Transform_Rate
     (Xform : in Pose_Type;
      Rate  : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return Inverse_Times
                (Xform.Rotation,
                 (Translation (Rate) -
                  Cross (Xform.Translation, Rotation (Rate)))) &
             Inverse_Times (Xform.Rotation, Rotation (Rate));
   end Transform_Rate;

   function Transform_Rate
     (Disp : in Math_Dof_3.Cart_Vector_Type;
      Rate : in Dual_Cart_Vector_Type)
      return Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return Translation (Rate) -
             Cross (Disp, Rotation (Rate)) &
             Rotation (Rate);
   end Transform_Rate;

   function "*"
     (Left  : in Wrench_Transform_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops, Math_Dof_3.Cacv_Ops;
   begin
      return Left.Rot * Translation (Right) &
             (Left.Rot * Rotation (Right) +
              Left.Rot_Cross * Translation (Right));
   end "*";

   function Transform_Wrench
     (Xform  : in Pose_Type;
      Wrench : in Dual_Cart_Vector_Type)
      return   Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return Inverse_Times (Xform.Rotation, Translation (Wrench)) &
             Inverse_Times
                (Xform.Rotation,
                 (Rotation (Wrench) -
                  Cross (Xform.Translation, Translation (Wrench))));
   end Transform_Wrench;

   function Transform_Wrench
     (Disp   : in Math_Dof_3.Cart_Vector_Type;
      Wrench : in Dual_Cart_Vector_Type)
      return   Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return Translation (Wrench) &
             (Rotation (Wrench) - Cross (Disp, Translation (Wrench)));
   end Transform_Wrench;

   function Transform_Force
     (Disp  : in Math_Dof_3.Cart_Vector_Type;
      Force : in Math_Dof_3.Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3;
   begin
      return Force & Cross (Force, Disp);
   end Transform_Force;

   -------------
   -- dual magnitude and axis

   function Mag (Item : in Dual_Mag_Axis_Type) return Dual_Real_Type is
   begin
      return (Item.Translation.Mag, Item.Rotation.Mag);
   end Mag;

   function To_Dual_Mag_Axis
     (Dual_Cart_Vector : in Dual_Cart_Vector_Type)
      return             Dual_Mag_Axis_Type
   is
      use Math_Dof_3;
   begin
      return
        (To_Mag_Axis (Translation (Dual_Cart_Vector)),
         To_Mag_Axis (Rotation (Dual_Cart_Vector)));
   end To_Dual_Mag_Axis;

   function To_Dual_Cart_Vector
     (Dual_Mag_Axis : in Dual_Mag_Axis_Type)
      return          Dual_Cart_Vector_Type
   is
      use Math_Dof_3;
   begin
      return To_Cart_Vector (Dual_Mag_Axis.Translation) &
             To_Cart_Vector (Dual_Mag_Axis.Rotation);
   end To_Dual_Cart_Vector;

   function To_Dual_Mag_Axis
     (Pose : in Pose_Type)
      return Dual_Mag_Axis_Type
   is
      use Math_Dof_3;
   begin
      return (To_Mag_Axis (Pose.Translation), To_Mag_Axis (Pose.Rotation));
   end To_Dual_Mag_Axis;

   function To_Pose
     (Dual_Mag_Axis : in Dual_Mag_Axis_Type)
      return          Pose_Type
   is
      use Math_Dof_3;
   begin
      return
        (To_Cart_Vector (Dual_Mag_Axis.Translation),
         To_Unit_Quaternion (Dual_Mag_Axis.Rotation));
   end To_Pose;

   function "-" (Item : in Dual_Mag_Axis_Type) return Dual_Mag_Axis_Type is
   begin
      return
        ((-Item.Translation.Mag, Item.Translation.Axis),
         (-Item.Rotation.Mag, Item.Rotation.Axis));
   end "-";

   function "*"
     (Left  : in Dual_Real_Type;
      Right : in Dual_Mag_Axis_Type)
      return  Dual_Mag_Axis_Type
   is
      use Math_Dof_3;
   begin
      return (Left (Tran) * Right.Translation, Left (Rot) * Right.Rotation);
   end "*";

   function "*"
     (Left  : in Dual_Mag_Axis_Type;
      Right : in Dual_Real_Type)
      return  Dual_Mag_Axis_Type
   is
      use Math_Dof_3;
   begin
      return (Left.Translation * Right (Tran), Left.Rotation * Right (Rot));
   end "*";

   function "/"
     (Left  : in Dual_Mag_Axis_Type;
      Right : in Dual_Real_Type)
      return  Dual_Mag_Axis_Type
   is
      use Math_Dof_3;
   begin
      return (Left.Translation / Right (Tran), Left.Rotation / Right (Rot));
   end "/";

   function "*"
     (Left  : in Real_Type;
      Right : in Dual_Mag_Axis_Type)
      return  Dual_Mag_Axis_Type
   is
   begin
      return
        ((Left * Right.Translation.Mag, Right.Translation.Axis),
         (Left * Right.Rotation.Mag, Right.Rotation.Axis));
   end "*";

   function "*"
     (Left  : in Dual_Mag_Axis_Type;
      Right : in Real_Type)
      return  Dual_Mag_Axis_Type
   is
   begin
      return
        ((Left.Translation.Mag * Right, Left.Translation.Axis),
         (Left.Rotation.Mag * Right, Left.Rotation.Axis));
   end "*";

   function "/"
     (Left  : in Dual_Mag_Axis_Type;
      Right : in Real_Type)
      return  Dual_Mag_Axis_Type
   is
   begin
      return
        ((Left.Translation.Mag / Right, Left.Translation.Axis),
         (Left.Rotation.Mag / Right, Left.Rotation.Axis));
   end "/";

   ----------
   -- mass properties

   function Total (Item : in Mass_Type) return Real_Type is
   begin
      return Item.Total;
   end Total;

   function Center (Item : in Mass_Type) return Math_Dof_3.Cart_Vector_Type is
   begin
      return Item.Center;
   end Center;

   function Center_Inertia
     (Item : in Mass_Type)
      return Math_Dof_3.Inertia_Type
   is
   begin
      return Item.Center_Inertia;
   end Center_Inertia;

   function Inertia (Item : in Mass_Type) return Math_Dof_3.Inertia_Type is
   begin
      return Item.Inertia;
   end Inertia;

   function To_Mass
     (Total          : in Real_Type;
      Center         : in Math_Dof_3.Cart_Vector_Type;
      Center_Inertia : in Math_Dof_3.Inertia_Type)
      return           Mass_Type
   is
   begin
      if Total < Real_Type'Small then
         return Zero_Mass;
      else
         return
           (Total,
            Center,
            Center_Inertia,
            Math_Dof_3.Parallel_Axis (Total, Center, Center_Inertia));
      end if;
   end To_Mass;

   function "*"
     (Current_T_New : in Pose_Type;
      Mass          : in Mass_Type)
      return          Mass_Type
   is
      use Math_Dof_3;
      Result : Mass_Type;
   begin
      -- Can't use an aggregate, because the last component is a
      -- function of the first three.
      Result.Total          := Mass.Total;
      Result.Center         := Current_T_New * Mass.Center;
      Result.Center_Inertia := Mass.Center_Inertia;
      Result.Inertia        :=
         Parallel_Axis (Result.Total, Result.Center, Result.Center_Inertia);
      return Result;
   end "*";

   function Add
     (Left         : in Mass_Type;
      Right        : in Mass_Type;
      Left_T_Right : in Pose_Type)
      return         Mass_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;

      Left_P_Right_Center : constant Cart_Vector_Type :=
         Left_T_Right * Right.Center;
      Result              : Mass_Type;
   begin
      Result.Total := Left.Total + Right.Total;

      if Result.Total < Real_Type'Small then
         return Zero_Mass;

      else
         Result.Center         :=
           ((Left.Center * Left.Total) +
            (Left_P_Right_Center * Right.Total)) /
           Result.Total;
         Result.Center_Inertia :=
           Parallel_Axis
                (Left.Total,
                 Result.Center - Left.Center,
                 Left.Center_Inertia) +
           Parallel_Axis
              (Right.Total,
               Result.Center - Left_P_Right_Center,
               Left_T_Right.Rotation * Right.Center_Inertia);

         Result.Inertia :=
            Parallel_Axis
              (Result.Total,
               Result.Center,
               Result.Center_Inertia);

         return Result;
      end if;
   end Add;

   function Subtract
     (Left         : in Mass_Type;
      Right        : in Mass_Type;
      Left_T_Right : in Pose_Type)
      return         Mass_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
      Left_P_Right_Center : constant Cart_Vector_Type :=
         Left_T_Right * Right.Center;
      Result              : Mass_Type;
   begin
      Result.Total := Left.Total - Right.Total;

      if Result.Total < Real_Type'Small then
         return Zero_Mass;

      else
         Result.Center         :=
           ((Left.Center * Left.Total) -
            (Left_P_Right_Center * Right.Total)) /
           Result.Total;
         Result.Center_Inertia :=
           Parallel_Axis
                (Left.Total,
                 Result.Center - Left.Center,
                 Left.Center_Inertia) -
           Parallel_Axis
              (Right.Total,
               Result.Center - Left_P_Right_Center,
               Left_T_Right.Rotation * Right.Center_Inertia);
         Result.Inertia        :=
            Parallel_Axis
              (Result.Total,
               Result.Center,
               Result.Center_Inertia);

         return Result;
      end if;
   end Subtract;

   function "*"
     (Left  : in Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   --  force = mass * acceleration of cm, torque = I * alpha, at object frame.
   --  momentum = m * v_cm, I * w
   --  v_cm = v + w x r
   begin
      return Left.Total *
             (Translation (Right) + Cross (Rotation (Right), Left.Center)) &
             Left.Inertia * Rotation (Right);
   end "*";

   function Inverse_Times
     (Left  : in Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
      --  momentum = P, L
      --  velocity = v_cm - w x r, w
      --  w = I^-1 * L
      --  v_cm = P / m
      Rotation_Result : constant Cart_Vector_Type :=
         Inverse (Left.Inertia) * Rotation (Right);
   begin
      return Translation (Right) / Left.Total -
             Cross (Rotation_Result, Left.Center) &
             Rotation_Result;
   end Inverse_Times;

   ----------
   --  Simple mass properties

   function Inverse (Item : in Cm_Mass_Type) return Cm_Inverse_Mass_Type is
   begin
      return
        (Inverse_Total          => 1.0 / Item.Total,
         Inverse_Center_Inertia => Parent_Math_Dof_3.Inverse
                                     (Item.Center_Inertia));
   end Inverse;

   function "*"
     (Left  : in Cm_Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return Left.Total * Translation (Right) &
             Left.Center_Inertia * Rotation (Right);
   end "*";

   function "*"
     (Left  : in Cm_Inverse_Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return Left.Inverse_Total * Translation (Right) &
             Left.Inverse_Center_Inertia * Rotation (Right);
   end "*";

   function Inverse_Times
     (Left  : in Cm_Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type
   is
      use Math_Dof_3, Math_Dof_3.Cart_Vector_Ops;
   begin
      return Translation (Right) / Left.Total &
             Inverse (Left.Center_Inertia) * Rotation (Right);
   end Inverse_Times;

end Sal.Gen_Math.Gen_Dof_6;
