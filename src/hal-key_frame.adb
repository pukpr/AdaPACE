with Ada.Numerics.Long_Elementary_Functions;
--with Sal.Gen_Math.Gen_Square_Array.Gen_Inverse;

package body Hal.Key_Frame is

   function Dist (P1, P2 : Position) return Long_Float is
      use Ada.Numerics.Long_Elementary_Functions;
   begin
      return Sqrt
               (Long_Float(P1.X - P2.X) * Long_Float(P1.X - P2.X) +
                Long_Float(P1.Y - P2.Y) * Long_Float(P1.Y - P2.Y) +
                Long_Float(P1.Z - P2.Z) * Long_Float(P1.Z - P2.Z));
   end Dist;

   function Line_Length (p1 : Points) return Float is
      L : Long_Float := 0.0;
   begin
      for I in  2 .. p1'Length loop
         L := L + Dist (p1 (I), p1 (I - 1));
      end loop;
      return Float(L);
   end Line_Length;

   procedure Line_uniform (p1 : in Points; p2 : out Points) is
      S      : array (p1'Range) of Long_Float;
      npts   : constant Integer := p1'Length;
      opts   : constant Integer := p2'Length;
      L, DL  : Long_Float       := 0.0;
      So_Far : Long_Float       := 0.0;
      Scale  : Float;
   begin
      S (1) := 0.0;
      for I in 2 .. npts loop
         L     := L + Dist (p1 (I), p1 (I - 1));
         S (I) := L;
      end loop;
      DL     := L / Long_Float (opts - 1);
      p2 (1) := p1 (1);
      for J in  2 .. opts loop
         So_Far := So_Far + DL;
         for I in reverse  1 .. npts - 1 loop
            if S (I) < So_Far then
               Scale    := Float ((So_Far - S (I)) / (S (I + 1) - S (I)));
               p2 (J).X := p1 (I).X + (p1 (I + 1).X - p1 (I).X) * Scale;
               p2 (J).Y := p1 (I).Y + (p1 (I + 1).Y - p1 (I).Y) * Scale;
               p2 (J).Z := p1 (I).Z + (p1 (I + 1).Z - p1 (I).Z) * Scale;
               exit;
            end if;
         end loop;
      end loop;
   end Line_uniform;

   function Line_Position (p1 : Points; T : TFloat) return Position is
      S      : array (p1'Range) of Long_Float;
      npts   : constant Integer := p1'Length;
      L      : Long_Float       := 0.0;
      So_Far : Long_Float       := 0.0;
      Scale  : Float;
      Pos    : Position;
   begin
      S (1) := 0.0;
      for I in  2 .. npts loop
         L     := L + Dist (p1 (I), p1 (I - 1));
         S (I) := L;
      end loop;
      So_Far := Long_Float(T) * L;
      for I in reverse  1 .. npts - 1 loop
         if S (I) < So_Far then
            Scale := Float ((So_Far - S (I)) / (S (I + 1) - S (I)));
            Pos.X := p1 (I).X + (p1 (I + 1).X - p1 (I).X) * Scale;
            Pos.Y := p1 (I).Y + (p1 (I + 1).Y - p1 (I).Y) * Scale;
            Pos.Z := p1 (I).Z + (p1 (I + 1).Z - p1 (I).Z) * Scale;
            return Pos;
         end if;
      end loop;
      return p1 (1);
   end Line_Position;

--    package Gm is new Sal.Gen_Math (Long_Float);
--    type Three is new Integer range 1 .. 3;
--    type Vector is array (Three) of Long_Float;
--    type Matrix is array (Three) of Vector;
--    package Gm3 is new Gm.Gen_Square_Array (Three, Vector, Matrix,
--                                            Ada.Numerics.Long_Elementary_Functions.Sqrt);
--    function Gm3inv is new Gm3.Gen_Inverse;

   function Spline_Position (p1 : Points; T : TFloat) return Position is
   begin
      return line_Position (p1, T);
   end Spline_Position;


   function Y (p1 : Points; X : Float;
               Dt : Float := 0.01;
               Eps : Float := 0.01 ) return Float is
      T : Float := 0.0;
      Pos : Position;
      VEps : Float := Eps;
   begin
      loop
         loop
            Pos := Line_Position (p1, T);
            if abs (pos.X - X) < VEps then
               return Pos.Y;
            end if;
            T := T + Dt;
            exit when T > 1.0;
         end loop;
         T := 0.0;
         VEps := VEps * 10.0;
      end loop;
      --unreachable return Float'Last;
   end;

   function X (p1 : Points; Y : Float;
               Dt : Float := 0.01;
               Eps : Float := 0.01 ) return Float is
      T : Float := 0.0;
      Pos : Position;
      VEps : Float := Eps;
   begin
      loop
         loop
            Pos := Line_Position (p1, T);
            if abs (pos.Y - Y) < VEps then
               return Pos.X;
            end if;
            T := T + Dt;
            exit when T > 1.0;
         end loop;
         T := 0.0;
         VEps := VEps * 10.0;
      end loop;
      --unreachable return Float'Last;
   end;

   function Line_Position
     (p1   : FPoints;
      Var  : Float;
      T    : TFloat)
      return Position
   is
      P : Points (p1'Range);
   begin
      for I in  p1'Range loop
         P (I) := p1 (I) (I, Var);
      end loop;
      return Line_Position (P, T);
   end Line_Position;

   function Line_Length (p1 : FPoints; Var : Float) return Float is
      P : Points (p1'Range);
   begin
      for I in  p1'Range loop
         P (I) := p1 (I) (I, Var);
      end loop;
      return Line_Length (P);
   end Line_Length;

end Hal.Key_Frame;
