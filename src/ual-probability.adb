with Ada.Numerics;
with Ada.Numerics.Float_Random;
with Ada.Numerics.Elementary_Functions;

package body Ual.Probability is

   use Ada.Numerics.Elementary_Functions;
   use Ada.Numerics;

   package Ran renames Ada.Numerics.Float_Random;
   G : Ran.Generator;

   function F_Random return Float is
   begin
      return Ran.Random (G);
   end F_Random;

   function Exponential_Random_Var
              (Mean : Float; Minimum : Float := 0.0) return Float is
      Shifted_Mean : Float := Mean - Minimum;
   begin
      return (-Shifted_Mean * Log (F_Random, E) + Minimum);
   end Exponential_Random_Var;

   function Gamma_Random_Var
              (Mean : Float; Num_Exp_Vars : Integer) return Float is
      Multiplied_Uniform_Vars : Float := 1.0;
   begin
      for I in 1 .. Num_Exp_Vars loop
         Multiplied_Uniform_Vars := F_Random * Multiplied_Uniform_Vars;
      end loop;
      return (-Log (Multiplied_Uniform_Vars, E) / Mean);
   end Gamma_Random_Var;

begin
   -- this sets the random number generator to a time dependent state, which
   -- means the seed is taken from the time and so application results will be
   -- different from run to run
   Ran.Reset (G);
end Ual.Probability;
