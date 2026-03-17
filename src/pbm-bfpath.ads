package Pbm.Bfpath is

   type Flight_Path_Record is record
      X, Y, Z, U, V, W : Float;
      T                : Duration;
      Tangent_Angle    : Float;
   end record;

   type Second_Tics is new Natural;

   type Flight_Path_Data is
     array (Second_Tics range <>) of Flight_Path_Record;

   function Generate_Flight_Path
     (Proj_Type                            : in Integer;
      Launch_Time, Gun_Az, Gun_Qe, Proj_Mv : in Float;
      Gun_Lat, Gun_Long, Gun_Hgt           : in Float;
      Total_Time                           : in Second_Tics := 150)
      return                                 Flight_Path_Data;

   function Get_Data
     (Fp   : in Flight_Path_Data;
      Time : in Duration)
      return Flight_Path_Record;

private
   -- Underlying functions

   procedure Initialize
     (Proj_Type                                                        : in
     Integer;
      Launch_Time, Gun_Az, Gun_Qe, Proj_Mv, Gun_Lat, Gun_Long, Gun_Hgt : in
     Float);

   procedure Update (Run_Until : in Duration);

   procedure Get
     (Time             : in Duration;
      X, Y, Z, U, V, W : out Float;
      T                : out Duration);

end Pbm.Bfpath;
