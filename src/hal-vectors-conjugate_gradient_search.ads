generic
   with function F (V : in Vector) return Real_Type;
   Epsilon : in Real_Type := 0.01;   -- Precision in error
   Alpha_0 : in Real_Type := 10.0;   -- Initial error
   Delta_G : in Real_Type := 0.001;  -- Perturbation on gradient
package Hal.Vectors.Conjugate_Gradient_Search is 
   
   -- --------------------------------------------------------------
   -- This function identifies the minimum of f by golden section search. 
   -- The initial search interval is given by the end points A and B, where A < B.
   -- The function returns the minimum value of f, and the variable
   -- alpha contains the variable value for which the minimum value occurs.
   -- Initial interval is determined before beginning golden section search
   -- Starting the initial interval search from point A

   procedure Minimize (X : in out Vector;
                       S : out Vector;
                       Result : out Real_Type);

   -- Convenience/debugging
   function Number_Of_Iterations return Integer;
   
end Hal.Vectors.Conjugate_Gradient_Search;
