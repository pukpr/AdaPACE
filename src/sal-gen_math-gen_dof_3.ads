--  Abstract:
--
--  Math types and operations for 3 Cartesian degrees of freedom. One
--  degree of freedom types and operations are in Gen_Math.Gen_Scalar,
--  and 6 Cartesian degrees of freedom types and operations are in
--  Gen_Math.Gen_DOF_6.
--
--  References:
--
--  [1] Spacecraft Math, Stephen Leake
--
--  Design:
--
--  By the standard naming convention, Cart_Vector_Type should be
--  named Cart_Array_Real_Type. We use Cart_Vector_Type in recognition
--  of the overwhelming influence of Cartesian geometry.
--
--  All rotation units are radians, all translation units are up to
--  the user (meters are recommended).
--
--  Rot_Matrix_Type is supported for compatibility with other systems;
--  in general unit quaternions are more efficient, depending on
--  processor and compiler details. Rot_Matrix_Type is useful for
--  display during debugging.
--
--  ZYX_Euler_Type is supported only so it can be converted to and from
--  Unit_Quaternion_Type. ZYX_Euler_Type may be useful for display
--  during debugging, or for interfacing to other systems that haven't
--  learned about quaternions yet.
--
--  Cross function is not "*" because "*" (Cart_Vector_Type,
--  Cart_Vector_Type) return Cart_Vector_Type is element by element
--  which is used more often. The other Cross functions are not "*"
--  for consistency.
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
generic
   --  Auto_Text_IO : ignore
   with package Elementary is new Ada.Numerics.Generic_Elementary_Functions (
      Real_Type);
   with package Math_Scalar is new Sal.Gen_Math.Gen_Scalar (
      Elementary);
