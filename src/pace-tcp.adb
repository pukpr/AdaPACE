with Ada.Strings.Fixed;
with GNAT.Sockets;
with Interfaces;
with Pace.Ordering;
with Text_IO;

package body Pace.Tcp is

   Debug : constant Boolean := Getenv ("PACE_TCP_DISPLAY", "0") = "1";
   Ignore_Pipe : constant Boolean := Getenv ("PACE_IGNORE_PIPE", 0) = 1;

   procedure Debug_Display (Text : in String; X_Info : in String := "") is
   begin
      if X_Info = "" then
         if Debug then
            Text_Io.Put_Line (Text_Io.Current_Error, "SOCK-INFO:" & Text);
         end if;
      else
         Text_Io.Put_Line (Text_Io.Current_Error,
                           "SOCK-ERROR:" & Text & " : " & X_Info);
      end if;
   end Debug_Display;

   function Init return Integer is
   begin
      GNAT.Sockets.Initialize;
      Debug_Display ("SOCK Initialized for: " & GNAT.Sockets.Host_Name);
      return 0;
   end;
   
   Dummy : constant Integer := Init;
   
   procedure Ignore_Signal is
      procedure Signal (Sig, Op : in Integer);
      pragma Import (C, Signal, "signal");
      Sigpipe : constant := 13; -- Note: Not defined on Windows!
      Ignore : constant := 1;   -- Callback cast to 1 means ignore
   begin
      -- PIPE is a UNIX signal that exits program if not ignored or caught.
      -- It looks as if it needs to be caught on a per thread basis also.
      -- Other OS's such as Windows will ignore it
      if Ignore_Pipe then
         Signal (Sigpipe, Ignore);
      end if;
   end Ignore_Signal;

   package AS renames Ada.Streams;
   function Net_Reverse is new Pace.Ordering (Integer);
--   function Net_Reverse (Val : in Integer) return Integer;
--   pragma Import (Network_Call, Net_Reverse, "htonl"); -- or pick "ntohl"

   subtype Address is GNAT.Sockets.Inet_Addr_Type;

   subtype Host_Location is GNAT.Sockets.Sock_Addr_Type;  -- Address & Port

   type Host_Data is
      record
         Location : Host_Location;
         Fd : Integer;   -- Same value as Socket below
         Connected : Boolean := False;
         Socket : GNAT.Sockets.Socket_Type;
      end record;

   subtype Port_Type is GNAT.Sockets.Port_Type;
   subtype Port_Short is Interfaces.Unsigned_16;

   --
   --  Mappings between IP names and IP addresses.
   --
   package Naming is
      function Check_Security (Addr : Address) return Integer;
   end Naming;

   --  Address of an IP name or a dotted form.
   function Address_Of (Something : String) return Address is
   begin
      return GNAT.Sockets.Addresses (GNAT.Sockets.Get_Host_By_Name(Something));
   exception
      when GNAT.Sockets.Host_Error => -- try dotted form
         Pace.Error (Something & " is not in host table - using dotted quad");
         return GNAT.Sockets.Inet_Addr (Something);
   end Address_Of;

   --  Split a data given as <machine> or <machine>:<port>
   function Split_Data (Data : String) return Host_Location is
      Result : Host_Location;
   begin
      if Data = "" then
         return Result;
      end if;
      for I in Data'Range loop
         if Data (I) = ':' then -- Use Fields package?
            Result.Addr := Address_Of (Data (Data'First .. I - 1));
            Result.Port := Port_Type'Value (Data (I + 1 .. Data'Last));
            return Result;
         end if;
      end loop;
      Result.Addr := Address_Of (Data);
      return Result;
   end Split_Data;


   ------------------------------
   -- CLIENT Establish_Connection 
   ------------------------------

   function Establish_Connection (Host_And_Port : String) return Socket_Type is
      Location : Host_Location;
      S : GNAT.Sockets.Socket_Type;
   begin
      Location := Split_Data (Host_And_Port);
      GNAT.Sockets.Create_Socket (S);
      GNAT.Sockets.Connect_Socket (S, Location);
      GNAT.Sockets.Set_Socket_Option -- This can be moved before Connect?
         (S,
          GNAT.Sockets.IP_Protocol_For_TCP_Level,
          (GNAT.Sockets.No_Delay, True));
      return GNAT.Sockets.To_C (S);
   exception
      when E : others =>
         Pace.Error ("Establish Connection => " & Host_and_Port,
                     GNAT.Sockets.Error_Type'Image(
                       GNAT.Sockets.Resolve_Exception(E)));
         raise Communication_Error;
   end Establish_Connection;

   ----------------------
   -- Physical_Receive --
   ----------------------
