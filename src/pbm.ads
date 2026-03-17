with Pace;
package PBM is
   -- Physics-Based Models

   Gravity : constant Float := Float'Value(Pace.Getenv("GRAVITY", 
                                                       "9.80665")); -- m/s^2

   Ms_To_Kph_Factor : constant Float := 3.6;

   -- $Id: pbm.ads,v 1.6 2006/04/07 15:39:26 pukitepa Exp $

end;
