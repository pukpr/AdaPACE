with Ada.Strings.Unbounded;

package body Pace.Server.Peek_Factory is

   pragma Suppress (Elaboration_Check);

   use Ada.Strings.Unbounded;

   procedure Inout (Obj : in out Peek) is
   begin
      Obj.Set := To_Unbounded_String (Assign);
      Pace.Server.Put_Data (To_String (Obj.Set));
   end Inout;

   use Pace.Server.Dispatch;
begin
   Save_Action (Peek'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   -- $ID: pace-server-peek_factory.adb,v 1.1 12/08/2003 14:40:10 pukitepa Exp $
end Pace.Server.Peek_Factory;


