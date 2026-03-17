package body Hal.CTDB is

   procedure Read (Name : in String; Integrity_Check : in Boolean := False) is
   begin
      null;
   end Read;

   procedure Read is
   begin
      null;
   end Read;

   procedure Place_Vehicle
     (X, Y, Length, Width, Heading : in Long_Float;
      Z                            : out Long_Float;
      Pitch, Roll                  : out Float;
      Rotation                     : out Rotation_Matrix;
      Soil                         : out Integer) is
   begin
      Z := 0.0;
      Pitch := 0.0;
      Roll := 0.0;
      Rotation := (others => (others => 0.0));
      Soil := 0;
   end Place_Vehicle;

   procedure Place_Vehicle
     (X, Y, Length, Width, Heading : in Long_Float;
      Z                            : out Long_Float;
      Pitch, Roll                  : out Float;
      Rotation                     : out Rotation_Matrix;
      Water                        : out Boolean;
      No_Go                        : out Boolean;
      Slow_Go                      : out Boolean;
      Road                         : out Boolean) is
   begin
      Z := 0.0;
      Pitch := 0.0;
      Roll := 0.0;
      Rotation := (others => (others => 0.0));
      Water := False;
      No_Go := False;
      Slow_Go := False;
      Road := False;
   end Place_Vehicle;

   procedure Place_Vehicle
     (Zone                         : in Integer;
      E, N, Length, Width, Heading : in Long_Float;
      Latitude, Longitude          : out Long_Float;
      Z                            : out Long_Float;
      Pitch, Roll                  : out Long_Float;
      Rotation                     : out Rotation_Matrix;
      Water                        : out Boolean;
      No_Go                        : out Boolean;
      Slow_Go                      : out Boolean;
      Road                         : out Boolean) is
   begin
      Latitude := 0.0;
      Longitude := 0.0;
      Z := 0.0;
      Pitch := 0.0;
      Roll := 0.0;
      Rotation := (others => (others => 0.0));
      Water := False;
      No_Go := False;
      Slow_Go := False;
      Road := False;
   end Place_Vehicle;

   procedure UTM
     (Source, Datum, Zone_Number : out Integer;
      Zone_Letter                : out Character;
      Northing, Easting          : out Long_Float) is
   begin
      Source := 0;
      Datum := 0;
      Zone_Number := 0;
      Zone_Letter := ' ';
      Northing := 0.0;
      Easting := 0.0;
   end UTM;

   procedure UTM
     (Zone                       : in Integer;
      Northing, Easting          : in Long_Float;
      Zone_Number                : out Integer;
      Min_Northing, Min_Easting  : out Long_Float) is
   begin
      Zone_Number := 0;
      Min_Northing := 0.0;
      Min_Easting := 0.0;
   end UTM;

   procedure Geographic_Extent
     (South, West, North, East   : out Long_Float) is
   begin
      South := 0.0;
      West := 0.0;
      North := 0.0;
      East := 0.0;
   end Geographic_Extent;

   procedure Geographic_Extent
     (Zone                     : in Integer;
      Northing, Easting        : in Long_Float;
      South, West, North, East : out Long_Float) is
   begin
      South := 0.0;
      West := 0.0;
      North := 0.0;
      East := 0.0;
   end Geographic_Extent;

   procedure find_ground_intersection
     (X0, Y0, Z0, X1, Y1, Z1 : in Long_Float;
      X, Y, Z                : out Long_Float;
      Result                 : out Integer;
      Qual                   : in Integer := 0) is
   begin
      X := 0.0;
      Y := 0.0;
      Z := 0.0;
      Result := CTDB_HIT_NOTHING;
   end find_ground_intersection;

   procedure find_ground_intersection
     (X0, Y0, Z0, X1, Y1, Z1 : in Long_Float;
      Vehicles               : in Vehicle_Location_Array;
      Hit_Vehicle            : out Positive;
      X, Y, Z                : out Long_Float;
      Result                 : out Integer;
      Qual                   : in Integer := 0) is
   begin
      Hit_Vehicle := 1;
      X := 0.0;
      Y := 0.0;
      Z := 0.0;
      Result := CTDB_HIT_NOTHING;
   end find_ground_intersection;

end Hal.CTDB;
