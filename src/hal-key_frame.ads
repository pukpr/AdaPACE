package Hal.Key_Frame is

   type Points is array (Positive range <>) of Position;

   procedure Line_uniform (p1 : in Points; p2 : out Points);

   subtype TFloat is Float range 0.0 .. 1.0;

   function Line_Position (p1 : Points; T : TFloat) return Position;

   function Line_Length (p1 : Points) return Float;

   function Y (p1 : Points; X : Float;
               Dt : Float := 0.01;
               Eps : Float := 0.01 ) return Float;
   function X (p1 : Points; Y : Float;
               Dt : Float := 0.01;
               Eps : Float := 0.01 ) return Float;

   function Spline_Position (p1 : Points; T : TFloat) return Position;

   --- Callback variant assuming points vary according to a single parameter

   type FPoint is access function
     (Index : Positive;
      Var   : Float)
   return     Position;
   type FPoints is array (Positive range <>) of FPoint;

   function Line_Position
     (p1   : in FPoints;
      Var  : in Float;
      T    : in TFloat)
      return Position;

   function Line_Length (p1 : FPoints; Var :  Float) return Float;

end Hal.Key_Frame;
