package Pace.Time_Series is
   pragma Elaborate_Body;

   Frame_Overrun : exception;
   function Advance
     (Time                : Duration;
      Check_Frame_Overrun : Boolean := False)
      return                Duration;

   pragma Warnings(Off);
   type Order is mod 32;
   subtype History is Integer range 0 .. Integer (Order'Last);

   type Series is private;
   procedure Update (Obj : in out Series; 
                     Val : in Float; 
                     Time : in Duration := Pace.Now);

   function Predict (Obj : in Series;    -- "Dead Reckoned" value, considers velocity and accel
                     Time : in Duration := Pace.Now) return Float;

   -- Scale
   function "*" (Left : Float; Right : Series) return Float;

   -- Unit delay
   function "-" (Left : Series; Right : History) return Float;

   -- Construct/Convert
   function "+" (Right : Float) return Series;
   function "+" (Right : Series) return Float;

   -- Calculus
   function Acceleration (Obj : Series) return Float;
   function Derivative (Obj : Series) return Float;
   procedure Integrate (Obj : in out Series);
   function Integral (Obj : Series) return Float;
   function Delta_T (Obj : Series; Back : History := 1) return Duration;

   -- Statistics (depends on running an Integrate step)
   function Average (Obj : Series) return Float;
   function Maximum (Obj : Series) return Float;
   function Minimum (Obj : Series) return Float;

   Empty : constant Series;
   
private
   type Sample is record
      Value : Float    := 0.0;
      Time  : Duration := 0.0;
   end record;

   type Sample_Ring is array (Order) of Sample;

   type Series is record
      Ptr                 : Order    := Order'First;
      Samples             : Sample_Ring;
      Cumulative_Integral : Float    := 0.0;
      Running_Average     : Float    := 0.0;
      Cumulative_Time     : Duration := 0.0;
      Min                 : Float    := Float'Last;
      Max                 : Float    := Float'First;
      Average_Delta       : Float    := 0.0;
      Total_Count         : Float    := 0.0;
   end record;

   Empty : constant Series := (Order'First, (others => (0.0, 0.0)), 0.0, 0.0, 0.0, 
                               Float'Last, Float'First, 0.0, 0.0);

   -- $ID: pace-time_series.ads,v 1.2 12/16/2003 16:42:06 pukitepa Exp $
end Pace.Time_Series;
