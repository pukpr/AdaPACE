
package Ual.Probability is

   pragma Elaborate_Body;

   -- returns a uniformly distributed random number between 0.0 and 1.0
   function F_Random return Float;

   -- returns a random variable with the Exponential Distribution
   -- this is a shifted exponential if a minimum is supplied
   function Exponential_Random_Var
              (Mean : Float; Minimum : Float := 0.0) return Float;

   -- returns a random variable with the Gamma Distribution
   -- A Gamma random variable is the sum of Num_Exp_Vars indepedent
   -- exponential random variables each with a mean of Mean
   function Gamma_Random_Var
              (Mean : Float; Num_Exp_Vars : Integer) return Float;

end Ual.Probability;
