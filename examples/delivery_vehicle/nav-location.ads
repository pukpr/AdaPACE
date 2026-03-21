with Gis.Location;
with Acu;
with Vkb;

package Nav.Location is
  new Gis.Location (Acu.Vehicle,
                    Vkb);
