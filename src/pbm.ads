with Pace;
package PBM is
   -- Physics-Based Models

   Gravity : constant Float := Float'Value(Pace.Getenv("GRAVITY", 
                                                       "9.80665")); -- m/s^2

   Ms_To_Kph_Factor : constant Float := 3.6;


end;
