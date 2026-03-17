with Pace.Server.Dispatch;

generic
   with function Assign return String;
package Pace.Server.Peek_Factory is
   -- Convenient way to instantiate action requests that "peek" on values
private
   type Peek is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Peek);
   -- $ID: pace-server-peek_factory.ads,v 1.1 12/08/2003 14:40:12 pukitepa Exp $
end Pace.Server.Peek_Factory;
