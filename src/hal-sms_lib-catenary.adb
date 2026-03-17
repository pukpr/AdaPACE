with Hal.Sms_Lib.Ribbon;
with Hal.Sms;
with Pace.Log;
with Ada.Numerics.Elementary_Functions;
with Hal.Vectors.Conjugate_Gradient_Search;

package body Hal.Sms_Lib.Catenary is
   
   Tana : Float := -10.0; --0.1;
   Tanb : Float := 10.0; -- -0.1;

   function Flex (Link : Integer; Current : Hal.Position)
                 return Hal.Orientation is
      Amt : Float;
      FL : constant Float := Float (Links);
   begin
      Amt := (Tana * Float(Links-Link) + Tanb * Float (Link)) / FL;
      Amt := Ada.Numerics.Elementary_Functions.Arctan (Amt);
      -- rotation about Z for X
      return (0.0, 0.0, Amt);
   end Flex;

   package Track is new Hal.Sms_Lib.Ribbon (Base => (Pace.Msg with
                                                     Assembly => Hal.Sms.To_Name (Link_Name),
                                                     Pos => (0.0, 0.0, 0.0),
                                                     Rot => (0.0, 0.0, 0.0),
                                                     Entity => Hal.Sms.To_Name ("")),
                                            Segment => (Link_Length, 0.0, 0.0),
                                            Flex => Flex,
                                            Links => Links,
                                            Time_Delta => 0.0); -- let us do the delay


   package Vec is new Hal.Vectors (Float, Ada.Numerics.Elementary_Functions);
   
   function Render (X, Y : in Float) return Hal.Position is
      Tan, S : Vec.vector (1..2) := (others => 0.0);
      Min : Float := 0.0;

      P : Hal.Position;

      function f(Tan : Vec.vector) return Float is
      begin
         Tana := Tan(1);
         Tanb := Tan(2);
         P := Track.Calculate_Deflection (Relative_Orientation_Per_Link => False);
         return (P.X - X)*(P.X - X) + (P.Y - Y)*(P.Y - Y);
      end f;

      package CJG is new Vec.Conjugate_Gradient_Search (F);
      
   begin
      Tan(1) := Tana;
      Tan(2) := Tanb;
      CJG.Minimize (Tan, S, Min);
      Pace.Log.Put_Line ("CJGmin:" & CJG.Number_Of_Iterations'Img & " iterations");
      Track.Step (Number => 1, 
                  Relative_Orientation_Per_Link => False);
      return P;
   end Render;

end Hal.Sms_Lib.Catenary;

