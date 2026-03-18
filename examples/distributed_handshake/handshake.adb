with Pace.Log;
with Pace.Socket;

package body Handshake is

   -- 1. Responder (Node 2) receives Propose from Node 1
   procedure Input (Obj : in Propose) is
      V : Validate;
   begin
      Pace.Log.Put_Line ("Responder: Received Propose (Id =" & Integer'Image(Obj.Request_Id) & ")");
      V.Request_Id := Obj.Request_Id;
      Pace.Log.Put_Line ("Responder: Sending Validate to Verifier...");
      Pace.Socket.Send (V, Ack => True);
   end Input;

   -- 2. Verifier (Node 3) receives Validate from Node 2
   procedure Input (Obj : in Validate) is
      C : Confirm;
   begin
      Pace.Log.Put_Line ("Verifier: Received Validate (Id =" & Integer'Image(Obj.Request_Id) & ")");
      C.Request_Id := Obj.Request_Id;
      Pace.Log.Put_Line ("Verifier: Sending Confirm to Initiator...");
      Pace.Socket.Send (C, Ack => True);
   end Input;

   -- 3. Initiator (Node 1) receives Confirm from Node 3
   procedure Input (Obj : in Confirm) is
   begin
      Pace.Log.Put_Line ("Initiator: Received Confirm (Id =" & Integer'Image(Obj.Request_Id) & ")");
      Pace.Log.Put_Line ("Initiator: Handshake complete for Id =" & Integer'Image(Obj.Request_Id));
   end Input;

end Handshake;