package Sal.Gen_Math.Gen_Dof_3 is
   pragma Elaborate_Body; -- non-static (non-scalar) constants

   type Cart_Axis_Type is (X, Y, Z);

   type Cart_Array_Boolean_Type is array (Cart_Axis_Type) of Boolean;
   type Cart_Vector_Type is array (Cart_Axis_Type) of Real_Type;
   type Cart_Array_Limit_Type is
     array (Cart_Axis_Type) of Math_Scalar.Limit_Type;

   Zero_Cart_Vector : constant Cart_Vector_Type := (0.0, 0.0, 0.0);

   package Cart_Vector_Ops is new Gen_Math.Gen_Vector (
      Elementary => Elementary,
      Math_Scalar => Math_Scalar,
      Index_Type => Cart_Axis_Type,
      Index_Array_Boolean_Type => Cart_Array_Boolean_Type,
      Index_Array_Real_Type => Cart_Vector_Type,
      Index_Array_Limit_Type => Cart_Array_Limit_Type);

   function Mag (Item : in Cart_Vector_Type) return Real_Type;
   -- The Euclidean magnitude of a vector

   function Cross
     (Left, Right : in Cart_Vector_Type)
      return        Cart_Vector_Type;

   ----------------
   -- unit vectors

   type Unit_Vector_Type is private;
   -- Private to enforce magnitude = 1.0.

   X_Unit : constant Unit_Vector_Type;
   Y_Unit : constant Unit_Vector_Type;
   Z_Unit : constant Unit_Vector_Type;

   function X (Item : in Unit_Vector_Type) return Real_Type;
   function Y (Item : in Unit_Vector_Type) return Real_Type;
   function Z (Item : in Unit_Vector_Type) return Real_Type;
   pragma Inline (X, Y, Z);

   function To_Unit_Vector (X, Y, Z : in Real_Type) return Unit_Vector_Type;
   pragma Inline (To_Unit_Vector);
   function To_Unit_Vector
     (Item : in Cart_Vector_Type)
      return Unit_Vector_Type;
   -- Normalize Item to magnitude 1.0
   --
   -- Raises Non_Normalizable_Unit_Vector if Mag (Item) = 0.0.

   function To_Cart_Vector
     (Item : in Unit_Vector_Type)
      return Cart_Vector_Type;
   pragma Inline (To_Cart_Vector);

   function Normalize (Item : in Unit_Vector_Type) return Unit_Vector_Type;
   -- Normalize Item to magnitude 1.0. Useful when Item is derived
   -- from user input, or to eliminate round-off.
   pragma Inline (Normalize);

   function Unchecked_Unit_Vector
     (Item : in Cart_Vector_Type)
      return Unit_Vector_Type;
   function Unchecked_Unit_Vector
     (X, Y, Z : in Real_Type)
      return    Unit_Vector_Type;
   -- Convert Item to a unit vector, with no normalization. This is
   -- suitable when algorithm guarantees normalization.
   pragma Inline (Unchecked_Unit_Vector);

   function "-" (Item : in Unit_Vector_Type) return Unit_Vector_Type;

   function "*"
     (Left  : in Unit_Vector_Type;
      Right : in Real_Type)
      return  Cart_Vector_Type;
   function "*"
     (Left  : in Real_Type;
      Right : in Unit_Vector_Type)
      return  Cart_Vector_Type;

   function "/"
     (Left  : in Unit_Vector_Type;
      Right : in Real_Type)
      return  Cart_Vector_Type;

   function Dot
     (Left  : in Unit_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Real_Type;
   function Dot
     (Left  : in Unit_Vector_Type;
      Right : in Cart_Vector_Type)
      return  Real_Type;
   function Dot
     (Left  : in Cart_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Real_Type;
   function "*"
     (Left  : in Unit_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Real_Type renames Dot;
   function "*"
     (Left  : in Unit_Vector_Type;
      Right : in Cart_Vector_Type)
      return  Real_Type renames Dot;
   function "*"
     (Left  : in Cart_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Real_Type renames Dot;
   -- Dot product

   function Cross
     (Left  : in Unit_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Cart_Vector_Type;
   function Cross
     (Left  : in Unit_Vector_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type;
   function Cross
     (Left  : in Cart_Vector_Type;
      Right : in Unit_Vector_Type)
      return  Cart_Vector_Type;
   -- Cross product

   ----------------
   -- magnitude and axis

   type Mag_Axis_Type is record
      Mag  : Real_Type;
      Axis : Unit_Vector_Type;
   end record;
   -- Suitable for magnitude and axis of any Cartesian vector,
   -- translation or rotation.

   function "-" (Item : in Mag_Axis_Type) return Mag_Axis_Type;

   function "*"
     (Left  : in Real_Type;
      Right : in Mag_Axis_Type)
      return  Mag_Axis_Type;
   function "*"
     (Left  : in Mag_Axis_Type;
      Right : in Real_Type)
      return  Mag_Axis_Type;

   function "/"
     (Left  : in Mag_Axis_Type;
      Right : in Real_Type)
      return  Mag_Axis_Type;

   function To_Cart_Vector
     (Mag_Axis : in Mag_Axis_Type)
      return     Cart_Vector_Type;
   function To_Mag_Axis
     (Cart_Vector : in Cart_Vector_Type)
      return        Mag_Axis_Type;

   function To_Mag_Axis
     (Left, Right : in Unit_Vector_Type)
      return        Mag_Axis_Type;
   -- [1] unit vector difference algorithm

   ---------------
   -- Quaternions

   type Unit_Quaternion_Type is private;
   -- Suitable for rotation displacement. Private to enforce magnitude = 1.0.

   Zero_Unit_Quaternion : constant Unit_Quaternion_Type;
   --  zero rotation; also known as the identity quaternion.

   function X (Item : in Unit_Quaternion_Type) return Real_Type;
   function Y (Item : in Unit_Quaternion_Type) return Real_Type;
   function Z (Item : in Unit_Quaternion_Type) return Real_Type;
   function S (Item : in Unit_Quaternion_Type) return Real_Type;
   pragma Inline (X, Y, Z, S);

   function To_Unit_Quaternion
     (X, Y, Z, S : in Real_Type)
      return       Unit_Quaternion_Type;
   -- Return a unit quaternion given its elements. They are assumed to
   -- be unnormalized.
   --
   -- Raises Non_Normalizable_Unit_Quaternion if magnitude of elements
   -- is 0.0.

   function Unchecked_Unit_Quaternion
     (X, Y, Z, S : in Real_Type)
      return       Unit_Quaternion_Type;
   -- Return a unit quaternion given its elements. They are assumed to
   -- be properly normalized; this is suitable for use when the
   -- algorithm guarantees normalization.
   pragma Inline (Unchecked_Unit_Quaternion);

   function Mag_Axis_To_Unit_Quaternion
     (Mag_Axis : in Mag_Axis_Type)
      return     Unit_Quaternion_Type;
   function To_Unit_Quaternion
     (Mag_Axis : in Mag_Axis_Type)
      return     Unit_Quaternion_Type renames Mag_Axis_To_Unit_Quaternion;

   function Unit_Quaternion_To_Mag_Axis
     (Quaternion : in Unit_Quaternion_Type)
      return       Mag_Axis_Type;
   function To_Mag_Axis
     (Quaternion : in Unit_Quaternion_Type)
      return       Mag_Axis_Type renames Unit_Quaternion_To_Mag_Axis;
   -- Result.Mag will be in range -PI .. PI.

   function Rot_Vector_To_Unit_Quaternion
     (Rot_Vector : in Cart_Vector_Type)
      return       Unit_Quaternion_Type;
   function To_Unit_Quaternion
     (Rot_Vector : in Cart_Vector_Type)
      return       Unit_Quaternion_Type renames Rot_Vector_To_Unit_Quaternion;
   -- Return a unit quaternion by assuming the magnitude of Rot_Vector
   -- is the angle, and the direction of Rot_Vector is the rotation
   -- axis.

   function Unit_Quaternion_To_Rot_Vector
     (Quaternion : in Unit_Quaternion_Type)
      return       Cart_Vector_Type;
   function To_Rot_Vector
     (Quaternion : in Unit_Quaternion_Type)
      return       Cart_Vector_Type renames Unit_Quaternion_To_Rot_Vector;
   -- Returns a rotation vector; the magnitude is the angle, and the
   -- direction is the rotation axis.

   function To_Unit_Quaternion
     (Angle : in Real_Type;
      Axis  : in Cart_Axis_Type)
      return  Unit_Quaternion_Type;
   -- Return a unit quaternion representing a rotation by Angle about
   -- the unit vector corresponding to Axis.

   function X_Axis (Quat : in Unit_Quaternion_Type) return Unit_Vector_Type;
   -- Return the X_Axis of the Cartesian frame represented by the unit
   -- quaternion. This is also the 1st column of the equivalent
   -- rotation matrix.

   function Y_Axis (Quat : in Unit_Quaternion_Type) return Unit_Vector_Type;
   -- Return the Y_Axis of the Cartesian frame represented by the unit
   -- quaternion. This is also the 2nd column of the equivalent
   -- rotation matrix.

   function Z_Axis (Quat : in Unit_Quaternion_Type) return Unit_Vector_Type;
   -- Return the Z_Axis of the Cartesian frame represented by the unit
   -- quaternion. This is also the 3rd column of the equivalent
   -- rotation matrix.

   function Mag (Item : in Unit_Quaternion_Type) return Real_Type;
   -- Result will be in range -PI .. PI.

   function Unit_Quaternion_Inverse
     (Item : in Unit_Quaternion_Type)
      return Unit_Quaternion_Type;
   pragma Inline (Unit_Quaternion_Inverse);
   function Inverse
     (Item : in Unit_Quaternion_Type)
      return Unit_Quaternion_Type renames Unit_Quaternion_Inverse;
   -- Return the inverse rotation.

   function "*"
     (Left, Right : in Unit_Quaternion_Type)
      return        Unit_Quaternion_Type;
   -- Add rotations.

   function Inverse_Times
     (Left, Right : in Unit_Quaternion_Type)
      return        Unit_Quaternion_Type;
   -- Equivalent to Inverse (Left) * Right, but faster.

   function Times_Inverse
     (Left, Right : in Unit_Quaternion_Type)
      return        Unit_Quaternion_Type;
   -- Equivalent to Left * Inverse (Right), but faster.

   function "*"
     (Left  : in Unit_Quaternion_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type;
   function "*"
     (Left  : in Unit_Quaternion_Type;
      Right : in Unit_Vector_Type)
      return  Unit_Vector_Type;
   -- Rotate Right. This changes the orientation of Right; Right and
   -- the result are expressed in the same frame. To change the frame
   -- Right is expressed in, use Inverse (Left) * Right.

   function Inverse_Times
     (Left  : in Unit_Quaternion_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type;
   function Inverse_Times
     (Left  : in Unit_Quaternion_Type;
      Right : in Unit_Vector_Type)
      return  Unit_Vector_Type;
   -- Same as Inverse (Left) * Right but faster.

   function Rotate
     (Angle  : in Real_Type;
      Axis   : in Cart_Axis_Type;
      Vector : in Cart_Vector_Type)
      return   Cart_Vector_Type;
   function Rotate
     (Sin_Cos : in Math_Scalar.Trig_Pair_Type;
      Axis    : in Cart_Axis_Type;
      Vector  : in Cart_Vector_Type)
      return    Cart_Vector_Type;
   -- Both are equivalent to but faster than To_Unit_Quaternion (Angle, Axis)
   --* Vector.

   ---------------------
   -- Euler angles

   type Zyx_Euler_Type is record
      Theta_Z : Real_Type;
      Theta_Y : Real_Type;
      Theta_X : Real_Type;
   end record;
   -- ZYX Euler angles in the ranges :
   --
   -- - Pi   < Theta_Z <= + Pi
   -- - Pi/2 < Theta_Y <= + Pi/2
   -- - Pi   < Theta_X <= + Pi
   --
   --  The singularity is at Theta_Y = +- Pi/2.

   function To_Zyx_Euler
     (Quaternion : in Unit_Quaternion_Type)
      return       Zyx_Euler_Type;
   -- Convert a unit quaternion to ZYX Euler angles. When at the
   -- singularity, Theta_Z is set to 0.0.

   function To_Unit_Quaternion
     (Euler : in Zyx_Euler_Type)
      return  Unit_Quaternion_Type;
   -- Convert ZYX Euler angles to a unit quaternion.

   type Celestial_Coordinate_Type is record
   -- See [2], section 2.2.2, fig 2-3.
   -- Note that there is a singularity at Declination = +-Pi/2
      Right_Ascension : Real_Type; --   0.0 ..  2 * Pi
      Declination     : Real_Type; -- -Pi/2 .. +Pi/2
   end record;

   function To_Celestial
     (N    : in Unit_Vector_Type)
      return Celestial_Coordinate_Type;
   -- Convert a unit vector to celestial coordinate angles. When at
   -- the singularity, Right_Ascension is set to 0.0.

   function To_Unit_Vector
     (Celestial : in Celestial_Coordinate_Type)
      return      Unit_Vector_Type;
   -- Convert celestial coordinate angles to a unit vector.

   ---------------
   -- general matrices for random purposes.

   type Cart_Array_Cart_Vector_Type is
     array (Cart_Axis_Type) of Cart_Vector_Type;
   -- Should NOT be used for inertias or rotation matrices; use
   -- Inertia_Type or Rot_Matrix_Type.
   --
   -- Abbreviation : CACV

   package Cacv_Ops is new Gen_Math.Gen_Square_Array (
      Index_Type => Cart_Axis_Type,
      Row_Type => Cart_Vector_Type,
      Array_Type => Cart_Array_Cart_Vector_Type,
      Sqrt => Elementary.Sqrt);

   function Inverse
     (Item : in Cart_Array_Cart_Vector_Type)
      return Cart_Array_Cart_Vector_Type;
   -- Compute inverse using determinant.
   --
   -- Raises Constraint_Error if Item is singular.

   --------------
   -- rotation matrices

   type Rot_Matrix_Type is private;
   -- 3 by 3 orthonormal matrices, with determinant +1. Also known as
   -- direction use 3 orthonormal matrices, with determinant +1. Also known as
   --direction
   -- cosine matrices, or orientation matrices.

   Zero_Matrix : constant Rot_Matrix_Type;
   --  zero rotation; also known as the identity matrix.

   function To_Cart_Array_Cart_Vector
     (Item : in Rot_Matrix_Type)
      return Cart_Array_Cart_Vector_Type;
   pragma Inline (To_Cart_Array_Cart_Vector);
   function To_Cacv
     (Item : in Rot_Matrix_Type)
      return Cart_Array_Cart_Vector_Type renames To_Cart_Array_Cart_Vector;
   -- For private element access, and use with general matrix algorithms.

   function To_Rot_Matrix
     (Item : in Cart_Array_Cart_Vector_Type)
      return Rot_Matrix_Type;
   -- Normalize Item.
   --
   -- Raises Non_Normalizable_Rot_Matrix if matrix cannot be normalized.

   function Unchecked_Rot_Matrix
     (Item : in Cart_Array_Cart_Vector_Type)
      return Rot_Matrix_Type;
   -- Return a rotation matrix given its elements. They are assumed to
   -- be properly normalized. This is suitable for use when the
   -- algorithm guarantees normalization.
   pragma Inline (Unchecked_Rot_Matrix);

   function Unit_Quaternion_To_Rot_Matrix
     (Quaternion : in Unit_Quaternion_Type)
      return       Rot_Matrix_Type;
   function To_Rot_Matrix
     (Quaternion : in Unit_Quaternion_Type)
      return       Rot_Matrix_Type renames Unit_Quaternion_To_Rot_Matrix;

   function Rot_Matrix_To_Unit_Quaternion
     (Rot_Matrix : in Rot_Matrix_Type)
      return       Unit_Quaternion_Type;
   function To_Unit_Quaternion
     (Rot_Matrix : in Rot_Matrix_Type)
      return       Unit_Quaternion_Type renames Rot_Matrix_To_Unit_Quaternion;

   function Mag_Axis_To_Rot_Matrix
     (Mag_Axis : in Mag_Axis_Type)
      return     Rot_Matrix_Type;
   function To_Rot_Matrix
     (Mag_Axis : in Mag_Axis_Type)
      return     Rot_Matrix_Type renames Mag_Axis_To_Rot_Matrix;

   function Rot_Matrix_To_Mag_Axis
     (Rot_Matrix : in Rot_Matrix_Type)
      return       Mag_Axis_Type;
   function To_Mag_Axis
     (Rot_Matrix : in Rot_Matrix_Type)
      return       Mag_Axis_Type renames Rot_Matrix_To_Mag_Axis;
   -- Result.Mag will be in range -PI .. PI.

   function Mag (Item : in Rot_Matrix_Type) return Real_Type;
   -- Result will be in range -PI .. PI.

   function Inverse (Item : in Rot_Matrix_Type) return Rot_Matrix_Type;
   -- Return the inverse rotation.

   function Rot_Matrix_Times_Rot_Matrix
     (Left, Right : in Rot_Matrix_Type)
      return        Rot_Matrix_Type;
   function "*" (Left, Right : in Rot_Matrix_Type) return Rot_Matrix_Type
      renames Rot_Matrix_Times_Rot_Matrix;
   -- Add rotations.
   pragma Inline (Rot_Matrix_Times_Rot_Matrix);

   function Inverse_Times
     (Left, Right : in Rot_Matrix_Type)
      return        Rot_Matrix_Type;
   -- Equivalent to Inverse (Left) * Right, but faster.
   pragma Inline (Inverse_Times);

   function Times_Inverse
     (Left, Right : in Rot_Matrix_Type)
      return        Rot_Matrix_Type;
   -- Equivalent to Left * Inverse (Right), but faster.
   pragma Inline (Times_Inverse);

   function Rot_Matrix_Times_Cacv
     (Left  : in Rot_Matrix_Type;
      Right : in Cart_Array_Cart_Vector_Type)
      return  Cart_Array_Cart_Vector_Type;
   function "*"
     (Left  : in Rot_Matrix_Type;
      Right : in Cart_Array_Cart_Vector_Type)
      return  Cart_Array_Cart_Vector_Type renames Rot_Matrix_Times_Cacv;
   pragma Inline (Rot_Matrix_Times_Cacv);

   function Cacv_Times_Rot_Matrix
     (Left  : in Cart_Array_Cart_Vector_Type;
      Right : in Rot_Matrix_Type)
      return  Cart_Array_Cart_Vector_Type;
   function "*"
     (Left  : in Cart_Array_Cart_Vector_Type;
      Right : in Rot_Matrix_Type)
      return  Cart_Array_Cart_Vector_Type renames Cacv_Times_Rot_Matrix;
   pragma Inline (Cacv_Times_Rot_Matrix);

   function Rot_Matrix_Times_Cart_Vector
     (Left  : in Rot_Matrix_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type;
   function "*"
     (Left  : in Rot_Matrix_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type renames Rot_Matrix_Times_Cart_Vector;
   -- Rotate Right. This changes the orientation of Right; Right and
   -- the result are expressed in the same frame. To change the frame
   -- Right is expressed in, use Inverse (Left) * Right.
   pragma Inline (Rot_Matrix_Times_Cart_Vector);

   function Inverse_Times
     (Left  : in Rot_Matrix_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type;
   -- Same as Inverse (Left) * Right but faster.
   pragma Inline (Inverse_Times);

   ------------------
   -- Inertias. See Gen_Math.Gen_DOF_6.Mass_Type for more complete
   -- operations on masses.

   type Inertia_Index_Type is (
      Ixx,
      Iyy,
      Izz,
      Ixy,
      Ixz,
      Iyz);

   type Inertia_Type is array (Inertia_Index_Type) of Real_Type;
   type Inverse_Inertia_Type is array (Inertia_Index_Type) of Real_Type;

   Zero_Inertia : constant Inertia_Type := (others => 0.0);

   function To_Cart_Array_Cart_Vector
     (Item : in Inertia_Type)
      return Cart_Array_Cart_Vector_Type;
   function To_Cacv
     (Item : in Inertia_Type)
      return Cart_Array_Cart_Vector_Type renames To_Cart_Array_Cart_Vector;
   --  For use with general matrix algorithms.

   function "+" (Left, Right : in Inertia_Type) return Inertia_Type;
   function "-" (Left, Right : in Inertia_Type) return Inertia_Type;
   -- Assumes both inertias are in the same frame.

   function "*"
     (Left  : in Inertia_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type;
   --  Normal matrix times vector; returns torque when Right is an
   --  angular acceleration, or angular momentum when Right is an
   --  angular velocity.

   function Inverse (Item : in Inertia_Type) return Inverse_Inertia_Type;

   function "*"
     (Left  : in Inverse_Inertia_Type;
      Right : in Cart_Vector_Type)
      return  Cart_Vector_Type;
   --  Normal matrix times vector; returns angular velocity when Right
   --  is an angular momentum.

   function Unit_Quat_Times_Inertia
     (Left  : in Unit_Quaternion_Type;
      Right : in Inertia_Type)
      return  Inertia_Type;
   function Rot_Matrix_Times_Inertia
     (Left  : in Rot_Matrix_Type;
      Right : in Inertia_Type)
      return  Inertia_Type;
   function "*"
     (Left  : in Unit_Quaternion_Type;
      Right : in Inertia_Type)
      return  Inertia_Type renames Unit_Quat_Times_Inertia;
   function "*"
     (Left  : in Rot_Matrix_Type;
      Right : in Inertia_Type)
      return  Inertia_Type renames Rot_Matrix_Times_Inertia;
   -- Change the frame of Right.

   function Parallel_Axis
     (Total_Mass     : in Real_Type;
      Center_Of_Mass : in Cart_Vector_Type;
      Inertia        : in Inertia_Type)
      return           Inertia_Type;
   -- Total_Mass is the object's total mass, Center_Of_Mass is
   -- expressed in the desired frame, Inertia is in a frame parallel
   -- to the desired frame, but centered at the center of mass. The
   -- result is the inertia matrix at the desired frame.

   -- Make our generic parameters visible to child packages.
   package Parent_Elementary renames Elementary;
   package Parent_Math_Scalar renames Math_Scalar;

private

   type Unit_Vector_Type is array (Cart_Axis_Type) of Real_Type;

   X_Unit : constant Unit_Vector_Type := (1.0, 0.0, 0.0);
   Y_Unit : constant Unit_Vector_Type := (0.0, 1.0, 0.0);
   Z_Unit : constant Unit_Vector_Type := (0.0, 0.0, 1.0);

   type Unit_Quaternion_Type is record
      X : Real_Type;
      Y : Real_Type;
      Z : Real_Type;
      S : Real_Type;
   end record;

   Zero_Unit_Quaternion : constant Unit_Quaternion_Type :=
     (0.0,
      0.0,
      0.0,
      1.0);

   type Rot_Matrix_Type is new Cart_Array_Cart_Vector_Type;

   Zero_Matrix : constant Rot_Matrix_Type :=
     ((1.0, 0.0, 0.0),
      (0.0, 1.0, 0.0),
      (0.0, 0.0, 1.0));

end Sal.Gen_Math.Gen_Dof_3;
