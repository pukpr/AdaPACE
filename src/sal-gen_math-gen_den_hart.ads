--  Abstract:
--
--  Low level types and operations for building manipulator packages.
--  For full manipulators, see SAL.Gen_Math.Gen_Manipulator.
--
--  References:
--
--  [1] "Introduction to Robotics Mechanics & Control" John J. Craig,
--      Addison-Wesley, 1986
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
--  Modification History:
--     (kept for sentimental reasons)
--
--  Jan. 17, 1991 Dana Miller
--     Created
--  27 Jan 1992   Stephe Leake
--     change Den_Hart to To_Pose, add To_Propagator
--  15 June 1992        Stephe Leake
--     change DEN_HART_PARAMS to DEN_HARTS. Add
--     To_Inverse_Wrench_Propagators, To_Inverse_Velocity_Propagators. Make
--     all conversion subprogram names plural.
--   8 July 1992        Stephe Leake
--     match changes to Math_6_DOF spec
--  30 Nov 1993 Stephe Leake
--     convert to _TYPE naming convention, match changes to Math_Scalar,
--  18 Jul 1994     Victoria Buckland
--     added both Mult functions
--  11 Oct 1994 Stephe Leake
--     add ANALOG_SERVO_TYPE
--  21 May 2002
--     changed to SAL.Gen_Math.Gen_Den_Hart.
with Ada.Numerics.Generic_Elementary_Functions;
with Sal.Gen_Math.Gen_Scalar;
with Sal.Gen_Math.Gen_Dof_3;
with Sal.Gen_Math.Gen_Dof_6;
generic
   --  Auto_Text_IO : ignore
   with package Elementary is new Ada.Numerics.Generic_Elementary_Functions (
      Real_Type);
   with package Math_Scalar is new Sal.Gen_Math.Gen_Scalar (
      Elementary);
   --  Auto_Text_IO : ignore
   with package Math_Dof_3 is new Sal.Gen_Math.Gen_Dof_3 (
      Elementary,
      Math_Scalar);
   --  Auto_Text_IO : ignore
   with package Math_Dof_6 is new Sal.Gen_Math.Gen_Dof_6 (
      Elementary,
      Math_Scalar,
      Math_Dof_3);
package Sal.Gen_Math.Gen_Den_Hart is

   type Joint_Class_Type is (Revolute, Prismatic);
   --  In [1] Craig considers these two the basic classes

   type Den_Hart_Type (Class : Joint_Class_Type := Revolute) is record
   --  As in [1]. These are the parameters for joint I; A[I-1],
   --  Alpha[I-1], D[I] or Theta[I]

      A          : Real_Type;
      Trig_Alpha : Math_Scalar.Trig_Pair_Type;

      case Class is
         when Revolute =>
            D : Real_Type;
         when Prismatic =>
            Trig_Theta : Math_Scalar.Trig_Pair_Type;
      end case;
   end record;

   subtype Revolute_Den_Hart_Type is Den_Hart_Type (Class => Revolute);
   subtype Prismatic_Den_Hart_Type is Den_Hart_Type (Class => Prismatic);

   function To_Pose
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Pose_Type;
   function To_Inverse_Pose
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Pose_Type;
   pragma Inline (To_Pose);
   pragma Inline (To_Inverse_Pose);

   function To_Rate_Transform
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Rate_Transform_Type;
   --  Equivalent to To_Rate_Transform (To_Pose (Den_Hart, Position))

   function To_Inverse_Rate_Transform
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Rate_Transform_Type;
   --  Equivalent to To_Rate_Transform (To_Inverse_Pose (Den_Hart, Position))

   function To_Wrench_Transform
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Wrench_Transform_Type;
   --  Equivalent to To_Wrench_Transform (To_Pose (Den_Hart, Position))

   function To_Inverse_Wrench_Transform
     (Param    : in Den_Hart_Type;
      Position : in Real_Type)
      return     Math_Dof_6.Wrench_Transform_Type;
   --  Equivalent to To_Wrench_Transform (To_Inverse_Pose (Den_Hart, Position))

   function Partial_Jacobian
     (Ti_T_Obj : Math_Dof_6.Pose_Type)
      return     Math_Dof_6.Dual_Cart_Vector_Type;
   --  Ti_T_Obj is the transform from a manipulator joint i to the
   --  object, expressed in the joint i frame; result is the column
   --  of the manipulator Jacobian corresponding to joint i. The
   --  Jacobian is in the object frame.

   function Mult
     (Left           : in Math_Dof_6.Pose_Type;
      Right          : in Den_Hart_Type;
      Right_Position : in Real_Type)
      return           Math_Dof_6.Pose_Type;
   --  Equivalent to Left * To_Pose(Right, Right_Position) but faster

   function Mult
     (Left          : in Den_Hart_Type;
      Left_Position : in Real_Type;
      Right         : in Math_Dof_6.Pose_Type)
      return          Math_Dof_6.Pose_Type;
   --  Equivalent to To_Pose(Left, Left_Position) * Right but faster

   --  Make our generic parameters visible to child packages.
   package Parent_Elementary renames Elementary;
   package Parent_Math_Scalar renames Math_Scalar;
   package Parent_Math_Dof_3 renames Math_Dof_3;
   package Parent_Math_Dof_6 renames Math_Dof_6;

end Sal.Gen_Math.Gen_Den_Hart;
