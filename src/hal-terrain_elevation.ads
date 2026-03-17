with Interfaces;
with Sequential_IO;

package Hal.Terrain_Elevation is

   -- pragma Pure;

   -------------------------------------------------------
   --   Standard terrain elevation formats
   -------------------------------------------------------
   -- DEM (Digital Elevation Model)
   -- DTED (Digital Terrain Elevation Matrix)

   Minimum : constant := -600;  -- DEM 1-deg terrain data
   Maximum : constant := 600;

   subtype Grid_Range is Integer range Minimum .. Maximum;

   package Dem_Data is  -- preprocessed binary DEM data
      type Grid is array (Grid_Range, Grid_Range) of Integer;
      -- Post data of elevations in meters

      type Grid_Record is
         record
            Lo, Hi : Float; -- Low/High elevation
            Dem : Grid;
         end record;
   end Dem_Data;


   generic
      Level : in Integer := 2; -- 1199; -- Level 1
   package Dted_Data is
      Minimum : constant Integer := 0;
      Maximum : constant Integer := 1200 + (Level-1)*2400;
      subtype Grid_Range_L1 is Integer range Minimum .. Maximum;
      
      subtype Byte is Interfaces.Integer_8;
      type Byte_Array is array (Integer range <>) of Byte;
      pragma Convention (C, Byte_Array); --APEX

      subtype Elev is Interfaces.Integer_16;
      type Elev_Array is array (Grid_Range_L1) of Elev;
      pragma Convention (C, Elev_Array);

      type Elev_Record is
         record
            A, B, C, D : Interfaces.Integer_16;
            Post_Data : Elev_Array;
            E, F : Interfaces.Integer_16;
         end record;
      pragma Convention (C, Elev_Record);

      type Elev_Set is array (Grid_Range_L1) of Elev_Record;
      pragma Convention (C, Elev_Set);

      type Data_Set is
         record
            User_Header_Label : Byte_Array (1 .. 80);
            Data_Set_Identification_Record : Byte_Array (1 .. 648);
            Accuracy_Record : Byte_Array (1 .. 2700);
            Data_Records : Elev_Set;
         end record;
      pragma Convention (C, Data_Set);

      type Grid_Access is access Data_Set;
      The_Grid : Grid_Access;

      package Io is new Sequential_IO (Data_Set);

   end Dted_Data;

------------------------------------------------------------------------------
-- $id: hal-terrain_elevation.ads,v 1.2 05/12/2003 22:10:10 pukitepa Exp $
------------------------------------------------------------------------------
end Hal.Terrain_Elevation;

