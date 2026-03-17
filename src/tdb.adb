
package body TDB is -- Terrain Dat Base

   procedure Init (tdb, adb : in String) is
   begin
      null;
   end Init;
   
   procedure get_Extents (coord_system : in String;
                          x_min, x_max, y_min, y_max : out Long_Float) is
      pragma Unreferenced (x_min, x_max, y_min, y_max);
   begin
      null;
   end get_Extents;
       

   function get_Height(x, y : Long_Float) return Long_Float is
   begin
      return 0.0;
   end get_Height;

   function get_Pitch(x, y, Az : Long_Float) return Long_Float is
   begin
      return 0.0;
   end get_Pitch;

   function get_Roll(x, y, Az : Long_Float) return Long_Float is
   begin
      return 0.0;
   end get_Roll;

begin

   Init ("", "");
   
end;
