generic
   X0, X1,             -- Max and Min extents on free end
   DX,                 -- Iteration Delta X
   Length : in Float;  -- "Pinion Rod" Length

   -- Free end constraint on pinion rod
   with procedure Constraint (Xm : in Float;
                              Ym : out Float);

   -- Typically, 2 solutions will result, use this to pick
   with function Condition (X,Y,Xm,Ym : in Float) return Boolean;

procedure Hal.Constraint_2d (X, Y: in Float;     -- Fixed end of rod
                             Theta : out Float;  -- Arctan (Y/X)
                             Scale : out Float); -- Stretch of rod

