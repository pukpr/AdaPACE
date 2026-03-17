package body Hal.Vectors.Conjugate_Gradient_Search is

   Number_Iterations : Integer := 0;  -- Use only for debugging/non-reentrant

   -- --------------------------------------------------------------
   -- This function computes the gradient of the objective function
   -- at the point xx by finite difference. The current objective
   -- function value Fxx must be known
   procedure Gradient(xx : Vector;
                      Fxx : Real_Type;
                      Grad : out Vector) is
      xx_temp : Vector := xx;
   begin
      for j in xx'Range loop
         xx_temp(j) := xx_temp(j) + delta_g;  -- Perturb the j'th var by delta
         Grad(j) := (f(xx_temp)-Fxx)/delta_g;
      end loop;
   end Gradient;

   -- --------------------------------------------------------------
   -- This function computes a search direction ss given a gradient
   -- according to the conjugate gradient method. If the input variable
   -- itnr==0, the search direction is just the opposite of the gradient.
   -- If itno>0, it is modified according to the previous search direction,
   -- Oldss.

   procedure SearchDir(itnr : Integer;
                       Grad,OldGrad,Oldss : in Vector;
                       ss : out Vector) is

      beta : Real_Type;

   begin
      -- Always the opposite gradient
      ss := -Grad;

      -- Normalize
      Normalize(ss);

      -- If an old search direction is present, modify the new direction
      if itnr > 0 then
         beta := Grad * Grad / (OldGrad * OldGrad);
         ss := ss + Beta * Oldss;
      else
         return;  -- Don't normalize again unless we have modified ss
      end if;

      -- Normalize length after modification
      normalize(ss);

   end SearchDir;


   -- --------------------------------------------------------------
   -- This function minimizes the objective function by the conjugate
   -- gradient method.

   procedure Minimize (X : in out Vector;
                       S : out vector;
                       Result : out Real_Type) is

      -- --------------------------------------------------------------
      -- This is a one-dimensional version of the objective function
      -- given by the parameter alpha
      function falpha (alpha : Real_Type) return Real_Type is
         xx : vector := x;
      begin
         -- Construct point from x distance alpha along s
         xx := xx + alpha * s;

         -- Call the original function, Return the result to caller
         return f(xx);
      end falpha;

      procedure GoldenSectionSearch(A_Start, B_Start : in Real_Type;
                                    alpha : in out Real_Type;
                                    Result : out Real_Type) is

         A : Real_Type := A_Start;
         B : Real_Type := B_Start;
         Golden,Length,Alpha1,Alpha2,fAlpha1,fAlpha2 : Real_Type;
         N : Integer;

      begin

         -- ---------------------------------------------
         -- Golden section search in the initial interval

         Golden := 0.381966;

         -- Compute the two golden section points
         Length := B-A;
         Alpha1 := A + Golden*Length;
         Alpha2 := B - Golden*Length;

         -- And their function values
         fAlpha1 := falpha(Alpha1);
         fAlpha2 := falpha(Alpha2);

         -- Loop N times. This reduces the search interval to a certain
         -- 0.618^N of the initial size.

         N := 30;
         for n1 in 1..N loop
            -- Reduce the interval length
            Length := Length*(1.0-Golden);

            -- Use the left hand interval, if the function value at the
            -- right hand golden point is the larger
            if fAlpha2>fAlpha1 then
               -- Shift re-usable results left
               B := Alpha2;
               Alpha2 := Alpha1;
               fAlpha2 := fAlpha1;
               -- Compute new Alpha1 and function value
               Alpha1 := A + Golden*Length;
               fAlpha1 := falpha(Alpha1);
               -- otherwise, use the right hand interval
            else
               -- Shift re-usable results left
               A := Alpha1;
               Alpha1 := Alpha2;
               fAlpha1 := fAlpha2;
               -- Compute new Alpha2 and function value
               Alpha2 := B - Golden*Length;
               fAlpha2 := falpha(Alpha2);
            end if;
         end loop;     -- Golden section loop

         -- Return the smallest result
         if fAlpha1 < fAlpha2 then
            alpha := Alpha1;
            Result := fAlpha1;
         else
            alpha := Alpha2;
            Result := fAlpha2;
         end if;

      end GoldenSectionSearch;

      A,B,Fxx : Real_Type;
      df, OldGrad, OldS : vector (x'Range) := (others => 0.0);
      count : Integer;
      alpha : Real_Type := Alpha_0;

   begin

      B := 4.0;   -- Search length. Fits the banana function
      count := 0;

      -- Compute current objective
      Fxx := f(x);

      -- Main loop. Keep minimizing until the change is small enough
      while alpha > Epsilon loop -- and count < 1000 loop

         -- Todo: Program the search direction -> 1-D minimization here

         -- Calculate gradient by finite difference
         Gradient(x,Fxx,df);

         -- Find conjugate gradient search direction
         SearchDir(count,df,OldGrad,OldS,s);

         -- Minimize along s by the golden section method
         A := 0.0;
         GoldenSectionSearch(A,B,alpha,Fxx);

         -- Set next search interval according to the present
         B := 2.0*alpha;

         -- Update design variables
         X := X + alpha * s;

         count := count + 1;
         -- Store old gradient and search direction
         OldGrad := df;
         OldS := s;
      end loop;

      Number_Iterations := Count;
      Result := Fxx;
   end Minimize;


   function Number_Of_Iterations return Integer is
   begin
      return Number_Iterations;
   end;

end Hal.Vectors.Conjugate_Gradient_Search;
