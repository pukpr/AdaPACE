--  Abstract:
--
--  Inverse of a square matrix. Separate from parent package because
--  some applications may not need it, and to allow alternate
--  implementations.
--
generic
function Sal.Gen_Math.Gen_Square_Array.Gen_Inverse
     (Right : in Array_Type)
      return  Array_Type;
