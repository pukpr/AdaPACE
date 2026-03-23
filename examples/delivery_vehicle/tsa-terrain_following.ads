with Vkb;
with Gis.Terrain_Following;
with Nav.Location;
with Acu;
with Hal.Ve;

package Tsa.Terrain_Following is
  new Gis.Terrain_Following (Delta_Time => 3.0,
                             Mobility => Acu.Vehicle,
                             Loc => Nav.Location,
                             Kb => Vkb,
                             Get_Coordinate => Hal.Ve.Get_Coordinate,
                             Get_Terrain_Elev => Hal.Ve.Get_Terrain_Elevation);