--    procedure Physical_Receive (Fd : in Socket_Type;
--                                Data : in System.Address;
--                                Len : in Integer) is
--       S : GNAT.Sockets.Socket_Type;
--       for S'Address use Fd'Address;
--       subtype D is AS.Stream_Element_Array (1 .. AS.Stream_Element_Offset(Len));
--       Data_Buffer : D;
--       for Data_Buffer'Address use Data;
--       SS : GNAT.Sockets.Stream_Access;
--    begin
--       SS := GNAT.Sockets.Stream (S);
--       D'Read (SS, Data_Buffer);
--       GNAT.Sockets.Free (SS);
--    exception
--       when GNAT.Sockets.Socket_Error => 
--          GNAT.Sockets.Free (SS);
--          raise Communication_Error;
--       when others => 
--          GNAT.Sockets.Free (SS);
--          raise;
--    end Physical_Receive;

   procedure Physical_Receive (Fd : in Socket_Type;
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
         GNAT.Sockets.Receive_Socket (S, A (L+1 .. Last), L);
         exit when L >= AS.Stream_Element_Offset(Len) or L < 1;
      end loop;
      if L < 1 then  --  L is less than 1 if peer closes connection
         raise Communication_Error;
      end if;
   exception
      when GNAT.Sockets.Socket_Error =>
         raise Communication_Error;
   end Physical_Receive;


   -------------------
   -- Physical_Send --
   -------------------
--    procedure Physical_Send (Fd : in Socket_Type;
--                             Data : in System.Address;
--                             Len : in Integer) is
--       S : GNAT.Sockets.Socket_Type;
--       for S'Address use Fd'Address;
--       subtype D is AS.Stream_Element_Array (1 .. AS.Stream_Element_Offset(Len));
--       Data_Buffer : D;
--       for Data_Buffer'Address use Data;
--       SS : GNAT.Sockets.Stream_Access;
--    begin
--       SS := GNAT.Sockets.Stream (S);
--       D'Write (SS, Data_Buffer);
--       GNAT.Sockets.Free (SS);
--    exception
--       when GNAT.Sockets.Socket_Error => 
--          GNAT.Sockets.Free (SS);
--          raise Communication_Error;
--       when others => 
--          GNAT.Sockets.Free (SS);
--          raise;
--    end Physical_Send;

   procedure Physical_Send (Fd : in Socket_Type;
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
         GNAT.Sockets.Send_Socket (S, A (L+1 .. Last), L);
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


   ---------------------------------------------------------------
   --  SERVER side Task-based socket handling

   task type Accept_Handler is
      entry Start (Port : in out Port_Type);
      entry Get_Socket (Socket : out Integer; Client : out Integer);
   end Accept_Handler;
   --  The task which will accept new connections.

   type Handler_Ptr is access Accept_Handler;

   package Ports is
      procedure Set (Port : in Port_Short;
                     Handler : in Handler_Ptr);
      function Get (Port : in Port_Short) return Handler_Ptr;
   end;

   package body Ports is
      P : array (Port_Short) of Handler_Ptr := (others => null);

      --  package PV is new Ada.Containers.Indefinite_Vectors (Natural, Handler_Ptr);
      --  PVV : PV.Vector;
       
      procedure Set (Port : in Port_Short;
                     Handler : in Handler_Ptr) is
      begin
         P (Port) := Handler;
         -- PV.Replace_Element (PVV, Natural (Port), Handler);
      end Set;
      function Get (Port : in Port_Short) return Handler_Ptr is
      begin
         return P (Port);
         -- return PV.Element (PVV, Natural (Port));
      end;
   end;

   -----------------------
   -- Accept_Connection --
   -----------------------

   -- Handler_Mutex : aliased Pace.Semaphore.Mutex;
   protected Handler_Mutex is
      entry Wait;
      procedure Release;
   private
      Claimed : Boolean := False;
   end Handler_Mutex;

   protected body Handler_Mutex is
      entry Wait when not Claimed is
      begin
         Claimed := True;
      end Wait;
      procedure Release is
      begin
         Claimed := False;
      end Release;
   end Handler_Mutex;

   procedure Accept_Connection (Port : in out Port_Type;
                                Fd : out Socket_Type;
                                Client : out Integer) is
      S : Integer;
      Handler : Handler_Ptr;

      procedure Display_Accept_Connection_Error is
      begin
         Pace.Error ("****************************************");
         Pace.Error ("* TWO execs listening on same port?" &
                          Port_Type'Image (Port));
         Pace.Error ("****************************************");
         delay 5.0;
      end Display_Accept_Connection_Error;

   begin
      -- declare
      --   Handler_Lock : Pace.Semaphore.Lock (Handler_Mutex'Access);
      begin
         Handler_Mutex.Wait;
         -- Ports will always be less than 65,000 so OK to convert
         Handler := Ports.Get (Port_Short (Port));
      
         if Handler = null then
            Handler := new Accept_Handler;
            Debug_Display ("Creating listener for port" &
                             Port_Type'Image (Port));
            Handler.Start (Port_Type (Port));
            Ports.Set (Port_Short (Port), Handler);
         else
            Debug_Display ("Getting socket for port" & -- DEBUG
                             Port_Type'Image (Port));
         end if;
         Handler_Mutex.Release;
      exception
         when others =>
            Handler_Mutex.Release;
            raise;
      end;
      Handler.Get_Socket (S, Client);
      Fd := Socket_Type (S);
   exception
      when E : others =>
         Pace.Error ("Accept Connection", 
                     GNAT.Sockets.Error_Type'Image(
                       GNAT.Sockets.Resolve_Exception(E)));
         Display_Accept_Connection_Error;
         raise Communication_Error;
   end Accept_Connection;


   function Accept_Connection (Host_And_Port : String) return Socket_Type is
      Sock : Socket_Type;
      Client : Integer;
      Port : Port_Type;
   begin
      Port := Split_Data (Host_And_Port).Port;
      Accept_Connection (Port, Sock, Client);
      return Sock;
   end Accept_Connection;


   procedure Accept_Connection (Host_And_Port : String;
                                Port : in out Natural;
                                Fd : out Socket_Type;
                                Client : out Positive) is
      P : Port_Type := Port_Type (Port);
   begin
      if Port = 0 then
         P := Split_Data (Host_And_Port).Port;
         Accept_Connection (P, Fd, Client);
         Port := Natural (P);
      else
         Accept_Connection (P, Fd, Client);
      end if;
   end Accept_Connection;


   -------------------------
   -- Create_Port_Handler --
   -------------------------
   function Create_Port_Handler return Positive is
      Handler : Handler_Ptr;
      P : Port_Type := 0;
   begin
      Handler := new Accept_Handler;
      Debug_Display ("Creating unique listener port");
      Handler.Start (P);
      Ports.Set (Port_Short (P), Handler);
      return Positive (P);
   end Create_Port_Handler;

   --------------------------------
   -- Establish_Listening_Socket --
   --------------------------------
   --  Establish a socket according to the information in Self_Host 
   --  (andcomplete it if needed).
   procedure Establish_Listening_Socket (Self_Host : in out Host_Data) is
      use type Port_Type;
      S : GNAT.Sockets.Socket_Type;
      HL : Host_Location;
   begin
      GNAT.Sockets.Create_Socket (S);
      Self_Host.Fd := GNAT.Sockets.To_C (S);
      Self_Host.Socket := S;
      GNAT.Sockets.Set_Socket_Option
         (S,
          GNAT.Sockets.Socket_Level,
          (GNAT.Sockets.Reuse_Address, True));
      
      HL.Addr := GNAT.Sockets.Any_Inet_Addr;
      HL.Port := Self_Host.Location.Port;
      GNAT.Sockets.Bind_Socket (S, HL);
      GNAT.Sockets.Listen_Socket (S);
      -- If Port is not set then we grab a new one
      if Self_Host.Location.Port = 0 then
         HL := GNAT.Sockets.Get_Socket_Name (S);
         Self_Host.Location.Port := HL.Port;
      end if;
      Self_Host.Connected := True;
      Debug_Display ("Listening on port" & 
                       Port_Type'Image (Self_Host.Location.Port));
   exception
      when E : others =>
         Pace.Error ("Establish Listening Socket", 
                     GNAT.Sockets.Error_Type'Image(
                       GNAT.Sockets.Resolve_Exception(E)));
         raise Communication_Error;
   end Establish_Listening_Socket;

   --------------------
   -- Accept_Socket  --
   --------------------
   procedure Accept_Socket (Self_Host : in Host_Data;
                            Sock : out Integer;
                            Client : out Integer) is
      A : Host_Location;
      S : GNAT.Sockets.Socket_Type;
   begin
      pragma Debug (Debug_Display ("Accepting connections"));
      GNAT.Sockets.Accept_Socket (Self_Host.Socket, S, A);

      Client := Naming.Check_Security (A.Addr);

      GNAT.Sockets.Set_Socket_Option
         (S,
          GNAT.Sockets.IP_Protocol_For_TCP_Level,
          (GNAT.Sockets.No_Delay, True));
      Sock := GNAT.Sockets.To_C (S);
      pragma Debug (Debug_Display ("Accepted socket" &
                                     Integer'Image (Integer (Sock))));
   end Accept_Socket;

   --------------------
   -- Accept_Handler --
   --------------------
   task body Accept_Handler is
      Self_Host : Host_Data;
   begin
      Ignore_Signal;

      --  Wait for start listening on port
      select
         accept Start (Port : in out Port_Type) do
            Self_Host.Location.Port := Port;

            Establish_Listening_Socket (Self_Host);

            Port := Self_Host.Location.Port;
         end Start;
      or
         terminate;
      end select;

      --  Infinite loop on Accept_Socket.
      loop
         declare
            Fd : Integer;
            Caller : Integer;
         begin
            Accept_Socket (Self_Host, Fd, Caller);
            accept Get_Socket (Socket : out Integer; Client : out Integer) do
               Socket := Fd;
               Client := Caller;
            end Get_Socket;
         exception
            when Constraint_Error =>
               Pace.Error ("Accept-Socket failed.");
            when E : others =>
               Pace.Error
                 ("Accept-Socket, will try again in 10 secs ... ", X_Info (E));
               delay 10.0;

         end;
      end loop;

   exception
      when E : others =>
         Pace.Error ("Listening Socket", X_Info (E));
   end Accept_Handler;
   ---------------------------------------------- end of SERVER

   Crlf : constant String := Ascii.Cr & Ascii.Lf;

   --------------
   -- Get_Line --
   --------------

   function Get_Line (Socket : Socket_Type;
                      Delimiter : Character := ASCII.LF) return String is
      Result : String (1 .. 1024);
      Index : Positive := Result'First;
      Char : Character;
   begin
      loop
         Physical_Receive (Socket, Char'Address, 1);
         if Char = Delimiter then
            return Result (1 .. Index - 1);
         elsif Char /= Ascii.Cr then
            Result (Index) := Char;
            Index := Index + 1;
            if Index > Result'Last then
               return Result & Get_Line (Socket);
            end if;
         end if;
      end loop;
   end Get_Line;


   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (Socket : in Socket_Type; Str : in String) is
      Text : String := Str & Crlf;
   begin
      Physical_Send (Socket, Text'Address, Text'Length);
   end Put_Line;

   procedure Put (Socket : in Socket_Type; Str : in String) is
   begin
      Physical_Send (Socket, Str'Address, Str'Length);
   end Put;

   procedure New_Line (Socket : in Socket_Type; Count : in Natural := 1) is
   begin
      for I in 1 .. Count loop
         Put_Line (Socket, "");
      end loop;
   end New_Line;

   procedure Shutdown (Fd : in Socket_Type) is
      S : GNAT.Sockets.Socket_Type;
      for S'Address use Fd'Address;
   begin
      GNAT.Sockets.Shutdown_Socket (S);
      GNAT.Sockets.Close_Socket (S);
   exception
      when E : others =>
         Pace.Error ("Socket Shutdown", 
                     GNAT.Sockets.Error_Type'Image(
                       GNAT.Sockets.Resolve_Exception(E)));
   end Shutdown;


   -- Communicates with the socket layer ->
   function Stream_Send (Socket : in Socket_Type;
                         Stream : in Pace.Stream.Data_Access;
                         Stream_Size : Integer := 0) return Boolean is
      Size : Integer;
      Net_Size : Integer;
   begin
      if Stream_Size = 0 then
         Size := Integer (Pace.Stream.Data_Size (Stream));
      else
         Size := Stream_Size;
      end if;
      Net_Size := Net_Reverse (Size);
      Physical_Send (Socket, Net_Size'Address, 4);
      Physical_Send (Socket, Pace.Stream.Data_Address (Stream, Size), Size);
      Pace.Stream.Reset_Data (Stream);
      pragma Debug (Debug_Display ("TCP Msg sent" & Integer'Image (Size)));
      return True;
   exception
      when Communication_Error =>
         Pace.Error ("Socket Sender unconnected");
         return False;
   end Stream_Send;


   -- Communicates with the socket layer <-
   function Stream_Receive
              (Socket : in Socket_Type; Stream : in Pace.Stream.Data_Access)
              return Integer is
      Size : Integer;
      Net_Size : Integer;
   begin
      Pace.Stream.Reset_Data (Stream);
      Physical_Receive (Socket, Net_Size'Address, 4);
      Size := Net_Reverse (Net_Size);
      Physical_Receive (Socket, Pace.Stream.Data_Address (Stream, Size), Size);
      pragma Debug (Debug_Display ("TCP Msg recv" & Integer'Image (Size)));
      return Size;
   exception
      when Communication_Error =>
         Pace.Error ("Socket Receiver unconnected");
         return 0;
   end Stream_Receive;

   function Stream_Receive
              (Socket : in Socket_Type; Stream : in Pace.Stream.Data_Access)
              return Boolean is
   begin
      return Stream_Receive (Socket, Stream) > 0;
   end Stream_Receive;


   procedure New_Socket_Stream
               (Stream : in out Socket_Stream; Socket : in Socket_Type) is
   begin
      if Stream = null then
         Stream := new Socket_Stream_Type;
      end if;
      Stream.S := Socket;
   end New_Socket_Stream;

   procedure Read (Stream : in out Socket_Stream_Type;
                   Item : out AS.Stream_Element_Array;
                   Last : out AS.Stream_Element_Offset) is
      S : GNAT.Sockets.Socket_Type;
      for S'Address use Stream.S'Address;
   begin
      GNAT.Sockets.Receive_Socket (S, Item, Last);
   end Read;

   procedure Write (Stream : in out Socket_Stream_Type;
                    Item : in AS.Stream_Element_Array) is
      S : GNAT.Sockets.Socket_Type;
      for S'Address use Stream.S'Address;
      Last : AS.Stream_Element_Offset;
   begin
      GNAT.Sockets.Send_Socket (S, Item, Last);
   end Write;


   package body Naming is

      Named_Host : Address := Address_Of (GNAT.Sockets.Host_Name);
      Local_Host : Address := Address_Of ("localhost");
      Do_Security_Check : constant Boolean :=
        Pace.Getenv ("PACE_SECURITY_CHECK", "0") = "1";

      function Check_Security (Addr : Address) return Integer is
         Client : constant String := GNAT.Sockets.Image (Addr);
         C : Integer;
         V : Integer;
         use Ada.Strings;
      begin
         C := Fixed.Index(Client, ".", Backward);
         V := Integer'Value (Client(C+1..Client'Last));

         if Do_Security_Check then
            declare
               Client_Submask : constant String := Client(Client'First..C-1);

               Local : constant String := GNAT.Sockets.Image (Named_Host);
               L : Integer;
               use type Address; 
            begin
               L := Fixed.Index(Local, ".", Backward);
               if Client_Submask = Local(Local'First..L-1) or
                  Addr = Local_Host then
                  null;
               else
                  Debug_Display
                    ("WARNING: Accepted socket from outside subnet " & Client);
                  raise Constraint_Error;
               end if;
            end;
         end if;
         return V;
      end Check_Security;
   end Naming;

   ----------------------
   -- Command_Patterns --
   ----------------------

   function Command_Receive (Fd : in Socket_Type) return Msg'Class is
      S : GNAT.Sockets.Socket_Type;
      for S'Address use Fd'Address;
      SS : GNAT.Sockets.Stream_Access;
   begin
      SS := GNAT.Sockets.Stream (S);
      declare
         M : constant Msg'Class := Msg'Class'Input (SS);
      begin
         GNAT.Sockets.Free (SS);
         return M;
      end;
   exception
      when GNAT.Sockets.Socket_Error => 
         GNAT.Sockets.Free (SS);
         raise Communication_Error;
      when others => 
         GNAT.Sockets.Free (SS);
         raise;
   end Command_Receive;

   procedure Command_Send (Fd : in Socket_Type;
                           Obj : in Msg'Class) is
      S : GNAT.Sockets.Socket_Type;
      for S'Address use Fd'Address;
      SS : GNAT.Sockets.Stream_Access;
   begin
      SS := GNAT.Sockets.Stream (S);
      Msg'Class'Output (SS, Obj);
      GNAT.Sockets.Free (SS);
   exception
      when GNAT.Sockets.Socket_Error => 
         GNAT.Sockets.Free (SS);
         raise Communication_Error;
      when others => 
         GNAT.Sockets.Free (SS);
         raise;
   end Command_Send;

------------------------------------------------------------------------------
-- $Id: pace-tcp.adb,v 1.6 2006/07/03 16:47:57 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Tcp;
