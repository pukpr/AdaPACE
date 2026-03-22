package PBM.Trajectory is

   type Object is record
      Easting, Northing : Long_Float;
      Altitude          : Long_Float;
      Heading           : Long_Float;
      Elevation         : Long_Float;
      Speed             : Long_Float;
      Time              : Duration;
      Delta_T           : Duration   := 0.01;
      Air_Drag          : Long_Float := 0.0;  -- 0.5 rho C A / m
      Coriolis_Drag     : Long_Float := 0.0;  -- ~ omega
   end record;

   type Terrain_Intersection is access function
     (Easting, Northing, Altitude : Long_Float;
      Falling : Boolean)
   return                           Boolean;

   procedure Calculate_Location
     (Target    : in out Object;
      Time      : in Duration;  -- seconds from initial starting
      Isection  : in Terrain_Intersection;
      Easting   : out Long_Float;  -- absolute
      Northing  : out Long_Float;  -- absolute
      Altitude  : out Long_Float;
      Speed     : out Long_Float;
      Landed    : out Boolean;
      Descent_Angle : out Long_Float); -- descent angle in radians


   procedure Calculate_Launch_Angle 
     (Theta           : out Long_Float;
      Actual_Distance : out Long_Float;
      Cycles          : out Integer;
      Radial_Distance : in Long_Float;
      Altitude_Change : in Long_Float;
      Initial_Speed   : in Long_Float;
      Low_El, High_El : in Long_Float;
      Air_Drag        : in Long_Float := 0.0;
      Delta_Time      : in Duration := 0.01;
      High_Quadrant   : in Boolean    := True;
      Accuracy_EPS    : in Long_Float := 0.1);

end Pbm.Trajectory;
