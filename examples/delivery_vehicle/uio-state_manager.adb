with Pace.Log;
with Uio.State;
use Uio.State;
with Uio.State.Sustain;
with Uio.State.Move;
with Uio.State.Deliver;
with Pace.Strings; use Pace.Strings;

package body Uio.State_Manager is
   function Id is new Pace.Log.Unit_Id;

--    function Get_Vehicle_State return Uio.State.Vehicle_State_Enum;

   State : Uio.State.Vehicle_State_Enum := Move_State;

   function Get_Vehicle_State return Uio.State.Vehicle_State_Enum is
   begin
      return State;
   end Get_Vehicle_State;

   procedure Set_Initial_State_For_Non_Active_States is
   begin
      -- Set all other states to initial state
      -- I sure wish that I could use the magical
      -- OO technique known as polymorphism.
      for I in Uio.State.Vehicle_State_Enum loop
         if I /= State then
            case I is
               when Move_State =>
                  Uio.State.Move.Set_Initial_State;
               when Deliver_State =>
                  Uio.State.Deliver.Set_Initial_State;
               when Sustain_State =>
                  Uio.State.Sustain.Set_Initial_State;
               when Undefined_State =>
                  null;
               when others =>
                  Pace.Log.Put_Line ("WARNING: unhandled state " &
                               Uio.State.Vehicle_State_Enum'Image (I));
            end case;
         end if;
      end loop;
   end Set_Initial_State_For_Non_Active_States;

   task Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      Pace.Log.Put_Line ("Started State_Manager task");
      loop
         declare
            Msg : Uio.State.Vehicle_State;
         begin
            Inout (Msg);
            State := Msg.State;
            Pace.Log.Put_Line ("Vehicle State set to " &
                               Uio.State.Vehicle_State_Enum'Image (State));
         end;
         Set_Initial_State_For_Non_Active_States;
      end loop;
   exception
      when Event: others =>
         Pace.Log.Ex (Event);
   end Agent;

   procedure Inout (Obj : in out Get_State) is
      use Pace.Server.Dispatch;
   begin
      Obj.Set := S2u("<state>" &
                   Uio.State.Vehicle_State_Enum'Image (Get_Vehicle_State) &
                   "</state>");
      Pace.Server.Put_Data (U2s(Obj.Set));
      Pace.Log.Trace (Obj);
   end Inout;

   use Pace.Server.Dispatch;
begin
   Save_Action (Get_State'(Pace.Msg with Default));

end Uio.State_Manager;
