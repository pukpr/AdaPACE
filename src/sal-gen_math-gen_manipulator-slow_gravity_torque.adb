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

separate (Sal.Gen_Math.Gen_Manipulator)
function Slow_Gravity_Torque
  (T0_T_Ti   : in Joint_Array_Pose_Type;
   T0_A_Grav : in Math_Dof_3.Cart_Vector_Type;
   Mass      : in Joint_Array_Mass_Type)
   return      Joint_Array_Real_Type
is
   use Math_Scalar, Math_Dof_3, Math_Dof_3.Cart_Vector_Ops, Math_Dof_6,
     Math_Dof_6.Dcv_Ops;

   Result      : Joint_Array_Real_Type := (others => 0.0);
   Link_Wrench : Joint_Array_Dcv_Type;

   function Succ (Item : in Joint_Index_Type) return Joint_Index_Type renames
Joint_Index_Type'Succ;
   function Pred (Item : in Joint_Index_Type) return Joint_Index_Type renames
Joint_Index_Type'Pred;

begin

   Link_Wrench (Joint_Index_Type'Last) :=
      Transform_Force
        (-Center (Mass (Joint_Index_Type'Last)),
         Total (Mass (Joint_Index_Type'Last)) *
         Inverse_Times (T0_T_Ti (Joint_Index_Type'Last).Rotation, T0_A_Grav));

   for Joint in reverse  Joint_Index_Type'First .. Pred
                                                     (Joint_Index_Type'Last)
   loop
      Link_Wrench (Joint) :=
        Transform_Force
             (-Center (Mass (Joint)),
              Total (Mass (Joint)) *
              Inverse_Times (T0_T_Ti (Joint).Rotation, T0_A_Grav)) +
        Transform_Wrench
           (Inverse_Times (T0_T_Ti (Succ (Joint)), T0_T_Ti (Joint)),
            Link_Wrench (Succ (Joint)));

      Result (Joint) := Link_Wrench (Joint) (Rz);
   end loop;

   return Result;
end Slow_Gravity_Torque;
