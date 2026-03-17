with Ada.Strings.Fixed;
with Pace.Ports;
with Pace.Config;

separate (Pace.Socket)
package body Connections is

   Localhost : constant String := "localhost";
   Number_Of_Retries : constant Integer :=
     Pace.Getenv ("PACE_RETRIES", Integer'Last);

   type String_Access is access String;

   -- Have a limited number of socket connections
   subtype Max_Number_Of_Connections is
     Process_Type range 1 .. Tuning.Max_Port_Connections;
   subtype Sockets_Per_Connection is
     Integer range 1 .. Tuning.Max_Sockets_Per_Connection;

   type Socket_Resource_Type is
      record
         In_Use : Boolean := False;
         Socket : Integer := 0;
      end record;
   type Socket_Set is array (Sockets_Per_Connection) of Socket_Resource_Type;
   type Socket_Set_Access is access Socket_Set;

   type Socket_Connection is
      record
         Name : String_Access;
         Set : Socket_Set_Access;
         Local : Boolean := True;
         MC : Mcast.Sender;
      end record;
   type Socket_Connection_Array is
     array (Max_Number_Of_Connections) of Socket_Connection;


   function Make_Host_Port
              (Process : in Process_Type; Host : in String) return String is
   begin
      return Host & ":" & Pace.Ports.Unique_Port
                            (Service => Pace.Ports.Messaging,
                             Node => Integer (Process));
   end Make_Host_Port;


   protected Lock is
      procedure Check_Name_Service (Process : in Process_Type);
      procedure Get_Socket (Node : in Node_Type;
                            Retry : in Boolean := False;
                            Socket : out Socket_Type);
      procedure Finish_Socket (Node : in Node_Type);
      function Get_Address (Process : in Process_Type) return String;
      procedure Set_Address (Process : in Process_Type; Address : in String);
      function Is_Name_Served return Boolean;
      procedure Register_To_Name_Server;
      function Get_MC_Socket (Node : in Node_Type) return MCast.Sender;
   private
      Socket_Array : Socket_Connection_Array;
      Using_Name_Server : Boolean := True;
   end Lock;

   protected body Lock is

      procedure Check_Name_Service (Process : in Process_Type) is
         Conn : Socket_Connection renames Socket_Array (Process);
      begin
         if Is_Name_Served then
            if Conn.Name = null or else Conn.Local then
               declare
                  Address : constant String :=
                    Pace.Ports.Get_Address_From_Name_Server (Integer (Process));
               begin
                  Conn.Local := False;
                  Conn.Name := new String'(Address);
                  Conn.Set := new Socket_Set;
                  Pace.Display (Address &
                                " <= Name Service address for Node #" &
                                Process_Type'Image (Process));
               end;
            end if;
         end if;
      end Check_Name_Service;

      procedure Get_Socket (Node : in Node_Type;
                            Retry : in Boolean := False;
                            Socket : out Socket_Type) is
         To_Name : String_Access;
         Socket_Resource : Socket_Resource_Type;
         New_Socket : Sockets_Per_Connection := Sockets_Per_Connection'First;
         Reused : Boolean := False;
         Set : Socket_Set_Access renames Socket_Array (Node.Process).Set;
      begin
         if Retry then -- Have to shut this socket down to self-repair
            for I in Sockets_Per_Connection loop
               if Set (I).Socket = Node.Socket then
                  if Set (I).Socket /= 0 then
                     Pace.Tcp.Shutdown (Set (I).Socket);
                  end if;
                  Set (I) := (In_Use => False, Socket => 0);
                  exit;
               end if;
            end loop;
         end if;
         Check_Name_Service (Node.Process);
         Socket_Resource := Set (New_Socket);
         if Socket_Resource.Socket = 0 or Retry or Socket_Resource.In_Use then
            if Socket_Resource.In_Use then
               for I in Sockets_Per_Connection loop
                  if not Set (I).In_Use then
                     New_Socket := I;
                     Socket := Set (I).Socket;
                     pragma Debug (Pace.Display ("Found unused Socket" &
                                                 Integer'Image (-Integer (I)) &
                                                 Integer'Image (Socket)));
                     if Socket /= 0 then
                        Socket_Resource.Socket := Socket;
                        Reused := True;
                     end if;
                     exit;
                  end if;
               end loop;
            end if;

            if not Reused then
               To_Name := Socket_Array (Node.Process).Name;
               Pace.Display ("Connecting to " & To_Name.all);
               Socket_Resource.Socket :=
                 Pace.Tcp.Establish_Connection (To_Name.all);
               Pace.Display ("Connected to " & To_Name.all);
            end if;
            Socket_Resource.In_Use := True;
            Set (New_Socket) := Socket_Resource;
         else
            Set (New_Socket).In_Use := True;
         end if;
         Socket := Socket_Resource.Socket;
      end Get_Socket;

      procedure Finish_Socket (Node : in Node_Type) is
      begin
         for I in Sockets_Per_Connection loop
            if Socket_Array (Node.Process).Set (I).Socket = Node.Socket then
               Socket_Array (Node.Process).Set (I).In_Use := False;
               pragma Debug (Pace.Display ("Finish Socket" &
                                           Integer'Image (-Integer (I)) &
                                           Integer'Image (Node.Socket)));
               exit;
            end if;
         end loop;
      end Finish_Socket;

      function Get_Address (Process : in Process_Type) return String is
      begin
         if Socket_Array (Process).Name = null then
            return "";
         else
            return Socket_Array (Process).Name.all;
         end if;
      end Get_Address;

      procedure Set_Address (Process : in Process_Type; Address : in String) is
         --    Socket_Array (1).Name := new String'("wcss07:5555");
         --    Socket_Array (2).Name := new String'("chukar:5557"); etc
         -- This maps the logical Node number to an IP address
      begin
         Socket_Array (Process).Local := False;
         if Ada.Strings.Fixed.Index (Address, ":") >
            1 then  -- Port number available
            Socket_Array (Process).Name := new String'(Address);
            Pace.Display ("NOTE: Checking address:" & Address);
            if Mcast.In_Range (Address) then
               Socket_Array (Process).MC := Mcast.Create (Address);
            end if;
         else
            -- Find unique port from port table
            Socket_Array (Process).Name :=
              new String'(Make_Host_Port (Process, Address));
         end if;
         Socket_Array (Process).Set := new Socket_Set;
      end Set_Address;

      function Is_Name_Served return Boolean is
      begin
         return Using_Name_Server;
      end Is_Name_Served;

      procedure Register_To_Name_Server is
      begin
         -- Initialize all socket array nodes to local host
         for P in Socket_Array'Range loop
            Set_Address (P, Localhost);
            Socket_Array (P).Local := True;
         end loop;
         Pace.Ports.Set_Address_To_Name_Server (Pace.Get);
         Pace.Display ("NOTE: Using Name Server");
         Using_Name_Server := True;
      exception
         when Pace.Tcp.Communication_Error =>
            Pace.Display ("NOTE: Name Server disabled, using lookup table.");
            Using_Name_Server := False;
      end Register_To_Name_Server;

      function Get_MC_Socket (Node : in Node_Type) return MCast.Sender is
      begin
         return Socket_Array (Node.Process).MC;
      end Get_MC_Socket;

   end Lock;

   function Get_MC_Socket (Node : in Node_Type) return MCast.Sender is
   begin
      return Lock.Get_MC_Socket (Node);
   end Get_MC_Socket;


   -- Non-Lock interface

   function Max_Processes return Process_Type is
   begin
      return Max_Number_Of_Connections'Last;
   end Max_Processes;


   procedure Check_Name_Service (Process : in Process_Type) is
   begin
      Lock.Check_Name_Service (Process);
   end Check_Name_Service;

   function Get_Socket (Node : in Node_Type;
                        Retry : Boolean := False;  -- Repair
                        Test : in Boolean := False) return Socket_Type is
      S : Socket_Type;
      Retries : Integer := 1; -- this was 0
   begin
      loop
         begin
            Lock.Get_Socket (Node, Retry, S);
            return S;
         exception
            when Pace.Tcp.Communication_Error =>
               if Test then
                  return 0;
               else
                  Pace.Display ("*** Retry in" & Integer'Image (Retries) &
                                " seconds to: " & Get_Address (Node.Process));
                  delay Duration (Retries);
                  Retries := Retries + 1;
                  if Retries > Number_Of_Retries then
                     raise;
                  end if;
               end if;
            when E: others =>
               Pace.Error ("**********************");
               Pace.Error ("Connections-Get_Socket", Pace.X_Info (E));
               Pace.Error ("**********************");
               delay 0.5;
               return 0;
         end;
      end loop;
   end Get_Socket;

   function Current_Socket (Node : in Node_Type) return Socket_Type is
   begin
      return Node.Socket;
   end Current_Socket;

   procedure Finish_Socket (Node : in Node_Type) is
   begin
      Lock.Finish_Socket (Node);
   exception
      when E: others =>
         Pace.Error ("Connections-Finish_Socket", Pace.X_Info (E));
   end Finish_Socket;

   procedure Set_Socket (Node : in out Node_Type; Socket : in Socket_Type) is
   begin
      Node.Socket := Socket;
   end Set_Socket;

   procedure Set_Process (Node : in out Node_Type; Process : in Process_Type) is
   begin
      Node.Process := Process;
   end Set_Process;

   function Match (Node : in Node_Type; Socket : in Socket_Type)
                  return Boolean is
   begin
      return Node.Socket = Socket;
   end Match;

   function Same (Node : in Node_Type; Process : in Process_Type)
                 return Boolean is
   begin
      return Node.Process = Process;
   end Same;

   function Get_Address (Process : in Process_Type) return String is
   begin
      return Lock.Get_Address (Process);
   end Get_Address;

   procedure Set_Address (Process : in Process_Type; Address : in String) is
   begin
      Lock.Set_Address (Process, Address);
   exception
      when E: others =>
         Pace.Error ("Connections-Set_Address for: " & Address,
                     Pace.X_Info (E));
   end Set_Address;


   function New_Socket (Process : in Process_Type) return Socket_Type is
   begin
      Lock.Check_Name_Service (Process);
      return Pace.Tcp.Accept_Connection
               (Host_And_Port => Lock.Get_Address (Process));
   exception
      when E: others =>
         Pace.Error ("Connections-New_Socket", Pace.X_Info (E));
         raise;
   end New_Socket;

   function Is_Name_Served return Boolean is
   begin
      return Lock.Is_Name_Served;
   end Is_Name_Served;

   procedure Register_To_Name_Server is
   begin
      Lock.Register_To_Name_Server;
   end Register_To_Name_Server;

--------------------------

   function Checked_For_Class_Name (Node : in Node_Type) return Boolean is
   begin
      return Node.Checked;
   end Checked_For_Class_Name;


   -- Don't necessarily need a lock if registration done at startup only
   procedure Register_Class_Name
               (Process : in Process_Type; Name : in String) is
   begin
      Pace.Display ("WARNING: Unused 'Register_Class_Name'");
   end Register_Class_Name;

   procedure Check_For_Class_Name
               (Node : in out Node_Type; Id : in Ada.Tags.Tag) is
      Tag_Name : constant String := Ada.Tags.Expanded_Name (Id); -- external_tag
      Process : Process_Type;
      Host_Node : Process_Type := Process_Type (Pace.Get);
   begin
      if Node.Checked then
         -- If a socket connection fails, it will temporarily use the backup for
         -- one message. It will then try the remote again on a subsequent message.
         -- If that fails, the backup message will be permanent
         Process := Process_Type
                      (Pace.Config.Get_Integer
                         ("hot_backup", Pace.Config.Parse (Tag_Name)));
         if Node.Process = Process then
            Pace.Display ("Network reconfiguring to local copy ...");
            Set_Process (Node, Host_Node);
         elsif Node.Process = Host_Node then
            Pace.Display ("Network staying with local copy ...");
            return;
         else
            Pace.Display ("Network reconfiguring to backup copy ...");
            Set_Process (Node, Process);
         end if;
         -- if we want to make the new connection permanent ...
         Set_Socket (Node, 0); -- reset the destination socket
      else
         Process := Process_Type
                      (Pace.Config.Get_Integer
                         ("connection", Pace.Config.Parse (Tag_Name)));
         Set_Process (Node, Process);
         Node.Checked := True;
      end if;
   exception
      when Pace.Config.Not_Found =>
         Error ("No remote Route found : " & Tag_Name);
         Pace.Display ("Network reconfiguring to local copy ...");
         Set_Process (Node, Host_Node);
         Set_Socket (Node, 0); -- reset the destination socket
      when E: others =>
         Error ("Reading Route failed : " & Tag_Name, Pace.X_Info (E));
   end Check_For_Class_Name;

   function Get_Process (Node : Node_Type) return Process_Type is
   begin
      return Node.Process;
   end Get_Process;

------------------------------------------------------------------------------
-- $id: pace-socket-connections.adb,v 1.3 03/10/2003 22:05:10 pukitepa Exp $
------------------------------------------------------------------------------
end Connections;
