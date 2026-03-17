package body Hal.Vectors is

   function "+" (L, R : Vector) return Vector is
      T : Vector := L;
   begin
      for I in T'Range loop
         T(I) := T(I) + R(I);
      end loop;
      return T;
   end "+";

   function "-" (L, R : Vector) return Vector is
      T : Vector := L;
   begin
      for I in T'Range loop
         T(I) := T(I) - R(I);
      end loop;
      return T;
   end "-";

   function "/" (L : Vector; R : Real_Type) return Vector is
      T : Vector := L;
   begin
      for I in T'Range loop
         T(I) := T(I) / R;
      end loop;
      return T;
   end "/";

   function "-" (R : Vector) return Vector is
      T : Vector := R;
   begin
      for I in T'Range loop
         T(I) := - T(I);
      end loop;
      return T;
   end "-";

   function "*" (L : Real_Type; R : Vector) return Vector is
      T : Vector := R;
   begin
      for I in T'Range loop
         T(I) := L * T(I);
      end loop;
      return T;
   end "*";


   function "*" (L, R : in Vector) return Real_Type is
      Acc : Real_Type := 0.0;
   begin
      for I in L'Range loop
         Acc := Acc + L(I)*R(I);
      end loop;
      return Acc;
   end "*";

   procedure Normalize (v : in out Vector) is
   begin
      v := v / Elementary.Sqrt(V*V);
   end Normalize;
   
end Hal.Vectors;
