--  Abstract :
--
--  Kinematic state integrator utilities.
--
--  Copyright (C) 2002, 2003 Stephen Leake.  All Rights Reserved.
--
--  SAL is free software; you can redistribute it and/or modify it
--  under terms of the GNU General Public License as published by the
--  Free Software Foundation; either version 2, or (at your option) any
--  later version. SAL is distributed in the hope that it will be
--  useful, but WITHOUT ANY WARRANTY; without even the implied warranty
--  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
--  General Public License for more details. You should have received a
--  copy of the GNU General Public License distributed with SAL; see
--  file COPYING. If not, write to the Free Software Foundation, 59
--  Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--
--  As a special exception, if other files instantiate generics from
--  SAL, or you link SAL object files with other files to produce
--  an executable, that does not by itself cause the resulting
--  executable to be covered by the GNU General Public License. This
--  exception does not however invalidate any other reasons why the
--  executable file might be covered by the GNU Public License.
--

package body Sal.Gen_Math.Gen_Dof_6.Gen_Integrator_Utils is

   function Derivative
     (State                   : in State_Type;
      Inverse_Mass            : in Cm_Inverse_Mass_Type;
      Wrench                  : in Dual_Cart_Vector_Type;
      Child_Rotation_Momentum : in Math_Dof_3.Cart_Vector_Type)
      return                    State_Dot_Type
   is
      use Parent_Math_Dof_3, Parent_Math_Dof_3.Cart_Vector_Ops, Dcv_Ops;
      Pose_Dot         : constant Dual_Cart_Vector_Type       :=
         Inverse_Mass * State.Momentum;
      Angular_Velocity : constant Math_Dof_3.Cart_Vector_Type :=
         Rotation (Pose_Dot);
      Angular_Momentum : constant Math_Dof_3.Cart_Vector_Type :=
         Rotation (State.Momentum) + Child_Rotation_Momentum;
      Euler_Torque     : constant Math_Dof_3.Cart_Vector_Type :=
         Cross (Angular_Velocity, Angular_Momentum);
   begin
      return
        (Pose_Dot     => Pose_Dot,
         Momentum_Dot => Wrench -
                         Concat
                            (Translation => (0.0, 0.0, 0.0),
                             Rotation    => Euler_Torque));
   end Derivative;

   function Derivative_Times_Time
     (Derivative : in State_Dot_Type;
      Delta_Time : in Real_Type)
      return       State_Type
   is
      use Dcv_Ops;
   begin
      return
        (Pose     => To_Pose (Delta_Time * Derivative.Pose_Dot),
         Momentum => Delta_Time * Derivative.Momentum_Dot);
   end Derivative_Times_Time;

   function State_Plus_State
     (Left, Right : in State_Type)
      return        State_Type
   is
      use Dcv_Ops;
   begin
      return (Left.Pose * Right.Pose, Left.Momentum + Right.Momentum);
   end State_Plus_State;

end Sal.Gen_Math.Gen_Dof_6.Gen_Integrator_Utils;
