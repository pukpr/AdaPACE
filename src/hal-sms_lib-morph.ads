with Pace;
with Ada.Strings.Bounded;
with Hal.Bounded_Assembly;

package Hal.Sms_Lib.Morph is

   pragma Elaborate_Body;

   type Pin_Array is array (Integer range <>) of Float;

   type Pin_Pos_Array is array (Integer range <>) of Position;

   use Hal.Bounded_Assembly;

   procedure Set (Prefix : Bounded_String;
                  Pins : Pin_Array;
                  Pin_Positions : Pin_Pos_Array);

private

   type Move_Pins (Array_Size : Integer) is new Pace.Msg with
      record
         Assembly_Prefix : Bounded_String;
         -- angles in Pins are in radians
         Pins : Pin_Array (1 .. Array_Size);
         Positions : Pin_Pos_Array (1 .. Array_Size);
      end record;
   procedure Input (Obj : in Move_Pins);

end Hal.Sms_Lib.Morph;
