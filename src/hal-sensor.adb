with Pace.Log;

package body Hal.Sensor is

   procedure Output (Obj : out Get) is
   begin
      Obj.Num_Targets := 0;
   end Output;

   procedure Inout (Obj : in out Lase) is
   begin
      Obj.Success := True;
   end Inout;

end Hal.Sensor;
