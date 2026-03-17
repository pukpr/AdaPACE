   -- with CTDB_World;
package Hal.CTDB is

   --   pragma Elaborate_Body;

   --
   -- Compact Terrain Database interface
   --

   Database_Read_Error : exception;
   Database_Range_Error : exception;

   procedure Read (Name : in String; Integrity_Check : in Boolean := False); -- Non-world
   procedure Read; -- "World" version

   type Rotation_Matrix is array (1 .. 3, 1 .. 3) of Long_Float;



   --
   --  Placing Vehicle
   --
   procedure Place_Vehicle  -- Old version assuming single cell
     (X, Y, Length, Width, Heading : in Long_Float;
      Z                            : out Long_Float;
      Pitch, Roll                  : out Float;
      Rotation                     : out Rotation_Matrix;
      Soil                         : out Integer);

   procedure Place_Vehicle  -- Old version assuming single cell
     (X, Y, Length, Width, Heading : in Long_Float;
      Z                            : out Long_Float;
      Pitch, Roll                  : out Float;
      Rotation                     : out Rotation_Matrix;
      Water                        : out Boolean;
      No_Go                        : out Boolean;
      Slow_Go                      : out Boolean;
      Road                         : out Boolean);

   -- Latitude, Longitude variant
   procedure Place_Vehicle  -- New "World" version
     (Zone                         : in Integer;  -- Check Zone sign for hemisphere
      E, N, Length, Width, Heading : in Long_Float;
      Latitude, Longitude          : out Long_Float;
      Z                            : out Long_Float;
      Pitch, Roll                  : out Long_Float;
      Rotation                     : out Rotation_Matrix;
      Water                        : out Boolean;
      No_Go                        : out Boolean;
      Slow_Go                      : out Boolean;
      Road                         : out Boolean);

   procedure UTM
     (  -- Returns lower left of data using old terrain access
      Source, Datum, Zone_Number : out Integer;
      Zone_Letter                : out Character;
      Northing, Easting          : out Long_Float);

   procedure UTM
     (  -- Returns lower left of data using new "World" terrain access
      Zone                       : in Integer;    -- Requires an input starting UTM to get it on a terrain cell
      Northing, Easting          : in Long_Float; -- Pick a general cell location
      Zone_Number                : out Integer;
      Min_Northing, Min_Easting  : out Long_Float);


   procedure Geographic_Extent 
     ( -- Returns Latitude and Longitude using old terrain access
      South, West, North, East   : out Long_Float);

   procedure Geographic_Extent 
     ( -- Returns Latitude and Longitude using new "World" terrain access
      Zone                     : in Integer;      -- Requires an input starting UTM to get it on a terrain cell
      Northing, Easting        : in Long_Float;   -- Pick a general cell location
      South, West, North, East : out Long_Float); -- in Latitude and Longitude

--     type Hit is (
--        HIT_NOTHING,
--        HIT_TREELINE,
--        HIT_BUILDING,
--        HIT_GROUND,
--        HIT_VEHICLE,
--        HIT_WATER,
--        HIT_TREE);

   -- Two variants for Ground Intersection
   CTDB_HIT_NOTHING  : constant Integer := 16#00#;
   CTDB_HIT_TREELINE : constant Integer := 16#01#;
   CTDB_HIT_BUILDING : constant Integer := 16#02#;
   CTDB_HIT_GROUND   : constant Integer := 16#04#;
   CTDB_HIT_VEHICLE  : constant Integer := 16#08#;
   CTDB_HIT_WATER    : constant Integer := 16#10#;
   CTDB_HIT_TREE     : constant Integer := 16#20#;

   subtype Hit_Descriptor is String(1..10);
   Hit : array (CTDB_HIT_NOTHING..CTDB_HIT_TREE) of Hit_Descriptor :=
     (others => "??????????");

   procedure find_ground_intersection  -- Old terrain access
     (X0, Y0, Z0, X1, Y1, Z1 : in Long_Float;
      X, Y, Z                : out Long_Float;
      Result                 : out Integer;
      Qual                   : in Integer := 0);

   type VEHICLE_LOCATION is record
      Used          : Integer;
      X, Y, Z       : Long_Float;
      Width, Height : Long_Float;
   end record;
   type Vehicle_Location_Array is
     array (Positive range <>) of VEHICLE_LOCATION;

   procedure find_ground_intersection  -- Old terrain access
     ( -- Variation allows vehicle isect
      X0, Y0, Z0, X1, Y1, Z1 : in Long_Float;
      Vehicles               : in Vehicle_Location_Array;
      Hit_Vehicle            : out Positive;
      X, Y, Z                : out Long_Float;
      Result                 : out Integer;
      Qual                   : in Integer := 0);

   -- $id$

end Hal.CTDB;
