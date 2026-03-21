with Vkb;
with Nav.Location;
with Gis.Obstacle_Reporter;

package Nav.Obstacle_Reporter is
  new Gis.Obstacle_Reporter (Nav.Location,
                             Vkb);
