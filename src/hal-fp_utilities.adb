package body Hal.Fp_Utilities is

   ------------------------------------------------------------------------------

   function Is_Equal (Left, Right : Value_Type; Epsilon : Positive_Type)
                     return Boolean is
   begin -- Is_Equal
      return abs (Left - Right) <= Epsilon;
   end Is_Equal;

   function Is_Zero (Value : Value_Type; Epsilon : Positive_Type)
                    return Boolean is
   begin -- Is_Zero
      return abs Value <= Epsilon;
   end Is_Zero;

   ------------------------------------------------------------------------------

   procedure Limit (Value : in out Value_Type;
                    Minimum, Maximum : in Value_Type) is
   begin -- Limit
      Value := Limit (Value, Minimum, Maximum);
   end Limit;

   function Limit (Value, Minimum, Maximum : Value_Type) return Value_Type is
   begin -- Limit
      if Minimum > Maximum then
         return Value;
      else
         return Value_Type'Min (Value_Type'Max (Value, Minimum), Maximum);
      end if;
   end Limit;

   ------------------------------------------------------------------------------

   -- Return -1.0 if Value is negative, 0.0 if Value is zero, 1.0 if Value is positive
   function Sign (Value : in Value_Type) return Value_Type is
   begin
      if Value = 0.0 then
         return 0.0;
      elsif Value > 0.0 then
         return 1.0;
      else
         return -1.0;
      end if;
   end Sign;

   ------------------------------------------------------------------------------


   package body Circular is

      Zero_Offset : constant Positive_Type := Maximum - Minimum;
      Half_Offset : constant Value_Type := Zero_Offset / 2.0;
      Delta_Maximum : constant Value_Type := Half_Offset;
      Delta_Minimum : constant Value_Type := -Half_Offset;

      --------------------------------------------------------------------------------------

      function Long_Normalize (Value : Value_Type) return Value_Type is
      begin -- Long_Normalize

         return Normalize (Value - (Zero_Offset *
                                    Value_Type'Floor (Value / Zero_Offset)));

      end Long_Normalize;

      --------------------------------------------------------------------------------------

      function Normalize (Value : Value_Type) return Value_Type is
         Return_Value : Value_Type := Value;
      begin -- Normalize

         while Return_Value >= Maximum loop
            Return_Value := Return_Value - Zero_Offset;
         end loop;

         while Return_Value < Minimum loop
            Return_Value := Return_Value + Zero_Offset;
         end loop;

         return Return_Value;

      end Normalize;

      --------------------------------------------------------------------------------------

      function Difference (Value1, Value2 : Value_Type) return Value_Type is
         Temp : Value_Type;
      begin -- Difference

         Temp := Normalize (Value1 - Value2);

         if Temp >= Delta_Maximum then
            Temp := Temp - Zero_Offset;
         elsif Temp < Delta_Minimum then
            Temp := Temp + Zero_Offset;
         end if;

         return Temp;

      end Difference;

      --------------------------------------------------------------------------------------

      function Add (Value1, Value2 : Value_Type) return Value_Type is
      begin -- Add

         return Normalize (Value1 + Value2);

      end Add;

      --------------------------------------------------------------------------------------

      function Subtract (Value1, Value2 : Value_Type) return Value_Type is
      begin -- Subtract

         return Normalize (Value1 - Value2);

      end Subtract;

      --------------------------------------------------------------------------------------

      function Is_Equal (Left, Right : Value_Type; Epsilon : Positive_Type)
                        return Boolean is
      begin -- Is_Equal

         return abs Difference (Left, Right) <= Epsilon;

      end Is_Equal;

      --------------------------------------------------------------------------------------

      function Is_Zero (Value : Value_Type; Epsilon : Positive_Type)
                       return Boolean is
      begin -- Is_Zero
         return abs Difference (Value, 0.0) <= Epsilon;
      end Is_Zero;

      --------------------------------------------------------------------------------------
   end Circular;

end Hal.Fp_Utilities;
