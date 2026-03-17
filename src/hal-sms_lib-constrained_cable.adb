with Hal.Sms_Lib.Ribbon;
with Hal.Sms;
with Pace.Log;
with Ada.Numerics.Elementary_Functions;
with Hal.Vectors.Conjugate_Gradient_Search;
with Text_IO;

package body Hal.Sms_Lib.Constrained_Cable is
   
   package Vec is new Hal.Vectors (Float, Ada.Numerics.Elementary_Functions);
   Cable : Vec.Vector (1..Links) := (others => 0.00);

--    function Flex (Link : Integer; Current : Hal.Position)
--                  return Hal.Orientation is
--       Curvature : float;
--       C : Float;
--    begin
--       if Link = 1 then
--          C := Cable (Link);
--          Curvature := C;
--       else
--          C := Cable (Link); -- - Cable (Link-1);
--          Curvature := Link_Max_Angle * (1.0 - Ada.Numerics.Elementary_Functions.exp (- abs C/Link_Max_Angle));
--       end if;
--       return (0.0, Curvature, 0.0);
--       -- return (0.0, Cable (Link), 0.0);
--    end Flex;

   function Flex (Link : Integer; Current : Hal.Position)
                 return Hal.Orientation is
   begin
      return (0.0, Cable (Link), 0.0);
   end Flex;

--    function Flex (Link : Integer; Current : Hal.Position)
--                  return Hal.Orientation is
--    begin
-- --       if Cable(Link) > Link_Max_Angle then
-- --          return (0.0, Link_Max_Angle, 0.0);
-- --       elsif Cable(Link) < - Link_Max_Angle then
-- --          return (0.0, -Link_Max_Angle, 0.0);
-- --       else
-- --          return (0.0, Cable(Link), 0.0);
-- --       end if;
--       return (0.0, Cable (Link), 0.0);
--    end Flex;

--    function Flex (Link : Integer; Current : Hal.Position)
--                  return Hal.Orientation is
--       Curvature : float;
--       use Ada.Numerics;
--    begin
--       Curvature := Link_Max_Angle * (1.0 - Elementary_Functions.cos (Cable (Link) * PI /Link_Max_Angle));
--       return (0.0, Curvature, 0.0);
--    end Flex;

   package Track is new Hal.Sms_Lib.Ribbon (Base => (Pace.Msg with
                                                     Assembly => Hal.Sms.To_Name (Link_Name),
                                                     Pos => (0.0, 0.0, 0.0), -- Pos => (0.76, 0.0, 0.28),
                                                     Rot => (0.0, 0.0, 0.0), -- Rot => (0.0, Ada.Numerics.Pi/2.0, 0.0),
                                                     Entity => Hal.Sms.To_Name ("")),
                                            Segment => (0.0, 0.0, Link_Length),
                                            Flex => Flex,
                                            Links => Links,
                                            Time_Delta => 0.0); -- let us do the delay

   Penalty : constant Float := Float'Last / 1_000_000.0;
   PE, KE : Float;
   
   function Render (X, Y : in Float) return Hal.Position is

      P : Hal.Position;

      function f(C : Vec.vector) return Float is
         Distance : Float;
      begin
         PE := 0.0;
         KE := 0.0;
         Cable := C;
--         Track.Calculate_Deflection (P, PE, True); --False);
         P := Track.Calculate_Deflection (True); --False);
         PE := 10.0 * PE;
--         PE := 0.0;
--          for I in C'First+1 .. C'Last loop
-- --             if C(I) < 0.0 or C(I) > Link_Max_Angle then
-- --                -- Pace.Log.Put_Line ("Penalty");
-- --                PE := PE + 0.1*Link_Max_Angle*Link_Max_Angle + 1.0*(C(I)*C(I) - Link_Max_Angle*Link_Max_Angle);
--             if C(I)-C(I-1) < 0.0 then
--                KE := KE + 0.01*(C(I)-C(I-1))*(C(I)-C(I-1));
--             else
--                KE := KE + 1.0*(C(I)-C(I-1))*(C(I)-C(I-1));
--             end if;
--             null;
--             -- PE := PE + 1.0*(C(I)-Link_Max_Angle)*(C(I)-Link_Max_Angle);
-- --             if abs C(I) >= Link_Max_Angle then
-- --                PE := Float'Last/ 100000000.0;
-- --             else
-- --                PE := PE + 1.0/((C(I)-Link_Max_Angle)*(C(I)-Link_Max_Angle));
-- --             end if;
--          end loop;

            for I in C'First+1 .. C'Last loop
               KE := KE + C(I)*C(I);
            end loop;

--          for I in C'First+1 .. C'Last loop
--             if C(I) < -Link_Max_Angle or C(I) > 0.0 then
--                return Float'Last/1000000.0;
--             end if;
--          end loop;
         Distance := (P.Z - X)*(P.Z - X) + (P.X - Y)*(P.X - Y);
         -- Pace.Log.Put_Line ("PE" & PE'Img & C(1)'Img & Distance'Img);
         
         return - (Distance + PE + KE);
      end f;
 
      Accu : constant Float := Pace.getenv("ACC", 10.0);
      Init : constant Float := Pace.getenv("INI", 1000.0);
      Grad : constant Float := Pace.getenv("GRA", 1.0);
      package CJG is new Vec.Conjugate_Gradient_Search (F, Accu, Init, Grad); -- 1.0e-8);
      S : Vec.vector (1..Links) := (others => 0.0);
      Min : Float := 0.0;
      Temp : Float := -0.01;
   begin
      for I in Cable'Range loop
         --Temp := Temp + 0.2;
         Cable(I) := Temp;
      end loop;
      
      CJG.Minimize (Cable, S, Min);
      
      Pace.Log.Put_Line ("CJGmin:" & CJG.Number_Of_Iterations'Img & " iterations" & PE'Img);
      Track.Step (Number => 1, 
                  Relative_Orientation_Per_Link => True); --False);
      for I in Cable'Range loop
         Text_IO.Put (Cable(I)'Img & " ");
      end loop;
      Text_IO.New_Line;
      return P;
   end Render;

end Hal.Sms_Lib.Constrained_Cable;

