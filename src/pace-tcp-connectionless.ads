with Pace.Stream;
with GNAT.Sockets;

package Pace.Tcp.Connectionless is
   pragma Elaborate_Body;

   procedure Stream_Receive (To : out GNAT.Sockets.Sock_Addr_Type;
                             Socket : in Socket_Type; 
                             Stream : in Pace.Stream.Data_Access);

   procedure Stream_Send (To : in GNAT.Sockets.Sock_Addr_Type;
                          Socket : in Socket_Type;
                          Stream : in Pace.Stream.Data_Access;
                          Stream_Size : Integer := 0);

end Pace.Tcp.Connectionless;
