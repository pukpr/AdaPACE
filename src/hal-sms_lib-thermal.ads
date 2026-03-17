with Pace;
with Hal.Sms;

package Hal.Sms_Lib.Thermal is

   pragma Elaborate_Body;

   type Element is
      record
         Position : Float; -- Needed?
         Temperature : Float;
      end record;

   type Element_Profile is array (Positive range <>) of Element;


   procedure Set (Assembly : String;
                  Elements : Element_Profile);


private

   type Assembly_Profile (Array_Size : Positive) is new Pace.Msg with
      record
         Assembly : Hal.Sms.Name;
         Profile : Element_Profile (1..Array_Size);
      end record;
   procedure Input (Obj : in Assembly_Profile);


end Hal.Sms_Lib.Thermal;
