with Pace.Log;
with Pace.Socket;
with Text_IO;
with Hal.Sms;

-- the dummy file.. the real one is in $PACE/plugins/dvs
package body Hal.Sms_Lib.Texture2d is

   procedure Set
     (Assembly                 : String;
      Elements                 : Element_Profile;
      Upper_Limit, Lower_Limit : Float)
   is
      Msg : Assembly_Profile (Elements'Length (1));
   begin
      Msg.Assembly    := Hal.Sms.To_Name (Assembly);
      Msg.Profile     := Elements;
      Msg.Upper_Limit := Upper_Limit;
      Msg.Lower_Limit := Lower_Limit;
      Pace.Socket.Send (Msg);
   end Set;

   -- dummy methods

   procedure Input (Obj : in Assembly_Profile) is
   begin
      for X in  Obj.Profile'Range (1) loop
         for Y in  Obj.Profile'Range (2) loop
            Text_IO.Put (Obj.Profile (X, Y).Value'Img);
         end loop;
      end loop;
      Text_IO.New_Line;
   end Input;

end Hal.Sms_Lib.Texture2d;
