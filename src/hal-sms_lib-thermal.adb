with Pace.Log;
with Pace.Socket;
with Hal.Sms;

-- the dummy file.. the real one is in $PACE/plugins/dvs
package body Hal.Sms_Lib.Thermal is

   procedure Set (Assembly : String;
                  Elements : Element_Profile) is
      Msg : Assembly_Profile (Elements'Length);
   begin
      Msg.Assembly := Hal.Sms.To_Name (Assembly);
      Msg.Profile := Elements;
      Pace.Socket.Send (Msg);
   end Set;


   -- dummy methods

   procedure Input (Obj : in Assembly_Profile) is
   begin
      null;
   end Input;

end Hal.Sms_Lib.Thermal;
