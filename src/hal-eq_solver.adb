with Text_IO;
procedure Hal.Eq_Solver
  (Y      : in Float_Type;
   Xf, Yf : out Float_Type;
   Cycles : out Integer)
is
   Xm, Xm0 : Float_Type;
   Ym      : Float_Type;
   DOpt    : Float_Type := Float_Type'Last;
   DLast   : Float_Type := DOpt;
   D       : Float_Type;
   Delta_X : Float_Type := (X1 - X0) / Starting_Partitions; 
   X_Last  : Float_Type;
begin
   Xf     := Float_Type'Last;
   Yf     := Float_Type'Last;
   Cycles := 0;
   Xm     := X0;
   X_Last := X1;
   loop
      loop
         Constraint (Xm, Ym);
         D := abs (Ym - Y);
         if D < DOpt and then Condition (Xm, Ym) then
            DOpt := D;
            Xf   := Xm;
            Yf   := Ym;
         end if;
         Xm0 := Xm;
         Xm := Xm + Delta_X;
         exit when Xm = Xm0; -- lost resolution completely
         exit when Xm >= X_Last;
      end loop;
      exit when Delta_X <= Float_Type'Epsilon; -- No point in trying again
      exit when DOpt = DLast; -- No match at all, keeps from looping endlessly
      Cycles := Cycles + 1;
      exit when abs (Yf - Y) < Eps;
      DLast   := DOpt;
      -- Back off from solution and try again. 
      Xm      := Float_Type'Max(X0, Xf - 2.0 * Delta_X); -- New lower bound
      X_Last  := Float_Type'Min(X1, Xf + 2.0 * Delta_X); -- New upper bound
      Delta_X := Delta_X / 10.0;
   end loop;
end Hal.Eq_Solver;
