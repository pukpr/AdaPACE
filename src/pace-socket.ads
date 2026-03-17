package Pace.Socket is

   -----------------------------------------------------
   -- SOCKET -- Polymorphic message passing using Sockets
   -----------------------------------------------------
   -- Nodes are assigned logical values 1..N via the
   -- env.var NODE. Nodes are also assigned physical TCP/IP addresses
   -- which map to the logical number. Lookup table will dispatch the class
   -- tag to the correct node, where it will call the corresponding
   -- primitive Input, Inout, or Output function for base Msg.
   -- e.g. "nodes.pro" contains "connection(external_tag, logical_node)."
   --  connection(pkg, op, 1).
   -- and contains optional "host_node (logical_node, host_name[:port])."
   --  host_node (1, "wcss07:5555").

   pragma Elaborate_Body;

   procedure Init;
   -- Starts up Sender and Receiver tasks, loads the routing tables

   procedure Send (Obj : in Pace.Msg'Class; Ack : in Boolean := True; Forward : in Boolean := False);
   -- Associated with primitive Input(Obj)

   procedure Send_Inout (Obj : in out Pace.Msg'Class);
   -- Associated with primitive Inout(Obj)

   procedure Send_Out (Obj : out Pace.Msg'Class);
   -- Associated with primitive Output(Obj)


   generic
      type Remote is new Pace.Msg with private;
      type Local is new Remote with private;
      Send_Remote : in Boolean := True;
   procedure Observer;
   -- Attaches the local message to the remote message (i.e. for pub-sub )

   function Get_Destination (Obj : in Pace.Msg'Class) return String;
   -- Returns the "host:port" destination of message

   function Ping (Obj : in Pace.Msg'Class) return Boolean;
   -- Returns the availability of host:port

------------------------------------------------------------------------------
-- $id: pace-socket.ads,v 1.3 02/04/2003 23:09:27 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Socket;
