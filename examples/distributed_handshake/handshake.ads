with Pace;

package Handshake is
   pragma Elaborate_Body;

   -- Handshake states
   type Handshake_Phase is (Proposed, Validated, Confirmed);

   -- 1. Initiator (Node 1) -> Responder (Node 2)
   type Propose is new Pace.Msg with record
      Request_Id : Integer;
   end record;
   procedure Input (Obj : in Propose);

   -- 2. Responder (Node 2) -> Verifier (Node 3)
   type Validate is new Pace.Msg with record
      Request_Id : Integer;
   end record;
   procedure Input (Obj : in Validate);

   -- 3. Verifier (Node 3) -> Initiator (Node 1)
   type Confirm is new Pace.Msg with record
      Request_Id : Integer;
   end record;
   procedure Input (Obj : in Confirm);

end Handshake;
