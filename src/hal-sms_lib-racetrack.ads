with Pace;
with Hal.Bounded_Assembly;

package Hal.Sms_Lib.Racetrack is

   pragma Elaborate_Body;

   -- X is the short axis, Z the long axis, and Phi the rotating axis
   type Slot_Position is
      record
         Phi, X, Z : Float;
      end record;

   type Slots_Array is array (Integer range <>) of Slot_Position;


   subtype Direction is Hal.Rotation_Direction;

   use Bounded_Assembly;

   procedure Set (Prefix : Bounded_String; Slots : Slots_Array);

private

   type Move_Slots (Num_Slots : Integer) is new Pace.Msg with
      record
         Assembly_Prefix : Bounded_String;
         Slots : Slots_Array (1 .. Num_Slots);
      end record;
   procedure Input (Obj : in Move_Slots);

end Hal.Sms_Lib.Racetrack;
