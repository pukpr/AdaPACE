
package Hal.Fp_Utilities is

   subtype Value_Type is Float;
   subtype Positive_Type is Value_Type range 0.0 .. Value_Type'Last;

   ------------------------------------------------------------------------------

   -- Exceptions raised: Constraint_Error when  "not (Left - Right) in Value_Type"
   --                                       or  "not abs(Left - Right) in Value_Type"
   function Is_Equal (Left, Right : Value_Type; Epsilon : Positive_Type)
                     return Boolean;

   -- Exceptions raised: Constraint_Error when  "abs Value > Value_Type'Last"
   function Is_Zero
              (Value : Value_Type; Epsilon : Positive_Type) return Boolean;

   ------------------------------------------------------------------------------
   -- Limit subprograms return Value if Minimum > Maximum

   procedure Limit (Value : in out Value_Type;
                    Minimum, Maximum : in Value_Type);

   function Limit (Value, Minimum, Maximum : Value_Type) return Value_Type;

   ------------------------------------------------------------------------------

   -- Return -1.0 if Value is negative, 0.0 if Value is zero, 1.0 if Value is positive

   function Sign (Value : in Value_Type) return Value_Type;
   -- Exceptions raised: Constraint_Error when {-1.0, 0.0, 1.0} not in Value_Type
   ------------------------------------------------------------------------------


   generic

      -- Define the normalized circle constants.  Note that maximum is a asymptotic bound.
      -- Note that Maximum must be greater than minimum.
      -- Note that delta(minimum,maximum) should be exactly one cycle.
      Minimum : in Value_Type; -- Minimum normal cycle range
      Maximum : in Value_Type; -- Maximum normal cycle range

   package Circular is

      ------------------------------------------------------------------------------
      -- Normalize functions take an angle and transform it into the range
      -- of Minimum..Maximum.

      -- This function uses a modulus operation to move an angle into the normalized range 
      -- (Minimum..Maximum).  This should be used to pre-adjust excessive values before
      -- operating on them.  This is potentially less accurate but faster than Normalize
      -- for values that are far out of the range Minimum..Maximum.
      function Long_Normalize (Value : Value_Type) return Value_Type;

      -- This function performs add/subtract operations to move an angle into the
      -- normalized range (Minimum..Maximum).  This will potentially be faster and
      -- more accurate than Long_Normalize if the angle is close to being in range,
      -- but will take excessively long or never converge if too far out of range.
      function Normalize (Value : Value_Type) return Value_Type;

      ------------------------------------------------------------------------------
      -- Basic arithmetic
      -- Warning: these functions all use Normalize.  Use Long_Normalize to pre-adjust
      -- values that are extreme.

      -- Computes relative angles from Value2 to Value1. Returns values in 
      -- range +/- half circle range.
      function Difference (Value1, Value2 : Value_Type) return Value_Type;

      -- Computes Value1 + Value2 and return normalized angle. Returns values
      -- in range Minimum to Maximum.
      function Add (Value1, Value2 : Value_Type) return Value_Type;

      -- Computes Value1 - Value2 and returns normalized angle. Returns values
      -- in range Minimum to Maximum.
      function Subtract (Value1, Value2 : Value_Type) return Value_Type;

      ------------------------------------------------------------------------------

      -- Exceptions raised: Constraint_Error when  "not (Left - Right) in Value_Type"
      function Is_Equal (Left, Right : Value_Type; Epsilon : Positive_Type)
                        return Boolean;

      -- Exceptions raised: Constraint_Error when  "abs Value > Value_Type'Last"
      function Is_Zero
                 (Value : Value_Type; Epsilon : Positive_Type) return Boolean;

      ------------------------------------------------------------------------------

   end Circular;


end Hal.Fp_Utilities;
