with Pace.Notify;

-- Note:  there is no corresponding body for the spec. Uio.Vehicle_Status
-- utilizes this type.  It is located here purely for clarity of design.
package Veh.Vehicle_Status is

   type Vehicle_Component is (A, B, C, D, E, F, Drone);

   type Component_Status is (Up, Down);

   type Modify_Vehicle_Status is new Pace.Notify.Subscription with
      record
         Component : Vehicle_Component;
         Status : Component_Status;
      end record;
end Veh.Vehicle_Status;
