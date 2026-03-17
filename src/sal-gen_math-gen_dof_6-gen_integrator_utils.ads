--  Abstract :
--
--  Generic Kinematic state integrator utilities.
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

generic
package Sal.Gen_Math.Gen_Dof_6.Gen_Integrator_Utils is
   pragma Elaborate_Body;

   type State_Type is record
      Pose     : Pose_Type;
      Momentum : Dual_Cart_Vector_Type;
      --  Both must be in the center of mass frame of the object.
   end record;

   type State_Dot_Type is record
      Pose_Dot     : Dual_Cart_Vector_Type;
      Momentum_Dot : Dual_Cart_Vector_Type;
   end record;

   function State_Plus_State
     (Left, Right : in State_Type)
      return        State_Type;
   function "+" (Left, Right : in State_Type) return State_Type renames
     State_Plus_State;

   function Derivative_Times_Time
     (Derivative : in State_Dot_Type;
      Delta_Time : in Real_Type)
      return       State_Type;
   function "*"
     (Derivative : in State_Dot_Type;
      Delta_Time : in Real_Type)
      return       State_Type renames Derivative_Times_Time;

   function Derivative
     (State                   : in State_Type;
      Inverse_Mass            : in Cm_Inverse_Mass_Type;
      Wrench                  : in Dual_Cart_Vector_Type;
      Child_Rotation_Momentum : in Math_Dof_3.Cart_Vector_Type)
      return                    State_Dot_Type;
   --  Return derivative of State, given external Wrench on object,
   --  Mass of object, and extra rotation momentum in attached
   --  objects. Includes Euler torque.

end Sal.Gen_Math.Gen_Dof_6.Gen_Integrator_Utils;
