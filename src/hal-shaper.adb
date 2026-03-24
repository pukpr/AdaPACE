with Ada.Numerics.Elementary_Functions;
with Pace.Log;

package body Hal.Shaper is

   Kx : constant := 10.0; -- Position sub-integration factor

   function Trapezoid
     (X, Xmax, V, Vmax, Accel, Decel : Float;
      Forward                        : Boolean := True)
      return                           Float
   is
      Dist : constant Float := Vmax * Vmax / 2.0 / Decel;
   begin
      if Forward then
         if X > Xmax - Dist then
            return -Decel;
         elsif V < Vmax then
            return Accel;
         end if;
      else
         if X < Dist then
            return Decel;
         elsif V > -Vmax then
            return -Accel;
         end if;
      end if;
      return 0.0;
   end Trapezoid;

   procedure Initialize
     (Obj                      : in out State;
      Dt                       : in Duration;
      Xmax, Vmax, Accel, Decel : in Float;
      Time                     : in Duration := Pace.Now;
      X, V                     : in Float    := 0.0;
      Profile                  : in Shape    := Trapezoid'Access)
   is

   begin
      Obj.Dt    := Dt;
      Obj.Xmax  := Xmax;
      Obj.Vmax  := Vmax;
      Obj.Accel := Accel;
      Obj.Decel := Decel;
      Obj.Time  := Time;
      Pace.Time_Series.Update (Obj.V, V);
      Pace.Time_Series.Update (Obj.X, X);
      Obj.Profile := Profile;
   end Initialize;

   procedure Integrate
     (Obj      : in out State;
      X        : out Float;
      Finished : out Boolean;
      Forward  : in Boolean := True)
   is
      use Pace.Time_Series;
      Dt   : constant Float := Float (Obj.Dt);
      A, V : Float;
   begin
      Obj.Time := Advance (Obj.Time + Obj.Dt);
      V        := Obj.V - 0;
      A        :=
         Obj.Profile
           (Obj.X - 0,
            Obj.Xmax,
            Obj.V - 0,
            Obj.Vmax,
            Obj.Accel,
            Obj.Decel,
            Forward);
      Update (Obj.V, Obj.V - 0 + Dt * A);
      Update (Obj.X, Obj.X - 0 + Dt * V + 0.5 * Dt * Dt * A);

      --      Update (Obj.X, Obj.X - 0 + Dt * (Obj.V - 0));
      --      Update (Obj.V, Obj.V - 0 +
      --                       Dt * Obj.Profile (Obj.X - 1, Obj.Xmax, Obj.V -
      --0,
      --                                         Obj.Vmax, Obj.Accel,
      --                                         Obj.Decel, Forward));
      X := +Obj.X;
      if Forward then -- Finished when starts to reverse direction
         Finished := Obj.X - 1 > Obj.X - 0 or Obj.X - 0 >= Obj.Xmax;
      else
         Finished := Obj.X - 0 > Obj.X - 1 or Obj.X - 0 <= Obj.Xmax;
      end if;
   end Integrate;

   procedure Advance
     (Obj      : in out State;
      X        : in Float;
      Time     : out Duration;
      Finished : out Boolean;
      Forward  : in Boolean := True)
   is
      Old_Dt : constant Duration := Obj.Dt;
      Dt     : constant Duration := Obj.Dt / Kx;
      Start  : constant Duration := Obj.Time;
      use type Pace.Time_Series.Series;
      New_X  : Float             := +Obj.X;
   begin
      if Forward then
         while X > New_X loop
            Integrate (Obj, New_X, Finished, Forward);
         end loop;
      else
         while X < New_X loop
            Integrate (Obj, New_X, Finished, Forward);
         end loop;
      end if;
      Obj.Dt := Old_Dt;
      Time := Obj.Time - Start;
   end Advance;

   function Trapezoidal_Velocity
     (Tup, Tdown, Ttotal, T : Duration;
      Vmax                  : Float)
      return                  Float
   is
   begin
      if T <= Tup then
         return Vmax * Float (T) / Float (Tup);
      elsif T <= Ttotal - Tdown then
         return Vmax;
      else
         return Vmax * Float (Ttotal - T) / Float (Tdown);
      end if;
   end Trapezoidal_Velocity;

   generic -- this gets shared by the Get_Time and Get_Position functions
      Xmax, Vmax, Accel, Decel : Float;
   package Transition_Points is
      -- If tp > 0.0, a plateau exists on the trapezoid
      tp : constant Float :=
         Xmax / Vmax - Vmax * (1.0 / Accel + 1.0 / Decel)/2.0;
      -- Time to reach max velocity
      t0 : constant Float := Vmax / Accel;
      -- Time to reach zero velocity from the max
      t1 : constant Float := Vmax / Decel;
      -- Distance to the max velocity
      x0 : constant Float := 0.5 * Accel * t0 * t0;
      -- Distance to the end of the plateau
      x1 : constant Float := Xmax - 0.5 * Decel * t1 * t1;
      -- Transition point velocity if Max plateau Velocity not reached
      VT : constant Float :=
         Ada.Numerics.Elementary_Functions.Sqrt
           (2.0 * Xmax / (1.0 / Accel + 1.0 / Decel));
   end Transition_Points;


   function Get_Time (Xpos, Xmax, Vmax, Accel, Decel : Float;
                      Forward  : in Boolean := True) return Duration is
      package Trans is new Transition_Points (Xmax, Vmax, Accel, Decel);
      use Trans;
      X : Float;
   begin
      if Forward then
         X := Xpos;
      else
         X := Xmax - Xpos;
      end if;
      if tp >= 0.0 then -- Trapezoid contains a plateau or reached max velocity
         if X < 0.0 then
            return 0.0;
         elsif X < x0 then -- On the way up
            return Duration (Ada.Numerics.Elementary_Functions.Sqrt
                                (2.0 * X / Accel));
         elsif X < x1 then -- On the plateau
            return Duration (t0 + (X - x0) / Vmax);
         elsif X <= Xmax then -- On the way down
            return Duration (t0 +
                             (x1 - x0) / Vmax +
                             t1 -
                             Ada.Numerics.Elementary_Functions.Sqrt
                                (2.0 * (Xmax - X) / Decel));
         else -- Beyond XMax
            return Get_Time (Xmax, Xmax, Vmax, Accel, Decel);
         end if;
      else -- Recursively call with a new max velocity
         return Get_Time (Xpos, Xmax, VT, Accel, Decel, Forward);
      end if;
   end Get_Time;

   function Get_Position
     (Time                     : Duration;
      Xmax, Vmax, Accel, Decel : Float;
      Forward  : in Boolean := True)
      return                     Float
   is
      package Trans is new Transition_Points (Xmax, Vmax, Accel, Decel);
      use Trans;
      T : constant Float := Float (Time);
      -- Going backwards from XMax if not Forward
      function R (X : in Float) return Float is
      begin
         if Forward then
            return X;
         else
            return Xmax - X;
         end if;
      end;
   begin
      if Xmax = 0.0  then
         return 0.0;
      end if;
      if tp >= 0.0 then -- Trapezoid contains a plateau or reached max velocity
         if T < 0.0 then
            return R(0.0);
         elsif T < t0 then -- On the way up
            return R(0.5 * Accel * T * T);
         elsif T < t0 + tp then -- On the plateau
            return R(x0 + (T - t0) * Vmax);
         elsif T <= t0 + tp + t1 then -- On the way down
            return R(x1 +
                   (T - t0 - tp) * (Vmax - 0.5 * Decel * (T - t0 - tp)));
         else
            return R(Xmax);
         end if;
      else -- Recursively call with a new max velocity
         Pace.Log.Put_Line ("#### rshaper : " & Duration'Image(Time) & " " & Xmax'Img & " " & Vt'Img & " " & Accel'Img & " " & Decel'Img, 10);
         return Get_Position (Time, Xmax, VT*0.999999, Accel, Decel, Forward);
      end if;
   end Get_Position;

end Hal.Shaper;
