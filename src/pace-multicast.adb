with Pace.Log;
with Pace.TCP.Connectionless;

package body Pace.Multicast is

   Windows : constant String := "Windows_NT";
   
   OS : constant String := Pace.Getenv ("OS", "");

   -----------------------------
   -- Create_Multicast_Socket --
   -----------------------------
   function Create_Multicast_Socket
               (Group : String;
                Port : Positive;
                Ttl : Positive := 16;
                Self_Loop : Boolean := True) return Multicast_Socket_Type is
      S : GNAT.Sockets.Socket_Type;
      Result : Multicast_Socket_Type;
   begin
      Pace.Display ("CREATING multicast group: " & Group);
      GNAT.Sockets.Create_Socket (S, GNAT.Sockets.Family_Inet, GNAT.Sockets.Socket_Datagram);

      Result.Target.Addr := GNAT.Sockets.Any_Inet_Addr;
      Result.Target.Port := GNAT.Sockets.Port_Type (Port);

      if OS = Windows then
         GNAT.Sockets.Bind_Socket (S, Result.Target);
      end if;

      GNAT.Sockets.Set_Socket_Option
         (S,
          GNAT.Sockets.Socket_Level,
          (GNAT.Sockets.Reuse_Address, True));

      begin
         GNAT.Sockets.Set_Socket_Option
            (S,
             GNAT.Sockets.IP_Protocol_For_IP_Level,
             (GNAT.Sockets.Add_Membership,
              GNAT.Sockets.Inet_Addr (Group),
              GNAT.Sockets.Any_Inet_Addr));
      exception
         when E : others =>
            Pace.Log.Put_line ("WARNING: multicast add membership failed");
            raise;
      end;
         
      begin
         GNAT.Sockets.Set_Socket_Option
            (S,
             GNAT.Sockets.IP_Protocol_For_IP_Level,
             (GNAT.Sockets.Multicast_TTL, Ttl)); -- 1?
      exception
         when E : others =>
            Pace.Log.Put_line ("WARNING: multicast TTL failed");
      end;

      begin
         GNAT.Sockets.Set_Socket_Option
            (S,
             GNAT.Sockets.IP_Protocol_For_IP_Level,
             (GNAT.Sockets.Multicast_Loop, True)); -- False for PC?
      exception
         when E : others =>
            Pace.Log.Put_line ("WARNING: multicast loop failed");
      end;

      if OS /= Windows then
         GNAT.Sockets.Bind_Socket (S, Result.Target);
      end if;

--       Result.Target.Addr := GNAT.Sockets.Any_Inet_Addr;
--       Result.Target.Port := GNAT.Sockets.Port_Type (Port);
-- 
--       GNAT.Sockets.Bind_Socket (S, Result.Target);

      Result.Fd := S;
      Result.Target.Addr := GNAT.Sockets.Inet_Addr (Group);
      Result.Target.Port := GNAT.Sockets.Port_Type (Port);

      return Result;
   exception
      when E : others =>
         Pace.Log.Ex(E, Group & " didn't work for mcast on " & 
                        Pace.Image & ", defaulting to unicast!");

         GNAT.Sockets.Bind_Socket (S, Result.Target);

         Result.Fd := S;
         Result.Target.Addr := GNAT.Sockets.Inet_Addr (Group);
         Result.Target.Port := GNAT.Sockets.Port_Type (Port);
         return Result;

   end Create_Multicast_Socket;


--    procedure Send (Socket : in Multicast_Socket_Type;
--                    Data : in Ada.Streams.Stream_Element_Array) is
--       Last : Ada.Streams.Stream_Element_Offset;
--    begin
--       GNAT.Sockets.Send_Socket (Socket.Fd, Data, Last, Socket.Target);
--    end Send;

   procedure Send (Socket : in Multicast_Socket_Type;
                   Data : in Pace.Stream.Data_Access) is
   begin
      -- Pace.Log.Put_Line ("TXing");
      Pace.TCP.Connectionless.Stream_Send (Socket.Target, GNAT.Sockets.To_C(Socket.Fd), Data);
   end Send;

