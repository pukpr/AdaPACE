
with Pace.Server.Dispatch;

package Uio.State_Manager is
   pragma Elaborate_Body;

   type Get_State is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_State);

private
   pragma Inline (Inout);

   -- $Id: uio-state_manager.ads,v 1.5 2004/09/20 22:18:15 pukitepa Exp $ --
end Uio.State_Manager;
