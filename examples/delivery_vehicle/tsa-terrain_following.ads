with Vkb;
with Gis.Terrain_Following;
with Nav.Location;
with Acu;

package Tsa.Terrain_Following is
  new Gis.Terrain_Following (Delta_Time => 3.0,
                             Mobility => Acu.Vehicle,
                             Loc => Nav.Location,
                             Kb => Vkb);



