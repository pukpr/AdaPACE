with Ada.Tags;
with Ada.Task_Identification;
with Pace.Stream;
with Pace.Tcp;
with Pace.Config;
with Pace.Hash_Table;
with Pace.Log;
with Pace.Resource;
with Pace.Surrogates;
with Pace.Ports;
with Pace.Multicast;

package body Pace.Socket is

   package Mcast renames Pace.Multicast;

   package Tuning is
      --------------------------------------------
      -- TUNING -- Tunes the socket configuration
      --------------------------------------------
      -- The msg lookup table is set up as a hash
      Message_Lookup_Hash_Size : constant := 479; -- prime number

      -- Sending messages is accomplished through a pool of reources
      Max_Sender_Pool_Tasks : constant := 32;
      -- A value of 20 for IRIX slows the throughput considerably

      -- Each process has a single port, but connects to multiple other ports
      Max_Port_Connections : constant := 100;

      -- The connection between ports is accomplished through parallel sockets
      Max_Sockets_Per_Connection : constant := 50;

   end Tuning;

   package Connections is
      -----------------------------------------------------
      -- CONNECTIONS -- Maps nodes, ports, and sockets
      -----------------------------------------------------
      -- Process maps to host:port -and- node associates process with socket

      subtype Socket_Type is Pace.Tcp.Socket_Type;

      --
      -- Process: Identifies a host:port address with a logical number
      --
      type Process_Type is new Integer;

      procedure Set_Address (Process : in Process_Type; Address : in String);

      function Get_Address (Process : in Process_Type) return String;

      function New_Socket (Process : in Process_Type) return Socket_Type;

      function Max_Processes return Process_Type;

      --
      -- Node: Identifies a remote process with a private socket connection
      --
      type Node_Type is private;

      procedure Set_Process (Node : in out Node_Type;
                             Process : in Process_Type);

      function Same (Node : in Node_Type; Process : in Process_Type)
                    return Boolean;

      procedure Set_Socket (Node : in out Node_Type; Socket : in Socket_Type);

      function Get_Socket (Node : in Node_Type;
                           Retry : in Boolean := False;  -- Repair
                           Test : in Boolean := False) return Socket_Type;

      function Current_Socket (Node : in Node_Type) return Socket_Type;

      procedure Finish_Socket (Node : in Node_Type);

      function Match (Node : in Node_Type; Socket : in Socket_Type)
                     return Boolean;

      function Get_Process (Node : Node_Type) return Process_Type;

      function Is_Name_Served return Boolean;

      procedure Register_To_Name_Server;


      -- Class lookup

      function Checked_For_Class_Name (Node : in Node_Type) return Boolean;

      procedure Check_For_Class_Name
                  (Node : in out Node_Type; Id : in Ada.Tags.Tag);

      procedure Register_Class_Name
                  (Process : in Process_Type; Name : in String);

      function Get_MC_Socket (Node : in Node_Type) return MCast.Sender;

   private

      type Node_Type is
         record
            Process : Process_Type := 0;  -- Mapping to an IP address
            Socket : Socket_Type := 0;    -- Connecting through a socket
            Checked : Boolean := False;   -- Checks for mapping at start
         end record;

   end Connections;

   package body Connections is separate;

   -- Active_Object_Name : exception;

   Get_Nodes_File : constant String := Getenv ("PACE_NODES", "nodes.pro");
   Infinite_Sockets : constant Boolean := "0" = Getenv ("PACE_SOCKETS", "0");

   Sender_Started : Boolean := False;

   -- The X is short for ConnXtion database
   package X renames Pace.Socket.Connections;

   Empty : X.Node_Type; -- Default is Node #0 which is local

   package Nodes is new Pace.Hash_Table.Simple_Htable
        (Element => X.Node_Type,
         No_Element => Empty,
         Key => Ada.Tags.Tag,
         Hash => Pace.Hash_Table.Hash,
         Equal => Ada.Tags."=");

   task Initializer is
      entry Start;
   end Initializer;

   Host_Node : X.Process_Type := X.Process_Type (Pace.Get);

   --
   -- Data pool (used for Solaris, Windows, LynxOS)
   --
   type Pool_Range is range 1 .. Tuning.Max_Sender_Pool_Tasks;
   Pools : array (Pool_Range) of Pace.Stream.Data_Access :=
     (others => new Pace.Stream.Data_Stream);
   package Pool_Resource is new Pace.Resource (Pool_Range);

   task type Receiver is
      pragma Storage_Size (Pace.Getenv ("PACE_TASK_STACK", 80_000));
   end Receiver;
   type Receiver_Access is access Receiver;


   procedure Send (Obj : in out Pace.Msg'Class;
                   To : in X.Node_Type;
                   Ack : in Boolean := True;
                   Data_Out : in Pace.Stream.Data_Access;
                   Pool_Index : in Pool_Range) is
      Dest : X.Node_Type := To;

      function Get_Socket (Retry : in Boolean := False)
                          return Pace.Tcp.Socket_Type is
      begin
         loop
            begin
               return X.Get_Socket (Dest, Retry => Retry);
            exception
               when Pace.Tcp.Communication_Error =>
                  X.Check_For_Class_Name (Dest, Obj'Tag);
            end;
         end loop;
      end Get_Socket;

      Sock : Pace.Tcp.Socket_Type;
      MC : MCast.Sender := X.Get_MC_Socket (Dest);
   begin
      -- Do this in the special case of multicast
      -- if not Ack and then
      if Mcast.Ready (MC) then
         MCast.Send (MC, Obj);
         Pool_Resource.Free (Pool_Index);
         return;
      end if;
      Sock := Get_Socket; -- (Retry => not Ack);

      if not X.Match (Dest, Sock) then  -- Not matched in socket database yet
         X.Set_Socket (Dest, Sock);
         Nodes.Set (Obj'Tag, Dest);
      end if;

      begin -- begin block cleans up any stack garbage
         Pace.Msg'Class'Output (Data_Out, Obj);
      end;

      loop
         exit when Pace.Tcp.Stream_Send (X.Current_Socket (Dest), Data_Out);
         X.Finish_Socket (Dest);
         X.Set_Socket (Dest, Get_Socket (Retry => True));
      end loop;
      if Ack then
         pragma Debug (Pace.Display ("Waiting return of " & Pace.Tag (Obj) &
                                     Integer'Image (X.Current_Socket (Dest))));
         if Pace.Tcp.Stream_Receive (X.Current_Socket (Dest), Data_Out) then
            if Obj.Enum = Two_Way or Obj.Enum = Reply then
               begin
                  Obj := Pace.Msg'Class'Input (Data_Out);
               end;
            end if;
         else
            Pace.Error ("Error on Sync return from" &
                        Integer'Image (X.Current_Socket (Dest)));
            X.Set_Socket (Dest, 0);
         end if;
      end if;
      X.Finish_Socket (Dest);
      Pace.Stream.Reset_Data (Data_Out);

      -- Make this sender available
      Pool_Resource.Free (Pool_Index);
   exception
      when E: others =>
         Pace.Error ("Pool index #" & Pool_Range'Image (Pool_Index),
                     Pace.X_Info (E));
   end Send;


   procedure Check_External_Send (Obj : in Pace.Msg'Class;
                                  Ext : out Boolean;
                                  To : out X.Node_Type;
                                  Forward : in Boolean := False) is
      Id : Ada.Tags.Tag := Obj'Tag;
   begin
      if Integer (Host_Node) = 0 then
         Ext := False;
         return;
      end if;
      if Obj.Slot = 0 or Forward = True then
         To := Nodes.Get (Id);
         if not X.Checked_For_Class_Name (To) then
            X.Check_For_Class_Name (To, Id);
            Nodes.Set (Id, To);  -- Reentrant safe
         end if;
      else
         X.Set_Process (To, X.Process_Type (Obj.Slot));
      end if;
      if X.Same (To, Host_Node) or X.Same (To, 0) then
         pragma Debug (Pace.Display ("Local call"));
         Ext := False;
      else
         Ext := True;
      end if;
   end Check_External_Send;

   procedure External_Send (Obj : in out Pace.Msg'Class;
                            Ack : in Boolean := True;
                            To : X.Node_Type) is
      Old_Slot : constant Integer := Obj.Slot;
      Old_Id : constant Ada.Task_Identification.Task_Id := Obj.Id;
   begin
      Obj.Slot := Integer (Host_Node);
      Obj.Id := Ada.Task_Identification.Null_Task_Id;
      if Ack then
         Obj.Send := Pace.Sync;
      else
         Obj.Send := Pace.Async;
      end if;
      while not Sender_Started loop
         Pace.Display ("...waiting for socket sender to start");
         delay 1.0;  -- make sure that at least one sender task is ready
      end loop;
      declare
         P : Pool_Range;
      begin
         P := Pool_Resource.Get;
         Send (Obj, To, Ack, Pools (P), P);
      end;
      Obj.Slot := Old_Slot;
      Obj.Id := Old_Id;
   end External_Send;

   procedure Send (Obj : in Pace.Msg'Class; Ack : in Boolean := True; Forward : in Boolean := False) is
      To : X.Node_Type;
      Ext : Boolean;
   begin
      Check_External_Send (Obj, Ext, To, Forward);
      if Ext then
         declare
            External_Msg : Pace.Msg'Class := Obj;
         begin
            Pace.Set_Time (External_Msg);
            External_Msg.Enum := One_Way;
            External_Send (External_Msg, Ack, To);
         end;
      elsif not Forward then
         -- if local dispatch and forwarding then do nothing!.. don't want to send
         -- to self.
         if Ack then
            Pace.Input (Obj);
         else
            Pace.Surrogates.Input (Obj);
         end if;
      end if;
   end Send;

   procedure Send_Inout (Obj : in out Pace.Msg'Class) is
      To : X.Node_Type;
      Ext : Boolean;
   begin
      Pace.Set_Time (Obj);
      Check_External_Send (Obj, Ext, To);
      Obj.Enum := Two_Way;
      if Ext then
         External_Send (Obj, True, To);
      else
         Pace.Inout (Obj);
      end if;
   end Send_Inout;

   procedure Send_Out (Obj : out Pace.Msg'Class) is
      To : X.Node_Type;
      Ext : Boolean;
   begin
      Pace.Set_Time (Obj);
      Check_External_Send (Obj, Ext, To);
      -- Obj.Enum := Two_Way;
      if Ext then
         declare
            External_Msg : Pace.Msg'Class := Obj;
         begin
            External_Msg.Enum := Reply;
            External_Send (External_Msg, True, To);
            Obj := External_Msg;
         end;
      else
         Pace.Output (Obj);
      end if;
   end Send_Out;

   procedure Init is
   begin
      if Pace.Get = 0 then
         return;
      end if;
      select
         Initializer.Start;
      or
         delay 10.0;
         Pace.Display ("Socket already initialized");
      end select;
   end Init;

   Receiver_Ptr : Receiver_Access;

   procedure New_Receiver is
   begin
      Pace.Display ("Starting new receiver");
      loop
         begin
            Receiver_Ptr := new Receiver;
            exit;
         exception
            when E: others =>
               Pace.Error ("Creating socket receiver task, retrying...",
                           Pace.X_Info (E));
               delay 5.0;
         end;
      end loop;
   end New_Receiver;

   --
   -- Receiver Task
   --
   task body Receiver is
      S : Pace.Tcp.Socket_Type := 0;
      Data_In : Pace.Stream.Data_Access := new Pace.Stream.Data_Stream;
      function Id is new Pace.Log.Unit_Id;
   begin
      Pace.Log.Agent_Id (Id);
      -- Larger delay may reduce the number of Receivers that start up
      --      delay Duration (Receiver_Delay);
      S := X.New_Socket (Host_Node);
      Pace.Display ("Receiver socket started" & Integer'Image (S));
      --
      -- Should new receiver be in the Initializer task? ...as in Sender task?
      if Infinite_Sockets then
         Pace.Log.Put_Line ("making a new receiver!");
         New_Receiver; -- Generate a new receiver for another socket
      end if;
      --
      loop
         loop
            exit when Pace.Tcp.Stream_Receive (S, Data_In);
            -- since comm error, shutdown socket and start a new one
            Pace.Tcp.Shutdown (S);
            S := X.New_Socket (Host_Node);
         end loop;
         declare
            Obj : Pace.Msg'Class := Pace.Msg'Class'Input (Data_In);
         begin
            Pace.Stream.Reset_Data (Data_In);
            pragma Debug (Pace.Display ("Received " & Pace.Tag (Obj)));
            if Obj.Enum = One_Way then
               if Obj.Send = Sync then
                  Pace.Input (Obj);
                  -- Send back 1 byte to satisfy the waiting sender
                  if Pace.Tcp.Stream_Send (S, Data_In, 1) then
                     null;
                     pragma Debug (Pace.Display
                                     ("Input return to " & Pace.Tag (Obj) &
                                      Integer'Image (Obj.Slot)));
                  else
                     Pace.Display ("Error on Input return " & Pace.Tag (Obj) &
                                   Integer'Image (Obj.Slot));
                  end if;
               else
                  Pace.Surrogates.Input (Obj);
               end if;
            elsif Obj.Enum = Two_Way or Obj.Enum = Reply then
               if Obj.Enum = Two_Way then
                  Pace.Inout (Obj);
               else
                  Pace.Output (Obj);
               end if;
               Pace.Msg'Class'Output (Data_In, Obj);
               if Pace.Tcp.Stream_Send (S, Data_In) then
                  null;
                  pragma Debug (Pace.Display
                                  ("Round-trip return to" & Pace.Tag (Obj) &
                                   Integer'Image (Obj.Slot)));
               else
                  Pace.Error ("Error on round-trip return" &
                              Pace.Tag (Obj) & Integer'Image (Obj.Slot));
               end if;
            else
               Pace.Display ("Unknown Send Enum " & Delivery'Image (Obj.Enum));
            end if;
         exception
            when E: others =>
               Pace.Error ("Dispatching IPC Msg " & Delivery'Image (Obj.Enum),
                           Pace.X_Info (E));
         end;
         Pace.Stream.Reset_Data (Data_In);
      end loop;
      --unreachable Pace.Display ("Exited socket receiver");
   exception
      when E: others =>
         Pace.Log.Ex (E, "Socket header:" & Pace.Stream.Show_Header (Data_In));
   end Receiver;


   procedure Read_Node_Map is
   begin
      Pace.Display ("Host Node=" & X.Process_Type'Image (Host_Node));
      if Integer (Host_Node) = 0 then
         return;
      end if;

      X.Register_To_Name_Server;
      ---------------------------------
      -- Reading in physical TCP/IP Nodes file
      --    host_node(1, "wcss07:5501").
      --    host_node(2, "chukar:5502"). etc
      -- This maps the logical Node number to a named IP address
      ---------------------------------
      -- load anything up that is in a local database
      -- The file which contains the rest of the functors to be asserted
      Pace.Config.Load (Get_Nodes_File);
      if not X.Is_Name_Served then
         for P in 1 .. X.Max_Processes loop
            declare
               use Pace.Config;
            begin
               X.Set_Address (P, Get_String
                                   ("host_node", X.Process_Type'Image (P)));
            exception
               when Not_Found =>
                  null;
            end;
         end loop;
      end if;
   end Read_Node_Map;

   task body Initializer is
      function Id is new Pace.Log.Unit_Id;
   begin
      Pace.Log.Agent_Id (Id);
      accept Start do
         Read_Node_Map;
      end Start;
      New_Receiver;
      Pace.Display ("Setting up Socket Sending Pool");
      for I in Pool_Range loop
         Pool_Resource.Free (I);
      end loop;
      Sender_Started := True;
      loop
         delay 10.0;
         if not Pool_Resource.Is_Available then
            Pace.Display ("WARNING: Ran out of Socket Sending Pool Resources");
         end if;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E, "socket initializer");
   end Initializer;

   procedure Observer is
      Client : Local;
      Service : Remote;
   begin
      if Client'Size /= Service'Size then
         Pace.Error ("Observer size mismatch " & Pace.Tag (Client) &
                     ": with " & Pace.Tag (Service));
      else
         Input (Remote (Client));
         if Send_Remote then
            Send (Service);
         end if;
      end if;
   end Observer;

   function Get_Destination (Obj : in Pace.Msg'Class) return String is
      To : X.Node_Type;
      Ext : Boolean;
      P : X.Process_Type;
      use Pace.Ports;
   begin
      Check_External_Send (Obj, Ext, To);
      if Ext then
         P := X.Get_Process (To);
         if Integer (P) /= 0 then
            return X.Get_Address (P);
         end if;
      end if;
      return "localhost:" & Unique_Port (Service => Messaging, Node => 0);
   end Get_Destination;

   function Ping (Obj : in Pace.Msg'Class) return Boolean is
      To : X.Node_Type;
      Ext : Boolean;
      P : X.Process_Type;
   begin
      Check_External_Send (Obj, Ext, To);
      if Ext then
         P := X.Get_Process (To);
         if Integer (P) /= 0 then
            Ext := 0 /= X.Get_Socket (To, Test => True);
            X.Finish_Socket (To);  -- Node releases "in use" lock
            return Ext;
         end if;
      end if;
      return True;
   end Ping;


begin

   if Pace.Getenv ("PACE_INIT", 1) = 1 then
      Init;
   end if;

------------------------------------------------------------------------------
------------------------------------------------------------------------------
end Pace.Socket;
