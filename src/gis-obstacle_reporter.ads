with Gkb;
with Gis.Location;

generic
   with package Loc is new Gis.Location (<>);
   with package Kb is new Gkb (<>);
   -- At runtime, Kb should have matches for the following :
   -- obstacle_point (X, Y, Description).
package Gis.Obstacle_Reporter is

   pragma Elaborate_Body;

end Gis.Obstacle_Reporter;
