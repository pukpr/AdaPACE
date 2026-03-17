--  Abstract:
--
--  Math types and operations for 6 Cartesian degrees of freedom. One
--  degree of freedom types and operations are in Gen_Math.Gen_Scalar,
--  and 3 Cartesian degrees of freedom types and operations are in
--  Gen_Math.Gen_DOF_3.
--
--  Design :
--
--  All rotation units are radians, all translation units are up to
--  the user.
--
--  By the common style convention, Dual_Cart_Vector_Type should be
--  named Dual_Cart_Array_Real_Type. We use Dual_Cart_Vector_Type out
--  of recognition of the overwhelming influence of Cartesian
--  geometry. 'Dual' comes from the duality of rotation and
--  translation; in group theory jargon, the Dual_Cart_Vectors live in
--  SO3 cross R3.
--
--  Dual_Real_Type is not Dual_Array_Real_Type, because it is only two
--  elements, which is usually the magnitude of a
--  Dual_Cart_Vector_Type. We need most of the operations of
--  Gen_Vector_Math, but the objects of this type are not really used
--  as arrays.
--
--  Pose transformations are documented using the notation B_T_A. B is
--  the base or reference frame of a pose; T stands for Transform; A
--  is the pose frame, or just a label identifying the pose. Thus the
--  equation:
--
--  Base_T_Right := Base_T_Left * Left_T_Right
--
--  says "the Right frame expressed in the Base frame is equal to the
--  Left frame expressed in the Base frame times the Right frame
--  expressed in the Left frame". Note that for "*" to make sense, the
--  labels must match: B_T_A * A_T_C is good, but B_T_A * B_T_C is
--  not.
--
--  When a pose B_T_A is converted to a Dual_Cart_Vector_Type, it is
--  denoted B_X_A.
--
--  The "+" and "-" operations involving Pose_Type and
--  Dual_Cart_Vector type are best understood in terms of a base pose
--  and two close poses 1 and 2. Then the operations satisfy the
--  following equations:
--
--  1_X_2 = B_T_2 - B_T_1
--  B_T_2 = B_T_1 + 1_X_2
--  B_T_1 = B_T_2 - 1_X_2
--  1_T_B = 1_X_2 + 2_T_B
--
--  Thus the "+" and "-" Pose_Type operators are analogous to the "+"
--  and "-" Cart_Vector_Type operators for the translation part of the
--  poses.
--
--  Optimized forms of the "+" and "-" operators are provided for
--  poses with zero translation or rotation part, since these
--  operations are faster.
--
--  We provide Transform_Force, but no equivalent
--  Transform_Translation_Rate, because there are common forces that
--  have no rotation component (ie gravity), but rates with no
--  rotation component are rare, and the simplification is not as
--  significant.
--
--  Copyright (C) 2001, 2002, 2003 Stephen Leake.  All Rights Reserved.
--
--  This library is free software; you can redistribute it and/or
--  modify it under terms of the GNU General Public License as
--  published by the Free Software Foundation; either version 2, or
--  (at your option) any later version. This library is distributed in
--  the hope that it will be useful, but WITHOUT ANY WARRANTY; without
--  even the implied warranty of MERCHANTABILITY or FITNESS FOR A
--  PARTICULAR PURPOSE. See the GNU General Public License for more
--  details. You should have received a copy of the GNU General Public
--  License distributed with this program; see file COPYING. If not,
--  write to the Free Software Foundation, 59 Temple Place - Suite
--  330, Boston, MA 02111-1307, USA.
--
--  As a special exception, if other files instantiate generics from
--  this unit, or you link this unit with other files to produce an
--  executable, this unit does not by itself cause the resulting
--  executable to be covered by the GNU General Public License. This
--  exception does not however invalidate any other reasons why the
--  executable file might be covered by the GNU Public License.
--
with Ada.Numerics.Generic_Elementary_Functions;
with Sal.Gen_Math.Gen_Scalar;
with Sal.Gen_Math.Gen_Vector;
with Sal.Gen_Math.Gen_Square_Array;
with Sal.Gen_Math.Gen_Dof_3;
generic
   --  Auto_Text_IO : ignore
   with package Elementary is new Ada.Numerics.Generic_Elementary_Functions (
      Real_Type);
   with package Math_Scalar is new Sal.Gen_Math.Gen_Scalar (
      Elementary);
   with package Math_Dof_3 is new Sal.Gen_Math.Gen_Dof_3 (
      Elementary,
      Math_Scalar);
