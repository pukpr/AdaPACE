with Pace.Notify;

package Uio.State is
   Null_Tag : constant String := "<null></null>";

   type Vehicle_State_Enum is (Undefined_State, Move_State,
                               Deliver_State, Sustain_State);

   type Vehicle_State is new Pace.Notify.Subscription with
      record
         State : Vehicle_State_Enum := Undefined_State;
      end record;

   -- $Id: uio-state.ads,v 1.8 2004/09/20 22:18:15 pukitepa Exp $
end Uio.State;
