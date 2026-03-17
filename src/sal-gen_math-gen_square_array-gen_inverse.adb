--  Abstract:
--
--  see spec.
--
--  This body implements plain old Gaussian elimination with pivoting.
--

function Sal.Gen_Math.Gen_Square_Array.Gen_Inverse
  (Right : in Array_Type)
   return  Array_Type
is
   Temp_Input  : Array_Type := Right;
   Temp_Result : Array_Type := Identity;
   Pivot       : Real_Type;
   Beta        : Real_Type;

   procedure Swap
     (Temp_Input  : in out Array_Type;
      Temp_Result : in out Array_Type;
      I           : in Index_Type;
      J           : in Index_Type)
      --  Swap rows I and J of Temp_Input, Temp_Result.
   is
      Temp_Input_Row  : constant Row_Type := Temp_Input (I);
      Temp_Result_Row : constant Row_Type := Temp_Result (I);
   begin
      Temp_Input (I) := Temp_Input (J);
      Temp_Input (J) := Temp_Input_Row;

      Temp_Result (I) := Temp_Result (J);
      Temp_Result (J) := Temp_Result_Row;
   end Swap;

   procedure Max_Pivot
     (Temp_Input  : in out Array_Type;
      Temp_Result : in out Array_Type;
      I           : in Index_Type)
      --  Find maximum element in column I below row I of Temp_Input.
      --  Then swap rows to put max element on row I.
   is
      Max       : Real_Type  := abs Temp_Input (I) (I);
      Max_Index : Index_Type := I;
   begin
      if I /= Index_Type'Last then
         for J in  Index_Type'Succ (I) .. Index_Type'Last loop
            if abs Temp_Input (J) (I) > Max then
               Max       := abs Temp_Input (J) (I);
               Max_Index := J;
            end if;
         end loop;

         if Max_Index /= I then
            --  Don't swap if first guess was right
            Swap (Temp_Input, Temp_Result, I, Max_Index);
         end if;
      end if;
   end Max_Pivot;

begin

   One_Row : for I in  Index_Type loop
      Max_Pivot (Temp_Input, Temp_Result, I);
      Pivot := Temp_Input (I) (I);

      if abs Pivot < Real_Type'Model_Epsilon then
         raise Singular;
      end if;

      Normalize_Row : for J in  Index_Type loop
         Temp_Input (I) (J)   := Temp_Input (I) (J) / Pivot;
         Temp_Result (I) (J)  := Temp_Result (I) (J) / Pivot;
      end loop Normalize_Row;

      -- do row ops to make other elements in pivot column become 0
      for J in  Index_Type loop
         if I /= J then
            --  Don't do current row
            Beta := Temp_Input (J) (I);

            --  Do one row operation
            for K in  Index_Type loop
               Temp_Input (J) (K)   := Temp_Input (J) (K) -
                                       Beta * Temp_Input (I) (K);
               Temp_Result (J) (K)  := Temp_Result (J) (K) -
                                       Beta * Temp_Result (I) (K);
            end loop;
         end if;
      end loop;
   end loop One_Row;

   return Temp_Result;
end Sal.Gen_Math.Gen_Square_Array.Gen_Inverse;
