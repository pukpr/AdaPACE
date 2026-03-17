with Pace;

package Hal.Sms_Lib.Dads_Firing is

   type Rotate_Gun is new Pace.Msg with
      record
         Start, Final : Orientation;
      end record;
   procedure Input (Obj : Rotate_Gun);

private

   pragma Inline (Input);

end Hal.Sms_Lib.Dads_Firing;
