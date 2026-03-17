--  Abstract:
--
--  see spec
--
--  Design Decisions:
--
--  Only rotational joints are handled for now.
--
--  Modification History:
--
--     24 Jan 1992      Stephe Leake    Created
--     24 June 1992     Stephe Leake
--          match math spec changes, use To_Inverse_Wrench_Propagators
--  30 Nov 1993 Stephe Leake
--      match spec changes
--  27 Oct 1994 Victoria Buckland
--      Fixed bug in code; function Link_Wrench now uses Math_6_DOF."*" instead
--      of explicit multiply.

separate (Sal.Gen_Math.Gen_Manipulator)
function Slow_Inertia
  (Joint    : in Joint_Array_Real_Type;
   Den_Hart : in Joint_Array_Den_Hart_Type;
   Mass     : in Joint_Array_Mass_Type)
   return     Inertia_Type
is
   use Math_Dof_3, Math_Dof_6, Math_Den_Hart;

   type Joint_Array_Jad_Type is
     array (Joint_Index_Type) of Joint_Array_Dcv_Type;

   type Joint_Array_Wrench_Transform_Type is
     array (Joint_Index_Type) of Wrench_Transform_Type;
   type Joint_Array_Jawts is
     array (Joint_Index_Type) of Joint_Array_Wrench_Transform_Type;

   Joint_Mass : Joint_Array_Mass_Type;
   -- sum of link masses outboard of joint I

   Ti_W_Tj : Joint_Array_Jad_Type;
   -- wrench on joint I due to unit joint acceleration of joint J. only diag
   -- and upper triangle elements are set.

   Ti_Pw_Tj : Joint_Array_Jawts;
   -- Propagator from frame I to frame J. only upper triangle elements are set.

   Result : Inertia_Type;

   Last : constant Joint_Index_Type := Joint_Index_Type'Last;

   function Link_Wrench (Mass : in Mass_Type) return Dual_Cart_Vector_Type
      --  Return wrench exerted on link at link frame, due to unit
      --  acceleration of the joint at the link frame.
        is
      Unit_Z_Acceleration : constant Dual_Cart_Vector_Type :=
        (0.0,
         0.0,
         0.0,
         0.0,
         0.0,
         1.0);
   begin
      return (Mass * Unit_Z_Acceleration);
   end Link_Wrench;

   function Succ (Item : in Joint_Index_Type) return Joint_Index_Type renames
Joint_Index_Type'Succ;
   function Pred (Item : in Joint_Index_Type) return Joint_Index_Type renames
Joint_Index_Type'Pred;
begin
   for I in  Succ (Joint_Index_Type'First) .. Last loop
      if Den_Hart (I).Class /= Math_Den_Hart.Revolute then
         raise Constraint_Error;
      end if;
      Ti_Pw_Tj (Pred (I)) (I)   :=
         Math_Den_Hart.To_Inverse_Wrench_Transform (Den_Hart (I), Joint (I));
   end loop;

   for I in  Joint_Index_Type'First .. Last loop
      Ti_Pw_Tj (I) (I)  := To_Wrench_Transform (Zero_Pose);
   end loop;

   Joint_Mass (Last)      := Mass (Last);
   Ti_W_Tj (Last) (Last)  := Link_Wrench (Joint_Mass (Last));
   Result (Last) (Last)   := Ti_W_Tj (Last) (Last) (Rz);

   for I in reverse  Joint_Index_Type'First .. Pred (Last) loop
      Joint_Mass (I) :=
         Add
           (Mass (I),
            Joint_Mass (Succ (I)),
            Math_Den_Hart.To_Pose (Den_Hart (Succ (I)), Joint (Succ (I))));

      Ti_W_Tj (I) (I)  := Link_Wrench (Joint_Mass (I));
      Result (I) (I)   := Ti_W_Tj (I) (I) (Rz);

      for J in reverse  Succ (I) .. Last loop
         Ti_Pw_Tj (I) (J)  := Ti_Pw_Tj (I) (Succ (I)) *
                              Ti_Pw_Tj (Succ (I)) (J);
         Ti_W_Tj (I) (J)   := Ti_Pw_Tj (I) (J) * Ti_W_Tj (J) (J);
         Result (I) (J)    := Ti_W_Tj (I) (J) (Rz);
         Result (J) (I)    := Result (I) (J);
      end loop;
   end loop;
   return Result;
end Slow_Inertia;
