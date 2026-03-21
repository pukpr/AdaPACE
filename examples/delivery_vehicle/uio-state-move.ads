with Pace.Server.Dispatch;

package Uio.State.Move is

   pragma Elaborate_Body;

   type State_Enum is (Initial, Displacing, Moving);

   procedure Set_Initial_State;

   type Next_State is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Next_State);

   type State is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out State);


private
   pragma Inline (Inout);
   pragma Inline (Set_Initial_State);

-- $Id: uio-state-move.ads,v 1.3 2003/03/31 13:55:25 pukitepa Exp $ --
end Uio.State.Move;
