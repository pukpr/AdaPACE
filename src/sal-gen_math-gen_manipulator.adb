--  Abstract:
--
--  see spec
--
--  Modification History:
--
--     Oct. 9, 1991     Dana Miller     Created
--     Dec. 31, 1991    Dana Miller
--      24 Jan 1992     Stephe Leake
--          match spec changes. localize use.
--      24 June 1992    Stephe Leake
--          match spec changes.
--       8 July 1992    Stephe Leake
--          match changes to Math_6_DOF spec
--       9 Nov 1992     Stephe Leake
--          match spec changes
--  30 Nov 1993 Stephe Leake
--      match spec changes
--  27 Sept 1994    Victoria Buckland
--      Utilized Manipulator_Math.Mult functions in Slow_T0_T_Obj,
--      Slow_T0_T_Ti, and Slow_Ti_T_Obj.
--  21 May 2002 Stephe Leake
--      match spec changes

package body Sal.Gen_Math.Gen_Manipulator is

   -- jacobians

   function "*"
     (Left  : in Jacobian_Type;
      Right : in Joint_Array_Real_Type)
      return  Math_Dof_6.Dual_Cart_Vector_Type
   is
      use Joint_Array_Dcv_Ops;
   begin
      return Dc_Array_Jar_Type (Left) * Right;
   end "*";

   function "*"
     (Left  : in Jacobian_Type;
      Right : in Math_Dof_6.Dual_Cart_Vector_Type)
      return  Joint_Array_Real_Type
   is
      use Joint_Array_Dcv_Ops;
   begin
      return Dc_Array_Jar_Type (Left) * Right;
   end "*";

   function "*"
     (Left  : in Inverse_Jacobian_Type;
      Right : in Math_Dof_6.Dual_Cart_Vector_Type)
      return  Joint_Array_Real_Type
   is
      use Joint_Array_Dcv_Ops;
   begin
      return Joint_Array_Dcv_Type (Left) * Right;
   end "*";

   function "*"
     (Left  : in Inverse_Jacobian_Type;
      Right : in Joint_Array_Real_Type)
      return  Math_Dof_6.Dual_Cart_Vector_Type
   is
      use Joint_Array_Dcv_Ops;
   begin
      return Joint_Array_Dcv_Type (Left) * Right;
   end "*";

   function Slow_Jacobian
     (Ti_T_Obj : in Joint_Array_Pose_Type)
      return     Jacobian_Type
   is
      Jacobian_Column : Math_Dof_6.Dual_Cart_Vector_Type;
      Result          : Jacobian_Type;
   begin
      for Joint in  Joint_Index_Type loop
         Jacobian_Column :=
            Math_Den_Hart.Partial_Jacobian (Ti_T_Obj (Joint));

         -- result cannot be assigned by slicing so it is assigned with a loop
         --instead.
         for Axis in  Math_Dof_6.Dual_Cart_Axis_Type loop
            Result (Axis) (Joint)  := Jacobian_Column (Axis);
         end loop;
      end loop;
      return Result;
   end Slow_Jacobian;

   function Transform_Jacobian
     (Current_T_New : in Math_Dof_6.Pose_Type;
      Jacobian      : in Jacobian_Type)
      return          Jacobian_Type
   is
      use Math_Dof_6;
      Result          : Jacobian_Type;
      Object_Velocity : Dual_Cart_Vector_Type;
   begin
      for Joint in  Joint_Index_Type loop
         Object_Velocity :=
            Transform_Rate
              (Current_T_New,
               Dual_Cart_Vector_Type'
           (Jacobian (Tx) (Joint),
            Jacobian (Ty) (Joint),
            Jacobian (Tz) (Joint),
            Jacobian (Rx) (Joint),
            Jacobian (Ry) (Joint),
            Jacobian (Rz) (Joint)));

         -- result cannot be assigned by slicing so it is assigned with a loop
         --instead.
         for Axis in  Dual_Cart_Axis_Type loop
            Result (Axis) (Joint)  := Object_Velocity (Axis);
         end loop;
      end loop;
      return Result;
   end Transform_Jacobian;

   function "*"
     (Left  : in Math_Dof_6.Rate_Transform_Type;
      Right : in Jacobian_Type)
      return  Jacobian_Type
   is
      use Math_Dof_6;
      Result          : Jacobian_Type;
      Object_Velocity : Dual_Cart_Vector_Type;
   begin
      for Joint in  Joint_Index_Type loop
         Object_Velocity := Left *
                            Dual_Cart_Vector_Type'
           (Right (Tx) (Joint),
            Right (Ty) (Joint),
            Right (Tz) (Joint),
            Right (Rx) (Joint),
            Right (Ry) (Joint),
            Right (Rz) (Joint));

         --  Result cannot be assigned by slicing so is assigned with a loop
         --instead.
         for Axis in  Dual_Cart_Axis_Type loop
            Result (Axis) (Joint)  := Object_Velocity (Axis);
         end loop;
      end loop;
      return Result;
   end "*";

   function Inverse (Right : in Jacobian_Type) return Inverse_Jacobian_Type is
   begin
      return Inverse_Jacobian_Type (Joint_Array_Dcv_Ops.Inverse
                                       (Dc_Array_Jar_Type (Right)));
   end Inverse;

   -- projectors

   function "*"
     (Left  : in Projector_Type;
      Right : in Joint_Array_Real_Type)
      return  Joint_Array_Real_Type
   is
      use Joint_Array_Jar_Ops;
   begin
      return Joint_Array_Jar_Type (Left) * Right;
   end "*";

   function Null_Space_Projector
     (Forward : in Jacobian_Type;
      Inverse : in Inverse_Jacobian_Type)
      return    Projector_Type
   is
      use Joint_Array_Jar_Ops, Joint_Array_Dcv_Ops;
   begin
      return Projector_Type (Joint_Array_Jar_Type'(Identity -
                                                   Joint_Array_Dcv_Type (
        Inverse) *
                                                   Dc_Array_Jar_Type (Forward))
);
   end Null_Space_Projector;

   -- kinematics

   function Slow_T0_T_Obj
     (Joint      : in Joint_Array_Real_Type;
      Den_Hart   : in Joint_Array_Den_Hart_Type;
      Tlast_T_Tp : in Math_Dof_6.Pose_Type;
      Tp_T_Obj   : in Math_Dof_6.Pose_Type)
      return       Math_Dof_6.Pose_Type
   is
      use Math_Dof_6;
      Result : Pose_Type := Zero_Pose;
   begin
      for I in  Joint'First .. Joint'Last loop
         Result := Math_Den_Hart.Mult (Result, Den_Hart (I), Joint (I));
      end loop;

      return Result * Tlast_T_Tp * Tp_T_Obj;
   end Slow_T0_T_Obj;

   function Slow_T0_T_Ti
     (Joint    : in Joint_Array_Real_Type;
      Den_Hart : in Joint_Array_Den_Hart_Type)
      return     Joint_Array_Pose_Type
   is
      Result : Joint_Array_Pose_Type;
   begin
      Result (Result'First) :=
         Math_Den_Hart.To_Pose
           (Den_Hart (Joint_Index_Type'First),
            Joint (Joint_Index_Type'First));

      for I in  Joint_Index_Type'Succ (Joint_Index_Type'First) .. 
           Joint_Index_Type'Last
      loop
         Result (I) :=
            Math_Den_Hart.Mult
              (Result (Joint_Index_Type'Pred (I)),
               Den_Hart (I),
               Joint (I));
      end loop;
      return Result;
   end Slow_T0_T_Ti;

   procedure Slow_Ti_T_Obj
     (Joint      : in Joint_Array_Real_Type;
      Den_Hart   : in Joint_Array_Den_Hart_Type;
      Tlast_T_Tp : in Math_Dof_6.Pose_Type;
      Tp_T_Obj   : in Math_Dof_6.Pose_Type;
      Ti_T_Obj   : out Joint_Array_Pose_Type;
      T0_T_Obj   : out Math_Dof_6.Pose_Type)
   is
      use Math_Dof_6;
      Result : Joint_Array_Pose_Type;
   begin
      Result (Result'Last) := Tlast_T_Tp * Tp_T_Obj;
      for I in reverse  Joint_Index_Type'First .. Joint_Index_Type'Pred
                                                    (Joint_Index_Type'Last)
      loop
         Result (I) :=
            Math_Den_Hart.Mult
              (Den_Hart (Joint_Index_Type'Succ (I)),
               Joint (Joint_Index_Type'Succ (I)),
               Result (Joint_Index_Type'Succ (I)));
      end loop;
      Ti_T_Obj := Result;
      T0_T_Obj :=
         Math_Den_Hart.Mult
           (Den_Hart (Joint_Index_Type'First),
            Joint (Joint_Index_Type'First),
            Result (Joint_Index_Type'First));

   end Slow_Ti_T_Obj;

   function Inverse
     (T0_T_Ti    : in Joint_Array_Pose_Type;
      Tlast_T_Tp : in Math_Dof_6.Pose_Type;
      Tp_T_Obj   : in Math_Dof_6.Pose_Type)
      return       Joint_Array_Pose_Type
   is
      use Math_Dof_6;

      T0_T_Object : constant Pose_Type :=
         T0_T_Ti (T0_T_Ti'Last) * Tlast_T_Tp * Tp_T_Obj;
      Result      : Joint_Array_Pose_Type;
   begin
      for I in  Joint_Index_Type loop
         Result (I) := Inverse_Times (T0_T_Ti (I), T0_T_Object);
      end loop;
      return Result;
   end Inverse;

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
is separate;

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
is separate;

   -- gravity and inertia

   function Slow_Inertia
     (Joint    : in Joint_Array_Real_Type;
      Den_Hart : in Joint_Array_Den_Hart_Type;
      Mass     : in Joint_Array_Mass_Type)
      return     Inertia_Type
   is separate;

   function Slow_Gravity_Torque
     (T0_T_Ti   : in Joint_Array_Pose_Type;
      T0_A_Grav : in Math_Dof_3.Cart_Vector_Type;
      Mass      : in Joint_Array_Mass_Type)
      return      Joint_Array_Real_Type
   is separate;

end Sal.Gen_Math.Gen_Manipulator;
