package TDB is -- Terrain Data Base

   procedure get_Extents (coord_system : in String;
                          x_min, x_max, y_min, y_max : out Long_Float);
       
   function get_Height(x, y : Long_Float) return Long_Float;

   function get_Pitch(x, y, Az : Long_Float) return Long_Float;

   function get_Roll(x, y, Az : Long_Float) return Long_Float;

private

   procedure Init (tdb,                -- terrain
                   adb : in String);   -- aspects?
   -- this part should go in the elaboration   

end TDB;
