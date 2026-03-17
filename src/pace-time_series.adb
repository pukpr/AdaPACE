with Pace.Log; -- Do we really want this here?

package body Pace.Time_Series is

   TS_Delta_Averaging : constant Boolean := Pace.Getenv("PACE_TSDA", 0) = 1;

   function Advance
     (Time                : Duration;
      Check_Frame_Overrun : Boolean := False)
      return                Duration
   is
   begin
      if Check_Frame_Overrun and then Time < Pace.Now then
         raise Frame_Overrun;
      end if;
      Pace.Log.Wait_Until (Time);
      return Time;
   end Advance;

   procedure Update (Obj : in out Series;
                     Val : in Float;
                     Time : in Duration := Pace.Now) is
      DT : Duration;
      N : Float renames Obj.Total_Count;
      M : Float;
   begin
      Obj.Ptr               := Obj.Ptr + 1;
      Obj.Samples (Obj.Ptr) := (Value => Val, Time => Time);

      if TS_Delta_Averaging then
         if N > 0.0 then
            DT := Obj.Samples (Obj.Ptr).Time - Obj.Samples (Obj.Ptr - 1).Time;
            M := (N-1.0)/N;
            Obj.Average_Delta := Obj.Average_Delta * M + Float (DT) / N;
         end if;
         N := N + 1.0;
      end if;
   end Update;

   function Acceleration (Obj : Series) return Float is
      Curr : Sample renames Obj.Samples (Obj.Ptr);
      Prev : Sample renames Obj.Samples (Obj.Ptr - 1);
      Pred : Sample renames Obj.Samples (Obj.Ptr - 2);
      Delta_1, Delta_2 : Float;
   begin
      if Curr.Time = Prev.Time or Prev.Time = Pred.Time then
         return 0.0;
      elsif TS_Delta_Averaging then
         Delta_1 := (Curr.Value - Prev.Value) / Obj.Average_Delta;
         Delta_2 := (Prev.Value - Pred.Value) / Obj.Average_Delta;
         return (Delta_1 - Delta_2) / Obj.Average_Delta;
      else
         Delta_1 := (Curr.Value - Prev.Value) / Float (Curr.Time - Prev.Time);
         Delta_2 := (Prev.Value - Pred.Value) / Float (Prev.Time - Pred.Time);
         return 2.0 * (Delta_1 - Delta_2) / Float (Curr.Time - Pred.Time);
      end if;
   end Acceleration;

   function Predict (Obj : in Series; 
                     Time : in Duration := Pace.Now) return Float is
      Deriv : constant Float := Derivative (Obj);
      Accel : constant Float := Acceleration (Obj);
      Curr  : Sample renames Obj.Samples (Obj.Ptr);
      Delta_Time : constant Duration := Time - Curr.Time;
      Val : constant Float := Curr.Value + (Deriv + 0.5* Accel * Float (Delta_Time)) * Float (Delta_Time);
   begin
      return Val;
   end;

   function "*" (Left : Float; Right : Series) return Float is
   begin
      return Left * Right.Samples (Right.Ptr).Value;
   end "*";

   function "-" (Left : Series; Right : History) return Float is
      Index : constant Order := Order (Right);
   begin
      return Left.Samples (Left.Ptr - Index).Value;
   end "-";

   function "+" (Right : Float) return Series is
      Initial : Series;
   begin
      Initial.Samples (Initial.Ptr).Value := Right;
      return Initial;
   end "+";

   function "+" (Right : Series) return Float is
   begin
      return Right.Samples (Right.Ptr).Value;
   end "+";

   function Derivative (Obj : Series) return Float is
      Curr : Sample renames Obj.Samples (Obj.Ptr);
      Prev : Sample renames Obj.Samples (Obj.Ptr - 1);
   begin
      if Curr.Time = Prev.Time then
         return 0.0;
      elsif TS_Delta_Averaging then
         return (Curr.Value - Prev.Value) / Obj.Average_Delta;
      else 
         return (Curr.Value - Prev.Value) / Float (Curr.Time - Prev.Time);
      end if;
   end Derivative;

   procedure Integrate (Obj : in out Series) is
      Curr       : Sample renames Obj.Samples (Obj.Ptr);
      Prev       : Sample renames Obj.Samples (Obj.Ptr - 1);
      Delta_Time : constant Duration := Curr.Time - Prev.Time;
   begin
      Obj.Cumulative_Time := Obj.Cumulative_Time + Delta_Time;
      if Obj.Cumulative_Time > 0.0 then
         Obj.Running_Average :=
           (Obj.Cumulative_Integral + Curr.Value * Float (Delta_Time)) /
           Float (Obj.Cumulative_Time);
      else
         Obj.Running_Average := Curr.Value;
      end if;
      Obj.Cumulative_Integral := Obj.Cumulative_Integral +
                                 Float (Delta_Time) *
                                 (Curr.Value + Prev.Value) /
                                 2.0;
      if Curr.Value > Obj.Max then
         Obj.Max := Curr.Value;
      end if;
      if Curr.Value < Obj.Min then
         Obj.Min := Curr.Value;
      end if;
   end Integrate;

   function Integral (Obj : Series) return Float is
   begin
      return Obj.Cumulative_Integral;
   end Integral;

   function Average (Obj : Series) return Float is
   begin
      return Obj.Running_Average;
   end Average;

   function Maximum (Obj : Series) return Float is
   begin
      return Obj.Max;
   end Maximum;

   function Minimum (Obj : Series) return Float is
   begin
      return Obj.Min;
   end Minimum;

   function Delta_T (Obj : Series; Back : History := 1) return Duration is
      Curr : Sample renames Obj.Samples (Obj.Ptr);
      Prev : Sample renames Obj.Samples (Obj.Ptr - Order (Back));
   begin
      return Curr.Time - Prev.Time;
   end Delta_T;

end Pace.Time_Series;