package Sal.Gen_Math.Gen_Dof_6 is
   pragma Elaborate_Body; --  non-static (non-scalar) constants

   --  Dual_Real_Type operations

   type Dual_Axis_Type is (Tran, Rot);

   type Dual_Boolean_Type is array (Dual_Axis_Type) of Boolean;
   type Dual_Real_Type is array (Dual_Axis_Type) of Real_Type;
   type Dual_Limit_Type is array (Dual_Axis_Type) of Math_Scalar.Limit_Type;

   package Dual_Real_Ops is new Gen_Vector (
      Elementary => Elementary,
      Math_Scalar => Math_Scalar,
      Index_Type => Dual_Axis_Type,
      Index_Array_Boolean_Type => Dual_Boolean_Type,
      Index_Array_Real_Type => Dual_Real_Type,
      Index_Array_Limit_Type => Dual_Limit_Type);

   --  Other Dual_Real_Type ops

   function "<=" (Left, Right : in Dual_Real_Type) return Boolean;
   --  True if both components of left are less than or equal to the
   --  corresponding components of Right. This is used instead of "<="
   --  (Dual_Real_Type, Dual_Limit_Type) when Left is a magnitude,
   --  which is inherently positive.

   ---------------
   --  Dual_Cart operations

   type Dual_Cart_Axis_Type is (
      Tx,
      Ty,
      Tz,
      Rx,
      Ry,
      Rz);
   --  Translation x, y, z; rotation x, y, z

   subtype Tran_Axis_Type is Dual_Cart_Axis_Type range Tx .. Tz;
   subtype Rot_Axis_Type is Dual_Cart_Axis_Type range Rx .. Rz;

   type Dual_Cart_Array_Boolean_Type is
     array (Dual_Cart_Axis_Type) of Boolean;
   type Dual_Cart_Vector_Type is array (Dual_Cart_Axis_Type) of Real_Type;
   --  Abbreviation DCV.
   type Dual_Cart_Array_Limit_Type is
     array (Dual_Cart_Axis_Type) of Math_Scalar.Limit_Type;

   Zero_Dual_Cart_Vector : constant Dual_Cart_Vector_Type := (others => 0.0);

   package Dcv_Ops is new Gen_Vector (
      Elementary => Elementary,
      Math_Scalar => Math_Scalar,
      Index_Type => Dual_Cart_Axis_Type,
      Index_Array_Boolean_Type => Dual_Cart_Array_Boolean_Type,
      Index_Array_Real_Type => Dual_Cart_Vector_Type,
      Index_Array_Limit_Type => Dual_Cart_Array_Limit_Type);

   --  Other Dual_Cart_Vector_Type ops

   function Translation
     (Item : in Dual_Cart_Vector_Type)
      return Math_Dof_3.Cart_Vector_Type;
   --  Return the translation portion of the Dual_Cart_Vector.

   function Rotation
     (Item : in Dual_Cart_Vector_Type)
      return Math_Dof_3.Cart_Vector_Type;
   --  Return the rotation portion of the Dual_Cart_Vector.

   function Concat
     (Translation, Rotation : in Math_Dof_3.Cart_Vector_Type)
      return                  Dual_Cart_Vector_Type;
   function "&"
     (Translation, Rotation : in Math_Dof_3.Cart_Vector_Type)
      return                  Dual_Cart_Vector_Type renames Concat;
   --  Return the resulting Dual_Cart_Vector formed with the two
   --  Cart_Vector_Type.

   pragma Inline (Rotation, Translation, "&");

   function Mag (Item : in Dual_Cart_Vector_Type) return Dual_Real_Type;
   --  Return the dual Euclidean magnitude of a dual vector.

   function "*"
     (Left  : in Dual_Real_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   function "*"
     (Left  : in Dual_Cart_Vector_Type;
      Right : in Dual_Real_Type)
      return  Dual_Cart_Vector_Type;

   function "/"
     (Left  : in Dual_Cart_Vector_Type;
      Right : in Dual_Real_Type)
      return  Dual_Cart_Vector_Type;

   function "*"
     (Left  : in Math_Dof_3.Unit_Quaternion_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Rotate Right. This changes the orientation of Right; Right and
   --  the result are expressed in the same frame. To change the frame
   --  Right is expressed in, use Inverse (Left) * Right.

   function Inverse_Times
     (Left  : in Math_Dof_3.Unit_Quaternion_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Same as Inverse (Left) * Right, but faster.

   ----------
   --  Pose operations

   type Pose_Type is record
      Translation : Math_Dof_3.Cart_Vector_Type;
      Rotation    : Math_Dof_3.Unit_Quaternion_Type;
   end record;
   --  A six dimensional displacement; a frame transformation. The
   --  translation is done first, then the rotation.

   Zero_Pose : constant Pose_Type :=
     (Math_Dof_3.Zero_Cart_Vector,
      Math_Dof_3.Zero_Unit_Quaternion);

   function To_Dual_Cart_Vector
     (Pose : in Pose_Type)
      return Dual_Cart_Vector_Type;
   --  The translation part is just copied; the rotation part is
   --  converted to a rotation vector

   function To_Pose
     (Dual_Cart_Vector : in Dual_Cart_Vector_Type)
      return             Pose_Type;
   --  The translation part is just copied; the rotation part is
   --  converted from a rotation vector.

   function Mag (Item : in Pose_Type) return Dual_Real_Type;
   --  The magnitude of the rotation and translation parts.

   function Inverse (Item : in Pose_Type) return Pose_Type;
   --  Return the inverse transform.
   --  Item_T_Base := Inverse (Base_T_Item)

   function "*" (Left, Right : in Pose_Type) return Pose_Type;
   --  'multiply' two poses. Right is expressed in Left frame. Left
   --  and result are expressed in the base frame.
   --  Base_T_Right := Base_T_Left * Left_T_Right

   function "*"
     (Left  : in Math_Dof_3.Unit_Quaternion_Type;
      Right : in Pose_Type)
      return  Pose_Type;
   --  Equivalent to (Zero_Cart_Vector, Left) * Right. Right is in
   --  Left frame. Left and result are in the base frame.

   function "*"
     (Left  : in Pose_Type;
      Right : in Math_Dof_3.Unit_Quaternion_Type)
      return  Pose_Type;
   --  Equivalent to Left * (Zero_Cart_Vector, Right). Left and result
   --  are in the base frame, Right is in the Left frame.

   function "*"
     (Left  : in Pose_Type;
      Right : in Math_Dof_3.Cart_Vector_Type)
      return  Math_Dof_3.Cart_Vector_Type;
   --  Equivalent to Translation (Left * (Right,
   --  Zero_Unit_Quaternion)); transform a vector into a new frame.
   --  Left and result are in the base frame, Right is in the Left
   --  frame.

   function Inverse_Times (Left, Right : in Pose_Type) return Pose_Type;
   --  Same as Inverse (Left) * Right, but faster. Left and Right are
   --  in the base frame, the result is in the Left frame.
   --  Left_T_Right := Inverse_Times (Base_T_Left, Base_T_Right)

   function "-" (Left, Right : in Pose_Type) return Dual_Cart_Vector_Type;
   --  Equivalent to To_Dual_Cart_Vector (Inverse (Right) * Left); the
   --  difference between two poses. Left and Right are in the base
   --  frame, result is in Left frame. This is useful mainly when the
   --  poses are close together, so the difference is small.

   function "+"
     (Left  : in Pose_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Pose_Type;
   --  Equivalent to Left * To_Pose (Right). Right is in the Left
   --  frame, Left and result are in the base frame.

   function "+"
     (Left  : in Pose_Type;
      Right : in Math_Dof_3.Cart_Vector_Type)
      return  Pose_Type;
   --  Equivalent to Left * To_Pose ((Right, Zero_Unit_Quaternion)).
   --  Right is in the Left frame, Left and result are in the base
   --  frame.

   function "-"
     (Left  : in Pose_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Pose_Type;
   --  Equivalent to Left * Inverse (To_Pose (Right)). Left and result
   --  are in the Base frame, Right is in the result frame.

   function "+"
     (Left  : in Dual_Cart_Vector_Type;
      Right : in Pose_Type)
      return  Pose_Type;
   --  Equivalent to To_Pose (Left) * Right. Right is in the Left
   --  frame, Left and result are in the base frame.

   function "+"
     (Left  : in Math_Dof_3.Cart_Vector_Type;
      Right : in Pose_Type)
      return  Pose_Type;
   --  Equivalent to (Left, Zero_Unit_Quaternion) * Right. Since Left
   --  has no rotation part, Left, Right, and result are all expressed
   --  in the base frame.

   --------------
   --  General purpose matrices.

   type Dc_Array_Dcv_Type is
     array (Dual_Cart_Axis_Type) of Dual_Cart_Vector_Type;
   --  Useful for information relating DCVs to DCVs such as (but not
   --  limited to) Cartesian stiffness and compliance and calibration
   --  matrices for wrench sensors

   package Dc_Array_Dcv_Ops is new Gen_Square_Array (
      Index_Type => Dual_Cart_Axis_Type,
      Row_Type => Dual_Cart_Vector_Type,
      Array_Type => Dc_Array_Dcv_Type,
      Sqrt => Elementary.Sqrt);

   --------------
   --  Wrench and rate transforms

   type Rate_Transform_Type is private;
   type Wrench_Transform_Type is private;
   --  Used to transform either a rate or a wrench to another frame.
   --  See "*" (_Transform, DCV) below for full definition.

   Zero_Rate_Transform   : constant Rate_Transform_Type;
   Zero_Wrench_Transform : constant Wrench_Transform_Type;

   function Unchecked_Rate_Transform
     (Rot, Rot_Cross : Math_Dof_3.Cart_Array_Cart_Vector_Type)
      return           Rate_Transform_Type;
   function Unchecked_Wrench_Transform
     (Rot, Rot_Cross : Math_Dof_3.Cart_Array_Cart_Vector_Type)
      return           Wrench_Transform_Type;
   pragma Inline (Unchecked_Rate_Transform, Unchecked_Wrench_Transform);

   function To_Rate_Transform
     (Item : in Pose_Type)
      return Rate_Transform_Type;
   function To_Wrench_Transform
     (Item : in Pose_Type)
      return Wrench_Transform_Type;

   function To_Rate_Transform
     (Translation : in Math_Dof_3.Cart_Vector_Type;
      Rotation    : in Math_Dof_3.Rot_Matrix_Type)
      return        Rate_Transform_Type;

   function To_Wrench_Transform
     (Translation : in Math_Dof_3.Cart_Vector_Type;
      Rotation    : in Math_Dof_3.Rot_Matrix_Type)
      return        Wrench_Transform_Type;

   function To_Dc_Array_Dcv
     (Item : in Rate_Transform_Type)
      return Dc_Array_Dcv_Type;
   function To_Dc_Array_Dcv
     (Item : in Wrench_Transform_Type)
      return Dc_Array_Dcv_Type;
   --  For element access or multiplying by random DC_Array_DCV_Type.

   function Inverse_Transpose
     (Right : in Rate_Transform_Type)
      return  Wrench_Transform_Type;
   function Inverse_Transpose
     (Right : in Wrench_Transform_Type)
      return  Rate_Transform_Type;
   pragma Inline (Inverse_Transpose);

   function "*"
     (Left, Right : in Rate_Transform_Type)
      return        Rate_Transform_Type;
   function "*"
     (Left  : in Rate_Transform_Type;
      Right : in Dc_Array_Dcv_Type)
      return  Dc_Array_Dcv_Type;
   function "*"
     (Left  : in Dc_Array_Dcv_Type;
      Right : in Rate_Transform_Type)
      return  Dc_Array_Dcv_Type;

   function "*"
     (Left, Right : in Wrench_Transform_Type)
      return        Wrench_Transform_Type;
   function "*"
     (Left  : in Wrench_Transform_Type;
      Right : in Dc_Array_Dcv_Type)
      return  Dc_Array_Dcv_Type;
   function "*"
     (Left  : in Dc_Array_Dcv_Type;
      Right : in Wrench_Transform_Type)
      return  Dc_Array_Dcv_Type;

   function "*"
     (Left  : in Rate_Transform_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Right gives the rate of a rigid body at frame A; Left is the
   --  transform from A to another frame B on the same rigid body.
   --  Returns the rate at frame B. Left, Right are expressed in frame
   --  A, the result is expressed in frame B. Same as To_DC_Array_DCV
   --  (Left) * Right, but faster.

   function Transform_Rate
     (Xform : in Pose_Type;
      Rate  : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Same as To_Rate_Transform (Xform) * Rate, but faster. This
   --  should be used when Xform changes often, so it is not worth
   --  converting to a Rate_Transform_Type.

   function Transform_Rate
     (Rotation : in Math_Dof_3.Unit_Quaternion_Type;
      Rate     : in Dual_Cart_Vector_Type)
      return     Dual_Cart_Vector_Type renames Inverse_Times;
   --  Same as Transform_Rate ((Zero_Cart_Vector, Rotation), Rate),
   --  but much faster.

   function Transform_Rate
     (Disp : in Math_Dof_3.Cart_Vector_Type;
      Rate : in Dual_Cart_Vector_Type)
      return Dual_Cart_Vector_Type;
   --  Same as Transform_Rate ((Left, Zero_Unit_Quaternion), Rate),
   --  but faster.

   function "*"
     (Left  : in Wrench_Transform_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Right gives the wrench on a rigid body at frame A; Left is the
   --  transform from A to another frame B on the same rigid body;
   --  returns the wrench at frame B. Left, Right are expressed in
   --  frame A, the result is expressed in frame B. Same as
   --  To_DC_Array_DCV (Left) * Right, but faster.

   function Transform_Wrench
     (Xform  : in Pose_Type;
      Wrench : in Dual_Cart_Vector_Type)
      return   Dual_Cart_Vector_Type;
   --  Same as To_Wrench_Transform (Xform) * Wrench, but faster. This
   --  should be used when Xform changes often, so it is not worth
   --  converting to a Wrench_Transform_Type.

   function Transform_Wrench
     (Rotation : in Math_Dof_3.Unit_Quaternion_Type;
      Wrench   : in Dual_Cart_Vector_Type)
      return     Dual_Cart_Vector_Type renames Inverse_Times;
   --  Same as Transform_Wrench ((Zero_Cart_Vector, Rotation), Rate),
   --  but much faster.

   function Transform_Wrench
     (Disp   : in Math_Dof_3.Cart_Vector_Type;
      Wrench : in Dual_Cart_Vector_Type)
      return   Dual_Cart_Vector_Type;
   --  Same as Transform_Wrench ((Disp, Zero_Unit_Quaternion), Wrench),
   --  but faster.

   function Transform_Force
     (Disp  : in Math_Dof_3.Cart_Vector_Type;
      Force : in Math_Dof_3.Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Same as Transform_Wrench ((Disp, Zero_Unit_Quaternion), (Force,
   --  Zero_Cart_Vector)), but faster.

   ---------------
   --  Dual magnitude and axis

   type Dual_Mag_Axis_Type is record
      Translation : Math_Dof_3.Mag_Axis_Type;
      Rotation    : Math_Dof_3.Mag_Axis_Type;
   end record;
   --  Suitable for magnitude and axis representation of six dimensional
   --  velocities, wrenches, differential displacements.

   function Mag (Item : in Dual_Mag_Axis_Type) return Dual_Real_Type;
   --  The dual magnitude of the translation and rotation parts.

   function To_Dual_Mag_Axis
     (Dual_Cart_Vector : in Dual_Cart_Vector_Type)
      return             Dual_Mag_Axis_Type;
   function To_Dual_Cart_Vector
     (Dual_Mag_Axis : in Dual_Mag_Axis_Type)
      return          Dual_Cart_Vector_Type;

   function To_Dual_Mag_Axis
     (Pose : in Pose_Type)
      return Dual_Mag_Axis_Type;
   function To_Pose
     (Dual_Mag_Axis : in Dual_Mag_Axis_Type)
      return          Pose_Type;

   function "-" (Item : in Dual_Mag_Axis_Type) return Dual_Mag_Axis_Type;

   function "*"
     (Left  : in Dual_Real_Type;
      Right : in Dual_Mag_Axis_Type)
      return  Dual_Mag_Axis_Type;
   function "*"
     (Left  : in Dual_Mag_Axis_Type;
      Right : in Dual_Real_Type)
      return  Dual_Mag_Axis_Type;
   --  Left.Translation * Right.Translation, Left.Rotation * Right.Rotation.

   function "/"
     (Left  : in Dual_Mag_Axis_Type;
      Right : in Dual_Real_Type)
      return  Dual_Mag_Axis_Type;
   --  Left.Translation / Right.Translation, Left.Rotation / Right.Rotation.

   function "*"
     (Left  : in Real_Type;
      Right : in Dual_Mag_Axis_Type)
      return  Dual_Mag_Axis_Type;
   function "*"
     (Left  : in Dual_Mag_Axis_Type;
      Right : in Real_Type)
      return  Dual_Mag_Axis_Type;
   function "/"
     (Left  : in Dual_Mag_Axis_Type;
      Right : in Real_Type)
      return  Dual_Mag_Axis_Type;

   ---------------
   --  Mass properties

   --  Auto_Text_IO : separate - don't put, get redundant Inertia value;
   --compute it on Get
   type Mass_Type is private;
   --  Private to enforce frame conventions.

   Zero_Mass : constant Mass_Type;

   function Total (Item : in Mass_Type) return Real_Type;
   --  Return total mass of Item.

   function Center (Item : in Mass_Type) return Math_Dof_3.Cart_Vector_Type;
   --  Return the center of mass of Item, expressed in the object frame.

   function Center_Inertia
     (Item : in Mass_Type)
      return Math_Dof_3.Inertia_Type;
   --  Return the inertia about the center of mass, expressed in the
   --  object frame.

   function Inertia (Item : in Mass_Type) return Math_Dof_3.Inertia_Type;
   --  Return the inertia about the object frame, expressed in the
   --  object frame.

   function To_Mass
     (Total          : in Real_Type;
      Center         : in Math_Dof_3.Cart_Vector_Type;
      Center_Inertia : in Math_Dof_3.Inertia_Type)
      return           Mass_Type;
   --  Total is the total mass. Center is the center of mass expressed
   --  in the object frame. Center_Inertia is about the center of
   --  mass, expressed in the object frame. If Total <
   --  Real_Type'small, returns Zero_Mass.

   function "*"
     (Current_T_New : in Pose_Type;
      Mass          : in Mass_Type)
      return          Mass_Type;
   --  Change frame of Mass.

   function Add
     (Left         : in Mass_Type;
      Right        : in Mass_Type;
      Left_T_Right : in Pose_Type)
      return         Mass_Type;
   --  Attach object Right to Left, at pose Left_T_Right. Right must
   --  be in Left_T_Right frame, result is in Left frame.

   function Subtract
     (Left         : in Mass_Type;
      Right        : in Mass_Type;
      Left_T_Right : in Pose_Type)
      return         Mass_Type;
   --  Detach object Right from Left, at pose Left_T_Right. Right must
   --  be in Left_T_Right frame, result is in Left frame.

   function "*"
     (Left  : in Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Mass * acceleration => wrench, or Mass * velocity => momentum.
   --  Right and result are in Left frame.

   function Inverse_Times
     (Left  : in Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Inverse Mass * momentum => velocity. Right and result are in
   --  Left frame.

   ---------------
   --  Simple Mass properties; body frame at center of mass

   type Cm_Mass_Type is record
      Total          : Real_Type;
      Center_Inertia : Math_Dof_3.Inertia_Type;
   end record;

   type Cm_Inverse_Mass_Type is record
      Inverse_Total          : Real_Type;
      Inverse_Center_Inertia : Math_Dof_3.Inverse_Inertia_Type;
   end record;

   function Inverse (Item : in Cm_Mass_Type) return Cm_Inverse_Mass_Type;

   function "*"
     (Left  : in Cm_Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Mass * acceleration => wrench, or Mass * velocity => momentum.
   --  Right and result are in Left frame.

   function "*"
     (Left  : in Cm_Inverse_Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   function Inverse_Times
     (Left  : in Cm_Mass_Type;
      Right : in Dual_Cart_Vector_Type)
      return  Dual_Cart_Vector_Type;
   --  Inverse Mass * momentum => velocity. Right and result are in
   --  Left frame.

   ----------
   --  Make our generic parameters visible to child packages.
   package Parent_Elementary renames Elementary;
   package Parent_Math_Scalar renames Math_Scalar;
   package Parent_Math_Dof_3 renames Math_Dof_3;

private

   type Rate_Transform_Type is record
      Rot       : Math_Dof_3.Cart_Array_Cart_Vector_Type;
      Rot_Cross : Math_Dof_3.Cart_Array_Cart_Vector_Type;
   end record;
   --  Rot could be Rot_Matrix_Type, but every operation on it would
   --  involve a conversion to Cart_Array_Cart_Vector_Type, so this is
   --  cleaner.

   type Wrench_Transform_Type is record
      Rot       : Math_Dof_3.Cart_Array_Cart_Vector_Type;
      Rot_Cross : Math_Dof_3.Cart_Array_Cart_Vector_Type;
   end record;
   --  Rot could be Rot_Matrix_Type, but every operation on it would
   --  involve a conversion to Cart_Array_Cart_Vector_Type, so this is
   --  cleaner.

   Zero_Rate_Transform   : constant Rate_Transform_Type   :=
     (others => Math_Dof_3.Cacv_Ops.Identity);
   Zero_Wrench_Transform : constant Wrench_Transform_Type :=
     (others => Math_Dof_3.Cacv_Ops.Identity);

   type Mass_Type is record
      Total          : Real_Type;
      Center         : Math_Dof_3.Cart_Vector_Type;
      Center_Inertia : Math_Dof_3.Inertia_Type;
      Inertia        : Math_Dof_3.Inertia_Type;
   end record;
   --  Defined as for To_Mass and Inertia above. Both Center_Inertia
   --  and Inertia are stored to save compute time; Inertia is a fixed
   --  function of Center_Inertia, Mass and Center.

   Zero_Mass : constant Mass_Type :=
     (0.0,
      Math_Dof_3.Zero_Cart_Vector,
      Math_Dof_3.Zero_Inertia,
      Math_Dof_3.Zero_Inertia);

end Sal.Gen_Math.Gen_Dof_6;
