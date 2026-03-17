--  Abstract:
--
--  see spec
--
--  Copyright (C) 2002 Stephen Leake.  All Rights Reserved.
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
separate (Sal.Gen_Math.Gen_Manipulator)
procedure Slow_Incremental_To_Joint
  (T0_T_Obj         : in Math_Dof_6.Pose_Type;
   Guess            : in Joint_Array_Real_Type;
   Den_Hart         : in Joint_Array_Den_Hart_Type;
   Tlast_T_Tp       : in Math_Dof_6.Pose_Type;
   Tp_T_Obj         : in Math_Dof_6.Pose_Type;
   Inverse_Jacobian : in Inverse_Jacobian_Type;
   Accuracy         : in Math_Dof_6.Dual_Real_Type := (0.001, 0.01);
   Iteration_Limit  : in Integer                   := 3;
   Iterations       : out Integer;
   Joint            : out Joint_Array_Real_Type)
is
   use Math_Dof_3, Math_Dof_6, Joint_Array_Real_Ops;

   Joint_Result    : Joint_Array_Real_Type := Guess;
   T0_T_Obj_Result : Pose_Type;
   Delta_Pose      : Dual_Cart_Vector_Type;
begin
   for I in  1 .. Iteration_Limit loop
      Iterations := I;

      T0_T_Obj_Result :=
         Slow_T0_T_Obj (Joint_Result, Den_Hart, Tlast_T_Tp, Tp_T_Obj);
      Delta_Pose      := T0_T_Obj - T0_T_Obj_Result;

      --  Update Joint_Result now, so some motion will be commanded
      --  even for steps smaller than Accuracy

      Joint_Result := Joint_Result + (Inverse_Jacobian * Delta_Pose);

      if Mag (Delta_Pose) <= Accuracy then
         Joint := Joint_Result;
         return;
      end if;

   end loop;

   raise Singular;
end Slow_Incremental_To_Joint;
