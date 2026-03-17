with Ada.Numerics.Elementary_Functions;
procedure Hal.Constraint_2d (X, Y: in Float;
                             Theta : out Float;
                             Scale : out Float) is
   use Ada.Numerics.Elementary_Functions;
   Xm : Float := X0;
   Ym : Float;
   -- Xopt, Yopt : Float := Float'Last;
   Xopt1, Yopt1 : Float := Float'Last;
   Xopt2, Yopt2 : Float := Float'Last;
   -- Dopt : Float := Float'Last;
   Dopt1, Dopt2 : Float := Float'Last;
   D, D2 : Float;
   type Pending_Solution is (None, First, Found);
   Pending : Pending_Solution := None;
   -- Last_Pending : Boolean := False;
begin
   loop
      Constraint (Xm, Ym);
      D2 := (X-Xm)*(X-Xm) + (Y-Ym)*(Y-Ym);
      D := abs (D2 - Length*Length);
   -- if D < Dopt and then Condition(X,Y,Xm,Ym) then
      if D < Dopt1 and then Condition(X,Y,Xm,Ym) then
         -- Dopt := D;
         -- Xopt := Xm;
         -- Yopt := Ym;
         Dopt1 := D;
         Xopt1 := Xm;
         Yopt1 := Ym;
      elsif Pending = None then
         Pending := First;
      elsif Pending = First then
         Dopt2 := Dopt1;  -- save last optimum in case there are 2 degenerate
         Xopt2 := Xopt1;  -- save last optimum positions
         Yopt2 := Yopt1;
         Pending := Found;
      end if;
      Xm := Xm + Dx;
      exit when Xm >= X1;
   end loop;
-- if Dopt = Float'Last then
   if Dopt1 = Float'Last then
      Theta := 0.0;
      Scale := 0.0;
   else
      --Theta := arctan (Yopt - Y, Xopt - X);
      --Scale := ((X-Xopt)*(X-Xopt) + (Y-Yopt)*(Y-Yopt)) / (Length*Length);
      declare
         Xopt : Float := Xopt2; 
         Yopt : Float := Yopt2;
      begin
         if Dopt2 = Float'Last then
            Xopt := Xopt1; 
            Yopt := Yopt1;
         end if;      
         Theta := arctan (Yopt - Y, Xopt - X);
         Scale := ((X-Xopt)*(X-Xopt) + (Y-Yopt)*(Y-Yopt)) / (Length*Length);
      end;
   end if;
end;


