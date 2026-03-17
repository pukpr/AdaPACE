with Pace.Notify;
with Pace.Strings;

package Hal.Ve_Lib.Projectile_Motion is

   pragma Elaborate_Body;

   -- The accuracy_radius will add a random factor to the flight.
   -- Projectile will be offset uniformly between 0.0 (perfect accuracy) and Accuracy_Radius
   type Launch_Projectile is new Pace.Msg with
     record
        Theta : Float; -- initial angle in radians
        Initial_Velocity : Float;  -- m/s
        Start_Pos : Hal.Position; -- absolute
        Heading : Float; -- direction of launch in radians
        Target_Pos : Hal.Position := (0.0, 0.0, 0.0); -- for knowing when the projectile will land
        Munition : Pace.Strings.Bstr.Bounded_String;
        Accuracy_Radius : Float := 10.0;
     end record;
   procedure Input (Obj : Launch_Projectile);

   -- Notification of projectile positions
   type Update is new Pace.Notify.Subscription with
      record
         Pid : Pace.Strings.Bstr.Bounded_String;
         Pos : Hal.Position;
         Ori : Hal.Orientation;
      end record;

   -- Notification of projectile landing
   type Landed is new Pace.Notify.Subscription with
      record
         Pid : Pace.Strings.Bstr.Bounded_String;
         Pos : Hal.Position;
      end record;

end Hal.Ve_Lib.Projectile_Motion;
