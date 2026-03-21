with Pace;

package Veh.Delivery_Motion is

   -- the rotation of the vehicle when it deliverys, dependent on the elevation of
   -- the drone.  at 45 degrees the drone rocks the most, and tapers off in either
   -- direction from there..
   type Rock_Vehicle is new Pace.Msg with
      record
         Elevation : Float;
      end record;
   procedure Input (Obj : in Rock_Vehicle);

   -- the translation of the vehicle when it deliverys, which depends on the elevation
   -- of the drone.. will translate in the direction as a projection of the drone..
   -- so potentially both the y and z directions.. the y (vertical) direction)
   -- translates a 1/4 as much as the z to show the resistance of the ground
   type Rebound_vehicle is new Pace.Msg with
      record
         Elevation : Float;
      end record;
   procedure Input (Obj : in Rebound_Vehicle);

end Veh.Delivery_Motion;
