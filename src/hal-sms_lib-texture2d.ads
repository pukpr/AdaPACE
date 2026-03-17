with Pace;
with Hal.Sms;

package Hal.Sms_Lib.Texture2d is

   pragma Elaborate_Body;

   type Element is
      record
         X, Y : Float; -- Needed ?
         Value : Float;
      end record;

   type Element_Profile is array (Positive range <>,
                                  Positive range <>) of Element;

   procedure Set (Assembly : String;
                  Elements : Element_Profile;
                  Upper_Limit, Lower_Limit : Float);

private

   type Assembly_Profile (Array_Size : Positive) is new Pace.Msg with
      record
         Assembly : Hal.Sms.Name;
         Upper_Limit, Lower_Limit : Float;
         Profile : Element_Profile (1..Array_Size, 1..Array_Size);
      end record;
   procedure Input (Obj : in Assembly_Profile);

end Hal.Sms_Lib.Texture2d;
