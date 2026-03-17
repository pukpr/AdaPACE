with Pace.Server.Dispatch;
with Ada.Strings.Unbounded;

package Hla.Tx is
   pragma Elaborate_Body;

   type Tuple_List is array (Natural range <>) of Tuple;

   type Interaction (Length : Natural) is new Pace.Msg with
      record
         Name : Ada.Strings.Unbounded.Unbounded_String;
         Values : Tuple_List (1 .. Length);
         Update : Boolean := False; -- True for Interactions
         Handle : Gateway := Null_Gateway;
         -- Instance_Name : Ada.Strings.Unbounded.Unbounded_String;
      end record;
   procedure Input (Obj : in Interaction);

   -- An Entity State message looks just like an Interaction
   -- except for the fact that it is semantically an update.
   -- Thus, derive from Interaction above and set Update=TRUE
   type Entity_State (Length : Natural) is new Interaction (Length) with
      null record;
   procedure Input (Obj : in Entity_State);

   type Init_Outgoing is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Init_Outgoing);

   -- $Id: hla-tx.ads,v 1.10 2004/09/22 18:30:35 pukitepa Exp $
end Hla.Tx;
