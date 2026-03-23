with Gis.Location;
with Acu;
with Vkb;
with Hal.Ve;
package Nav.Location is
  new Gis.Location (Acu.Vehicle,
                    Vkb,
                    Hal.Ve.Set);
