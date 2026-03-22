with Sal.Gen_Math.Gen_Square_Array.Gen_Inverse;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics.Elementary_Functions;
with Pace.Semaphore;

package body Pbm.Bfpath is

   procedure Op4_Bfpath_Initialize
     (Object_Type                                                        : in
     Integer;
      Launch_Time, Azimuth, Elevation_Angle, Initial_Speed, Src_Lat, Src_Long, Src_Hgt : in
     Long_Float);
   pragma Import (C, Op4_Bfpath_Initialize);

   procedure Op4_Bfpath_Update (Run_Until : in Long_Float);
   pragma Import (C, Op4_Bfpath_Update);

   procedure Op4_Bfpath_Get
     (Time             : in Long_Float;
      X, Y, Z, U, V, W : out Long_Float;
      T                : out Long_Float);
   pragma Import (C, Op4_Bfpath_Get);

   procedure Initialize
     (Object_Type                                                        : in
        Integer;
      Launch_Time, Azimuth, Elevation_Angle, Initial_Speed, Src_Lat, Src_Long, Src_Hgt : in
        Float)
   is
   begin
      Op4_Bfpath_Initialize
        (Object_Type,
         Long_Float (Launch_Time),
         Long_Float (Azimuth),
         Long_Float (Elevation_Angle),
         Long_Float (Initial_Speed),
         Long_Float (Src_Lat),
         Long_Float (Src_Long),
         Long_Float (Src_Hgt));
   end Initialize;

   procedure Update (Run_Until : in Duration) is
   begin
      Op4_Bfpath_Update (Long_Float (Run_Until));
   end Update;

   procedure Get
     (Time             : in Duration;
      X, Y, Z, U, V, W : out Float;
      T                : out Duration)
   is
      New_Time : Long_Float;
   begin
      Op4_Bfpath_Get
        (Long_Float (Time),
         Long_Float (X),
         Long_Float (Y),
         Long_Float (Z),
         Long_Float (U),
         Long_Float (V),
         Long_Float (W),
         New_Time);
      T := Duration (New_Time);
   end Get;

   M : aliased Pace.Semaphore.Mutex;

   function Generate_Flight_Path
     (Object_Type                            : in Integer;
      Launch_Time, Azimuth, Elevation_Angle, Initial_Speed : in Float;
      Src_Lat, Src_Long, Src_Hgt           : in Float;
      Total_Time                           : in Second_Tics := 150)
      return                                 Flight_Path_Data
   is
      Fp               : Flight_Path_Data (0 .. Total_Time);
      X, Y, Z, U, V, W : Float;
      Current_Time, T  : Duration := 1.0;
      L                : Pace.Semaphore.Lock (M'Access);
      Tangent_Angle    : Float;
   begin
      Initialize
        (Object_Type,
         Launch_Time,
         Azimuth,
         Elevation_Angle,
         Initial_Speed,
         Src_Lat,
         Src_Long,
         Src_Hgt);
      for I in  0 .. Total_Time loop
         Current_Time := Duration (I);
         Update (Current_Time);
         Get (Current_Time, X, Y, Z, U, V, W, T);
         if W /= 0.0 then
            -- slope = vertical_velocity / horizontal velocity)
            Tangent_Angle := -Ada.Numerics.Elementary_Functions.Arctan (U / W);
         else
            Tangent_Angle := -Ada.Numerics.Pi / 2.0;
         end if;
         Fp (I) := (X, Y, Z, U, V, W, T, Tangent_Angle);
      end loop;
      return Fp;
   end Generate_Flight_Path;

   package Gm is new Sal.Gen_Math (Long_Float);
   type Three is new Integer range 1 .. 3;
   type Vector is array (Three) of Long_Float;
   type Matrix is array (Three) of Vector;
--   package Math is new Ada.Numerics.Generic_Elementary_Functions (
--      Long_Float);
   package Gm3 is new Gm.Gen_Square_Array (Three, Vector, Matrix,
                                           Ada.Numerics.Long_Elementary_Functions.Sqrt);
   function Gm3inv is new Gm3.Gen_Inverse;

   function Get_Data
     (Fp   : in Flight_Path_Data;
      Time : in Duration)
      return Flight_Path_Record
   is
      Tics                   : constant Second_Tics := Second_Tics (Time);
      Back, Curr, Next       : Second_Tics;
      X0, X1, X2, T0, T1, T2 : Long_Float;
      M, Minv                : Matrix;
      Abc, Xxx               : Vector;
      Fpr                    : Flight_Path_Record;
      use Gm3;
      function Interpolate (F1, F2, F3 : in Float) return Float is
         T  : constant Float := Float (Time);
         Tu : constant Float := Float'Ceiling (T);
         Tl : constant Float := Float'Floor (T);
      begin
         if Tu = Tl then
            return F2;
         elsif Tics < 1 then -- No history
            return F2 + (F3 - F2) * (T - Tl) / (Tu - Tl);
         elsif Time > Duration (Tics) then
            return F2 + (F3 - F2) * (T - Tl) / (Tu - Tl);
         else
            return F1 + (F2 - F1) * (T - Tl) / (Tu - Tl);
         end if;
      end Interpolate;
   begin
      -- X0 = A*T0*T0 + B*T0 + C    X0   | T0*T0 T0 1.0 | A      A    -1 X0
      -- X1 = A*T1*T1 + B*T1 + C    X1 = | T1*T1 T0 1.0 | B =>   B = M   X1
      -- X2 = A*T2*T2 + B*T2 + C    X2   | T2*T2 T2 1.0 | C      C       X2
      if Time <= 0.0 then
         return Fp (0);
      end if;

      Fpr := Fp (Second_Tics (Time));

      if Tics > 0 then
         Back := Tics-1;
         Curr := Tics;
         Next := Tics+1;

         X0 := Long_Float (Fp (Back).X);
         X1 := Long_Float (Fp (Curr).X);
         X2 := Long_Float (Fp (Next).X);
         T0 := Long_Float (Float (Back));
         T1 := Long_Float (Float (Curr));
         T2 := Long_Float (Float (Next));
         M    :=
           (1 => (T0 * T0, T0, 1.0),
            2 => (T1 * T1, T1, 1.0),
            3 => (T2 * T2, T2, 1.0));
         Minv := Gm3inv (M);
         Xxx := (X0, X1, X2);
         Abc := Minv * Xxx;
         Xxx := M * Abc;
         Fpr.X :=
           Float (Abc (1) * Long_Float (Time) * Long_Float (Time) +
                  Abc (2) * Long_Float (Time) +
                  Abc (3));
      else -- No history
         Back := Tics;
         Curr := Tics;
         Next := Tics+1;
         Fpr.X := Interpolate (Fp (Back).X, Fp (Curr).X, Fp (Next).X);
      end if;

      Fpr.Y := Interpolate (Fp (Back).Y, Fp (Curr).Y, Fp (Next).Y);
      Fpr.Z := Interpolate (Fp (Back).Z, Fp (Curr).Z, Fp (Next).Z);
      Fpr.U := Interpolate (Fp (Back).U, Fp (Curr).U, Fp (Next).U);
      Fpr.V := Interpolate (Fp (Back).V, Fp (Curr).V, Fp (Next).V);
      Fpr.W := Interpolate (Fp (Back).W, Fp (Curr).W, Fp (Next).W);
      return Fpr;
   end Get_Data;

end Pbm.Bfpath;
