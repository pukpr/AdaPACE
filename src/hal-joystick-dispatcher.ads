with Pace.Notify;

package Hal.Joystick.Dispatcher is

   -- operates in the client executable
   -- simply sends all data incoming from device out as a notify message

   pragma Elaborate_Body;

   -- the joystick executable dispatches on this
   type Device_Update is new Pace.Msg with
      record
         Joy_Id : Integer;
         Data : Joy_Data;
      end record;
   procedure Input (Obj : in Device_Update);
   
   -- The code that uses the data waits on this notify
   type Data_Update is new Pace.Notify.Subscription with
      record
         Joy_Id : Integer;
         Data : Joy_Data;
      end record;

end Hal.Joystick.Dispatcher;
