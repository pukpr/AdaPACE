generic
   type Float_Type is digits <>;

   X0,                  -- Min of independent variable
     X1,                 -- Max of independent variable
     Eps : in Float_Type;  -- Error on result

   with procedure Constraint (Xm : in Float_Type;   -- Independent variable
     Ym : out Float_Type); -- Ym minimized against Y

   -- Typically, 2 solutions will result, use this to pick
   with function Condition (Xm, Ym : in Float_Type) return Boolean;
   
   Starting_Partitions : in Float_Type := 100.0; -- Initial (X1-X0) decimation

   -- $Id: hal-eq_solver.ads,v 1.4 2005/10/10 15:40:04 pukitepa Exp $
procedure Hal.Eq_Solver
  (Y      : in Float_Type; -- Dependent variable sol'n desired
   Xf, Yf : out Float_Type; -- Xf result, Yf gives error
   Cycles : out Integer); -- Cycles indicates result quality, 1 cycle=poor
