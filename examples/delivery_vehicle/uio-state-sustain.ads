with Pace.Server.Dispatch;

package Uio.State.Sustain is

   pragma Elaborate_Body;

   type State_Enum is (Initial, Emplaced, Sustaining);

   procedure Set_Initial_State;

   type Next_State is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Next_State);

   type State is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out State);

private
   pragma Inline (Inout);
   pragma Inline (Set_Initial_State);

-- $Id: uio-state-sustain.ads,v 1.7 2005/02/17 15:51:21 ludwiglj Exp $ --
end Uio.State.Sustain;
