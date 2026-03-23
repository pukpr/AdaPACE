with Ada.Numerics.Generic_Elementary_Functions;
generic
   type Real_Type is digits <>;
   with package Elementary is new Ada.Numerics.Generic_Elementary_Functions (
      Real_Type);
package Hal.Vectors is
   type Vector is array(Positive range <>) of Real_Type; 
   function "+" (L, R : Vector) return Vector;
   function "-" (L, R : Vector) return Vector;
   function "-" (R : Vector) return Vector;
   function "/" (L : Vector; R : Real_Type) return Vector;
   function "*" (L : Real_Type; R : Vector ) return Vector;
   function "*" (L, R : in Vector) return Real_Type;  -- Dot product
   procedure Normalize (v : in out Vector);
   
end Hal.Vectors;
