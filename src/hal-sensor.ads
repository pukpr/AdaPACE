with Pace;

package Hal.Sensor is

   pragma Elaborate_Body;

   type Target_Pos is record
      Id : Integer;
      X  : Float;
      Y  : Float;
      Z  : Float;
   end record;

   type Coord_Array is array (Integer range <>) of Target_Pos;

   type Get is new Pace.Msg with record
      Num_Targets : Integer := 0;
      Coords      : Coord_Array (1 .. 32);
   end record;
   procedure Output (Obj : out Get);

   type Lase is new Pace.Msg with record
      Target_Id : Integer;
      Success   : Boolean;
   end record;
   procedure Inout (Obj : in out Lase);

end Hal.Sensor;
