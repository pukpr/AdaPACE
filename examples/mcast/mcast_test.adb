with pace.log;
with Pace.Multicast;
package body Mcast_Test is
   use Pace.Multicast;

   -- Message Declaration
       
   type Message is new pace.msg with
      record
        N : integer;
      end record;
   procedure Input (Obj : in Message);

   -- Receives the messages

   Recv : Receiver := Create ("224.13.194.161:4161");

   procedure Input (Obj : in Message) is
   begin
      pace.log.put_line ("received: " & Obj.N'img);
   end;

   -- Sends the messages

   Xmit : Sender   := Create ("224.13.194.161:4161");

   procedure Run is
      M : Message;
   begin
      pace.log.put_line ("this goes on forever");
      for i in natural'range loop
         delay 3.0;
         M.N := i;
         Send (Xmit, M);
         pace.log.put_line ("sent");
      end loop;
   end;

end;

