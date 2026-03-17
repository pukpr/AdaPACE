with Pace.Time_Series;
package Hal.Shaper is

   ----------------------------
   -- Shaper profile generation
   ----------------------------

   type Shape is access function
     (X, Xmax, V, Vmax, Accel, Decel : Float;
      Forward                        : Boolean := True)
   return                              Float;
   -- X in 0 .. XMax,  V in 0 .. VMax
   -- returns Acceleration

   -- Default Shape is Trapezoidal velocity profile
   function Trapezoid
     (X, Xmax, V, Vmax, Accel, Decel : Float;
      Forward                        : Boolean := True)
      return                           Float;

   -- Current state on the shaped profile
   type State is record
      X, V                     : Pace.Time_Series.Series;
      Time                     : Duration;
      Dt                       : Duration;
      Xmax, Vmax, Accel, Decel : Float;
      Profile                  : Shape;
   end record;

   --  Set once at the start of integration
   procedure Initialize
     (Obj                      : in out State;
      Dt                       : in Duration;
      Xmax, Vmax, Accel, Decel : in Float;
      Time                     : in Duration := Pace.Now;
      X, V                     : in Float    := 0.0;
      Profile                  : in Shape    := Trapezoid'Access);

   -- For constant DeltaTime integration
   procedure Integrate
     (Obj      : in out State;
      X        : out Float;
      Finished : out Boolean;
      Forward  : in Boolean := True);

   -- For constant DeltaX but varying DeltaTime integration
   procedure Advance
     (Obj      : in out State;
      X        : in Float;
      Time     : out Duration; -- Time until reached X
      Finished : out Boolean;
      Forward  : in Boolean := True);

   -- Calculate instantaneous velocity given place on trapezoid
   function Trapezoidal_Velocity
     (Tup, Tdown, Ttotal, T : Duration;
      Vmax                  : Float)
      return                  Float;

   -- Non-iterative solutions for Trapezoidal velocity curves only

   -- For a given X in 0..Xmax, return the Time it occurs
   function Get_Time (Xpos, Xmax, Vmax, Accel, Decel : Float;
                      Forward  : in Boolean := True) return Duration;

   -- For a given Time in the velocity profile, return the X position in 0..XMax
   function Get_Position
     (Time                     : Duration;
      Xmax, Vmax, Accel, Decel : Float;
      Forward  : in Boolean := True)
      return                     Float;

   -- $Id: hal-shaper.ads,v 1.6 2005/11/10 22:22:58 pukitepa Exp $
end Hal.Shaper;
