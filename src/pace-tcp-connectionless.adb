with GNAT.Sockets;
with Pace.Ordering;

package body Pace.Tcp.Connectionless is

   package AS renames Ada.Streams;
   function Net_Reverse is new Pace.Ordering (Integer);


   procedure Physical_Receive (To : out GNAT.Sockets.Sock_Addr_Type;
                               Fd : in Socket_Type;
                               Data : in System.Address;
                               Len : in Integer) is
      S : GNAT.Sockets.Socket_Type;
      for S'Address use Fd'Address;
      L : AS.Stream_Element_Offset := AS.Stream_Element_Offset(Len);
      A : AS.Stream_Element_Array (1 .. L);
      for A'Address use Data;
      Last : AS.Stream_Element_Offset := L;
      use type AS.Stream_Element_Offset;
   begin
      L := 0;
      loop
         GNAT.Sockets.Receive_Socket (S, A (L+1 .. Last), L, To);
         exit when L >= AS.Stream_Element_Offset(Len) or L < 1;
      end loop;
      if L < 1 then  --  L is less than 1 if peer closes connection
         raise Communication_Error;
      end if;
   exception
      when GNAT.Sockets.Socket_Error =>
         raise Communication_Error;
   end Physical_Receive;


   procedure Physical_Send (To : in GNAT.Sockets.Sock_Addr_Type;
                            Fd : in Socket_Type;
                            Data : in System.Address;
                            Len : in Integer) is
      S : GNAT.Sockets.Socket_Type;
      for S'Address use Fd'Address;
      L : AS.Stream_Element_Offset := AS.Stream_Element_Offset(Len);
      A : AS.Stream_Element_Array (1 .. L);
      for A'Address use Data;
      Last : AS.Stream_Element_Offset := L;
      use type AS.Stream_Element_Offset;
   begin
      L := 0;
      loop
         GNAT.Sockets.Send_Socket (S, A (L+1 .. Last), L, To);
         exit when L >= AS.Stream_Element_Offset(Len) or L < 1;
      end loop;
      if L /= AS.Stream_Element_Offset(Len) then
         Pace.Error ("Can't send entire set of data over socket");
         raise Communication_Error;
      end if;
   exception
      when GNAT.Sockets.Socket_Error =>
         raise Communication_Error;
   end Physical_Send;


   procedure Stream_Send (To : in GNAT.Sockets.Sock_Addr_Type;
                          Socket : in Socket_Type;
                          Stream : in Pace.Stream.Data_Access;
                          Stream_Size : Integer := 0) is
      Size : Integer;
      Net_Size : Integer;
   begin
      if Stream_Size = 0 then
         Size := Integer (Pace.Stream.Data_Size (Stream));
      else
         Size := Stream_Size;
      end if;
      Net_Size := Net_Reverse (Size);
      Physical_Send (To, Socket, Net_Size'Address, 4);
      Physical_Send (To, Socket, Pace.Stream.Data_Address (Stream, Size), Size);
      Pace.Stream.Reset_Data (Stream);
   exception
      when Communication_Error =>
         Pace.Error ("Connectionless Socket Sender unconnected");
   end;


   procedure Stream_Receive (To : out GNAT.Sockets.Sock_Addr_Type;
                             Socket : in Socket_Type; 
                             Stream : in Pace.Stream.Data_Access) is
      Size : Integer;
      Net_Size : Integer;
   begin
      Pace.Stream.Reset_Data (Stream);
      Physical_Receive (To, Socket, Net_Size'Address, 4);
      Size := Net_Reverse (Net_Size);
      Physical_Receive (To, Socket, Pace.Stream.Data_Address (Stream, Size), Size);
   exception
      when Communication_Error =>
         Pace.Error ("Connectionless Socket Receiver unconnected");
   end;


end Pace.Tcp.Connectionless;
