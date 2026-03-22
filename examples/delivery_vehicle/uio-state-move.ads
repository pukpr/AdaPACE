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

end Uio.State.Move;
