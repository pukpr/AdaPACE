with Ada.Strings.Fixed;
with Pace.Semaphore;
with Pace.Tcp.Http;
with Ada.Strings.Unbounded;

package body Pace.Ports is

   -- : Name server location (host:port)
   -- : Base ports for Messaging and Web services
   Host : constant String := Getenv ("PACE_HOST", Getenv ("HOST", "localhost"));
   Name_Server : constant String := Getenv ("PACE_SERVER", "");
   Messaging_Base : constant Integer := Getenv ("PACE_PORT_MSG", 5500);
   Web_Base : constant Integer := Getenv ("PACE_PORT_WEB", 5600);
   Other_Base : constant Integer := 0;

   Port_Ids : array (Services) of Integer :=
     (Messaging => Messaging_Base, -- Starting point
      Web => Web_Base,
      Other => Other_Base);

   function Format (Value : Integer) return String is
      use Ada.Strings.Fixed;
   begin
      return Trim (Integer'Image (Value), Ada.Strings.Left);
   end Format;

   function Query (Key, Value : in String) return String is
   begin
      return "/name_service?" & Key & "=" & Value & "&node=";
   end Query;

   type String_Access is access String;

   protected The_Web_Address is
      procedure Set (Value : in String);
      function Get return String;
      function Created return Boolean;
   private
      Web_Address : String_Access;
      Web_Address_Created : Boolean := False;
   end The_Web_Address;

   protected body The_Web_Address is
      procedure Set (Value : in String) is
      begin
         Web_Address := new String'(Value);
         Web_Address_Created := True;
      end Set;
      function Get return String is
      begin
         return Web_Address.all;
      end Get;
      function Created return Boolean is
      begin
         return Web_Address_Created;
      end Created;
   end The_Web_Address;

   function Initialize_Web_Port return String is
      Port : Natural;
   begin
      Port := Pace.Tcp.Create_Port_Handler;
      The_Web_Address.Set (Host & ":" & Format (Port));
      return Query (Put_Web_Port, The_Web_Address.Get);
   end Initialize_Web_Port;

   function Initialize_Msg_Port return String is
      Port : Natural;
   begin
      Port := Pace.Tcp.Create_Port_Handler;
      return Query (Put_Msg_Port, Host & ":" & Format (Port));
   end Initialize_Msg_Port;

   Mutex : aliased Pace.Semaphore.Mutex;

   --
   -- This will set the web address to the name server if available
   --
   function Set_Web_Address_To_Name_Server
              (Node : in Integer; Name : in String) return String is
      use Pace.Tcp.Http;
      Lock : Pace.Semaphore.Lock (Mutex'Access);
      Failed : Boolean := False;
   begin
      if The_Web_Address.Created then
         null;
      elsif Name_Server = "" then
         Failed := True;
      elsif Name = Name_Server then
         Pace.Display ("Loading name server @ " & Name);
         The_Web_Address.Set (Name);
      else
         begin
            Get (Url => Name_Server,
                 Item => Format (Node),
                 Init => Initialize_Web_Port'Access);
         exception
            when Pace.Tcp.Communication_Error =>
               Failed := True;
         end;
      end if;
      if Failed then
         Pace.Display
           ("NOTE: Web addressing can't call Name Server='" & 
             Name_Server & "', using " & Name);
         The_Web_Address.Set (Name);
      end if;
      return The_Web_Address.Get;
   end Set_Web_Address_To_Name_Server;

   function Unique_Name (Service : Services) return String is
      Name : constant String := Host & ":" & Unique_Port (Service, Pace.Get);
   begin
      if Service = Web then
         return Set_Web_Address_To_Name_Server (Pace.Get, Name);
      else
         return Name;
      end if;
   end Unique_Name;

   function Unique_Port (Service : Services;  -- if node given find port
                         Node : Integer) return Integer is
   begin
      return Port_Ids (Service) + Node;
   end Unique_Port;

   function Unique_Port (Service : Services;  -- string version
                         Node : Integer) return String is
   begin
      return Format (Unique_Port (Service, Node));
   end Unique_Port;

   function Put_Msg_Port return String is
   begin
      return "put_msg_port";
   end Put_Msg_Port;

   function Get_Msg_Port return String is
   begin
      return "get_msg_port";
   end Get_Msg_Port;

   function Put_Web_Port return String is
   begin
      return "put_web_port";
   end Put_Web_Port;

   function Get_Web_Port return String is
   begin
      return "get_web_port";
   end Get_Web_Port;

   procedure Set_Address_To_Name_Server (Node : in Integer) is
      use Pace.Tcp.Http;
   begin
      if Name_Server = "" then
         raise Pace.Tcp.Communication_Error;
      end if;
      Get (Url => Name_Server,
           Item => Format (Node),
           Init => Initialize_Msg_Port'Access);
   exception
      when Pace.Tcp.Communication_Error =>
         Pace.Display ("NOTE: Msg addressing can't call Name Server='" &
                       Name_Server & "' due to communication failure");
         raise;
   end Set_Address_To_Name_Server;

   function No_Slash return String is
   begin
      return "";
   end No_Slash;

   function Get_Address_From_Name_Server (Node : in Integer) return String is
      Done : Boolean := False;
      Address : Ada.Strings.Unbounded.Unbounded_String;
      procedure Read (Val : in String);
      procedure Parse is new Pace.Tcp.Http.Parse_Get (Read);
      procedure Read (Val : in String) is
      begin
         if not Done then
            Address := Ada.Strings.Unbounded.To_Unbounded_String (Val);
         end if;
         Done := True;
      end Read;
      use Pace.Tcp.Http;
   begin
      loop
         Done := False;
         Parse (Get (Url => Name_Server,
                     Item => Query (Get_Msg_Port, "any") & Format (Node),
                     Init => No_Slash'Access));
         exit when Ada.Strings.Unbounded.Index (Address, ":") > 1;
         delay 5.0;
      end loop;
      return Ada.Strings.Unbounded.To_String (Address);
   exception
      when Pace.Tcp.Communication_Error =>
         Pace.Display ("NOTE: Can't retrieve address from Name Server");
         return "";
   end Get_Address_From_Name_Server;

------------------------------------------------------------------------------
-- $id: pace-ports.adb,v 1.2 01/09/2003 23:19:39 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Ports;
