with Ada.Strings.Fixed;
with Pace.Log;
with Hal.Sms;
with System;

package body Hal.Sms_Lib.Morph is

   Dummy : Hal.Sms.Name := Hal.Sms.To_Name ("dummy");

   -- dummy method..
   procedure Set (Prefix : Bounded_String; Pins : Pin_Array; Pin_Positions : Pin_Pos_Array) is
   begin
      null;
   end Set;

   procedure Input (Obj : in Move_Pins) is
      use Hal.Sms.Proxy;
      use Ada.Strings;
      Prefix : String := To_String (Obj.Assembly_Prefix);
      Data : Dvs_Record;
   begin
      for I in Obj.Pins'Range loop
         Data := (Msg_Type => Coord_Const,
                  Assembly => Hal.Sms.To_Name (Prefix & Ada.Strings.Fixed.Trim (Integer'Image(I), Left)),
                  Event => Dummy,
                  Pos => Obj.Positions (I),
                  Rot => (Obj.Pins (I), 0.0, 0.0),
                  Entity => Hal.Sms.Blank,
                  Assembly_Ptr => System.Null_Address);
         Hal.Sms.Proxy.Put (Data);
      end loop;
      Pace.Log.Trace (Obj);
   end Input;

end Hal.Sms_Lib.Morph;
