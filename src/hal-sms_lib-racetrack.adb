with Pace.Log;
with Ada.Strings.Fixed;
with Hal.Sms;
with System;

package body Hal.Sms_Lib.Racetrack is


   Dummy_Event_Name : Hal.Sms.Name := Hal.Sms.To_Name ("dummy");

   -- dummy method...
   procedure Set (Prefix : Bounded_String; Slots : Slots_Array) is
   begin
      null;
   end Set;

   -- consider making this package more flexible.. too flexible could be too
   -- complicated.. too specific won't be useful.  ?? is it okay to assume
   -- the axes will be X, Z, and B (for rotating)? is it okay to assume
   -- that the other values will be 0.0? and how complicated would it be
   -- to have the user specify the axes and the other values?
   procedure Input (Obj : in Move_Slots) is
      use Hal.Sms.Proxy;
      use Ada.Strings;
      Data : Dvs_Record;
      Prefix : String := To_String (Obj.Assembly_Prefix);
   begin
      for Id in Obj.Slots'Range loop
         Data := (Msg_Type => Coord_Const,
                  Assembly => Hal.Sms.To_Name (Prefix & Ada.Strings.Fixed.Trim
                                               (Integer'Image (Id), Left)),
                  Event => Dummy_Event_Name,
                  Pos => (Obj.Slots (Id).X, 0.0, Obj.Slots (Id).Z),
                  Rot => (0.0, Obj.Slots (Id).Phi, 0.0),
                  Entity => Hal.Sms.Blank,
                  Assembly_Ptr => System.Null_Address);
         Hal.Sms.Proxy.Put (Data);
      end loop;
      Pace.Log.Trace (Obj);
   end Input;


end Hal.Sms_Lib.Racetrack;
