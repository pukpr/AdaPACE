--  Abstract:
--
--  see spec
--
--  Design Decisions:
--
--  algorithm outline:
--
--    0) Set T0_T_Guess_Current := T0_T_Guess, T0_T_Goal_Current :=
--       T0_T_Obj
--
--    1) attempt Newton-Raphson solution, starting at T0_T_Guess_Current,
--       working to T0_T_Goal_Current, computing Jacobian each step.
--
--    2) if 1) fails, cut step in half: T0_T_Goal_Current :=
--       (T0_T_Goal_Current - T0_T_Guess_Current)/2.0, goto 1.
--
--    3) if 1) succeeds, and T0_T_Goal_Current := T0_T_Goal, return. If
--       not, set T0_T_Guess := T0_T_Goal_Current, T0_T_Goal_Current :=
--       T0_T_Goal, goto 1.
--

separate (Sal.Gen_Math.Gen_Manipulator)
procedure Slow_To_Joint
  (T0_T_Obj        : in Math_Dof_6.Pose_Type;
   Guess           : in Joint_Array_Real_Type;
   Den_Hart        : in Joint_Array_Den_Hart_Type;
   Tlast_T_Tp      : in Math_Dof_6.Pose_Type;
   Tp_T_Obj        : in Math_Dof_6.Pose_Type;
   Accuracy        : in Math_Dof_6.Dual_Real_Type := (0.001, 0.01);
   Partition_Limit : in Integer                   := 10;
   Iteration_Limit : in Integer                   := 5;
   Partitions      : out Integer;
   Iterations      : out Integer;
   Joint           : out Joint_Array_Real_Type)
is
   use Math_Scalar, Math_Dof_6, Math_Dof_6.Dcv_Ops, Joint_Array_Real_Ops;

   T0_T_Goal_Current   : Pose_Type             := T0_T_Obj;
   T0_T_Guess_Current  : Pose_Type;
   Joint_Guess_Current : Joint_Array_Real_Type := Guess;

   Joint_Pos_Current : Joint_Array_Real_Type;
   Ti_T_Obj          : Joint_Array_Pose_Type;
   T0_T_Obj_Current  : Pose_Type;
   Delta_Pose        : Dual_Cart_Vector_Type;
   Inverse_Jacobian  : Inverse_Jacobian_Type;

   Converged  : Boolean := False;
   Final_Goal : Boolean := True;

begin

   for I in  1 .. Partition_Limit loop
      Partitions := I;

      T0_T_Guess_Current :=
         Slow_T0_T_Obj
           (Joint      => Joint_Guess_Current,
            Den_Hart   => Den_Hart,
            Tlast_T_Tp => Tlast_T_Tp,
            Tp_T_Obj   => Tp_T_Obj);

      Joint_Pos_Current := Joint_Guess_Current;
      T0_T_Obj_Current  := T0_T_Guess_Current;

      begin
         for J in  1 .. Iteration_Limit loop
            Slow_Ti_T_Obj
              (Joint      => Joint_Pos_Current,
               Den_Hart   => Den_Hart,
               Tlast_T_Tp => Tlast_T_Tp,
               Tp_T_Obj   => Tp_T_Obj,
               Ti_T_Obj   => Ti_T_Obj,
               T0_T_Obj   => T0_T_Obj_Current);

            Delta_Pose := T0_T_Goal_Current - T0_T_Obj_Current;

            Converged := Mag (Delta_Pose) <= Accuracy;

            exit when Converged and J > 1;

            Iterations := J;

            Inverse_Jacobian  := Inverse (Slow_Jacobian (Ti_T_Obj));
            Joint_Pos_Current := Joint_Pos_Current +
                                 Inverse_Jacobian * Delta_Pose;
         end loop;
      exception
         when Singular =>
            Converged := False;
      end;

      if Converged then
         if Final_Goal then
            Joint := Joint_Pos_Current;
            return;
         else
            Final_Goal          := True;
            Joint_Guess_Current := Joint_Pos_Current;
            T0_T_Goal_Current   := T0_T_Obj;
         end if;
      else
         --  Cut current step in half, try again
         Final_Goal        := False;
         T0_T_Goal_Current := T0_T_Goal_Current -
                              (T0_T_Goal_Current - T0_T_Guess_Current) /
                              2.0;
      end if;
   end loop;

   raise Singular;

end Slow_To_Joint;
