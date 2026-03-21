with Pace.Server.Dispatch;

package Uio.State.Deliver is

   pragma Elaborate_Body;

   type State_Enum is (Initial, Acknowledged, Emplaced,
                       Enabled, Delivering, Items_Complete);

   procedure Set_Initial_State;

   type Get_Current_State is new Pace.Msg with
      record
         Current_State : State_Enum;
      end record;
   procedure Output (Obj : out Get_Current_State);

   type Next_State is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Next_State);

   type State is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out State);

private
   pragma Inline (Inout);
   pragma Inline (Set_Initial_State);

-- $Id: uio-state-deliver.ads,v 1.5 2003/05/22 20:46:00 ludwiglj Exp $ --
end Uio.State.Deliver;