--    procedure Receive (Socket : in Multicast_Socket_Type;
--                       Data : out Ada.Streams.Stream_Element_Array) is
--       Target : GNAT.Sockets.Sock_Addr_Type;
--       Last : Ada.Streams.Stream_Element_Offset;
--    begin
--       GNAT.Sockets.Receive_Socket (Socket.Fd, Data, Last, Target);
--    end Receive;

   procedure Receive (Socket : in Multicast_Socket_Type;
                      Data : in Pace.Stream.Data_Access) is
      Target : GNAT.Sockets.Sock_Addr_Type;
   begin
      -- Pace.Log.Put_Line ("RXing");
      Pace.TCP.Connectionless.Stream_Receive (Target, GNAT.Sockets.To_C(Socket.Fd), Data);
   end Receive;


   function Address (Ip : in String) return String is
   begin
      for I in Ip'Range loop
         if Ip (I) = ':' then
            return Ip (Ip'First .. I - 1);
         end if;
      end loop;
      raise Multicast_Error;
   end Address;

   function Port (Ip : in String) return Integer is
   begin
      for I in Ip'Range loop
         if Ip (I) = ':' then
            return Integer'Value (Ip (I + 1 .. Ip'Last));
         end if;
      end loop;
      raise Multicast_Error;
   end Port;

   function In_Range (Ip : in String) return Boolean is
      A : constant Integer := Ip'First;
      B : constant Integer := A + 1;
      C : constant Integer := B + 1;
   begin
      if IP'Length > 0 and then IP(A) = '2' then
         if IP'Length > 1 and then (IP(B) = '2' or IP(B) = '3') then
            if IP'Length > 2 and then (IP(C) >= '4' and IP(C) <= '9') then
               return True;
            end if;
         end if;
      end if;
      return False;
   end In_Range;


   -- Command Pattern

   function Create (Ip : in String) return Receiver is
   begin
      return new Receiver_Type'(Handle =>
                                    new Receiver_Imp (Ip => new String'(Ip)));
   end Create;

   function Create (Ip : in String) return Sender is
   begin
      return new Sender_Type'(Handle =>
                                  new Sender_Imp (Ip => new String'(Ip)));
   end Create;

   procedure Send (Obj : in out Sender; Msg : in Pace.Msg'Class) is
      Msg_Copy : Pace.Msg'Class := Msg;
   begin
      Msg_Copy.Slot := Pace.Get;
      if Msg_Copy.Slot = 0 then
         null;  -- Don't send out for Node=0
      else
         Obj.Handle.Send (Msg_Copy);
      end if;
   end Send;

   protected body Sender_Imp is
      procedure Send (Msg : in Pace.Msg'Class) is
      begin
         Pace.Msg'Class'Output (Data, Msg);
         -- Send (Sock, Pace.Stream.Data_Storage (Data).all);
         Send (Sock, Data);
         -- Pace.Log.Put_Line ("HEADER TX:"& Pace.Stream.Show_Header(Data));
         Pace.Stream.Reset_Data (Data);
      exception
         when E: others =>
            Pace.Error ("multicast send", Pace.X_Info (E));
      end Send;
   end Sender_Imp;


   task body Receiver_Imp is
      Data : Pace.Stream.Data_Access := new Pace.Stream.Data_Stream;
   begin
      Pace.Log.Agent_ID ("PACE.SOCKET.MULTICAST-" &  Ip.all);
      if Pace.Get = 0 then
         Pace.Display ("Multicast turned off for Node 0");
      else
         declare
            Sock : Multicast_Socket_Type :=
                Create_Multicast_Socket (Address (Ip.all), Port (Ip.all),
                                         Self_Loop => Self_Loop);
         begin
            loop
               begin
                  --Receive (Sock, Pace.Stream.Data_Storage (Data).all);
                  Receive (Sock, Data);
                  -- Pace.Log.Put_Line ("HEADER RX:"& Pace.Stream.Show_Header(Data));
                  Pace.Input (Pace.Msg'Class'Input (Data));
                  Pace.Stream.Reset_Data (Data);
               exception
                  when E: others =>
                     Pace.Error ("multicast receive", Pace.X_Info (E));
                     Pace.Stream.Reset_Data (Data);
               end;
            end loop;
         end;
      end if;
   exception
      when E: others =>
         Pace.Log.Ex (E, "multicast receiver");
   end Receiver_Imp;

   function Ready (Obj : Sender) return Boolean is
   begin
      return Obj /= null;
   end Ready;

------------------------------------------------------------------------------
-- $Id: pace-multicast.adb,v 1.1 2006/04/07 15:34:37 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Multicast;
