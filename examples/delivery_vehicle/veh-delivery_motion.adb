with Hal.Sms;
with Ada.Numerics.Elementary_Functions;

package body Veh.Delivery_Motion is

   procedure Input (Obj : in Rock_Vehicle) is
      use Ada.Numerics.Elementary_Functions;
      Freq : Hal.Rate := (Units => 0.1745, Second => 1);
      Damp : Hal.Rate := (Units => Hal.Rads (16.0), Second => 1);
      -- actual max rock is around 20 degrees.. here it must be higher in order
      -- to compensate for the dampening affect of the exponential decay
      Max_Rock : constant Float := Hal.Rads (-35.0);
      -- sin*cos gives us the upside down bowl affect with max
      -- at 45 and mins at 0 and 90... multiply by 2 to get a full percentage
      Rock_Percent : Float := 2.0 * Sin (Hal.Rads (Obj.Elevation)) * Cos (Hal.Rads (Obj.Elevation));
      Max_Time : Duration := 5.0;
      Start_Ori : Hal.Orientation := (0.0, 0.0, 0.0);
      Final_Ori : Hal.Orientation := (Rock_Percent * Max_Rock, 0.0, 0.0);
   begin
      Hal.Sms.Pendulum ("hull_motion", Start_Ori, Final_Ori, Freq, Damp, Max_Time);
   end;

   procedure Input (Obj : in Rebound_Vehicle) is
      use Ada.Numerics.Elementary_Functions;
      Freq : Hal.Rate := (Units => 0.1745, Second => 1);
      Damp : Hal.Rate := (Units => 1.0, Second => 1);
      -- actual max is less.. around .25 meters.. must be higher here to
      -- compensate for the dampening affects of the exponential decay
      Max_Rebound : constant Float := -0.75;  -- meters
      -- sin*cos with a shift of 45 degrees gives us the bowl affect with min
      -- at 45 ... multiply by 2 to get a full percentage
      Rebound_Percent : Float := 2.0 * Cos (Hal.Rads (Obj.Elevation + 45.0)) * Sin (Hal.Rads (Obj.Elevation + 45.0));
      Delta_H : Float := Max_Rebound * Rebound_Percent;  -- total translation distance
      Delta_Y : Float := 0.25 * Delta_H * Sin (Hal.Rads (Obj.Elevation)); -- translation in vertical direction
      Delta_Z : Float := Delta_H * Cos (Hal.Rads (Obj.Elevation)); -- translation in horizontal direction
      Start_Pos : Hal.Position := (0.0, 0.0, 0.0);
      Final_Pos : Hal.Position := (0.0, Delta_Y, Delta_Z);
      Max_Time : Duration := 5.0;
   begin
      Hal.Sms.Spring ("hull_motion", Start_Pos, Final_Pos, Freq, Damp, Max_Time);
   end;

end Veh.Delivery_Motion;
