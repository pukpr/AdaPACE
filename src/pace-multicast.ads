with GNAT.Sockets;
with Ada.Streams;
with Pace.Stream;

package Pace.Multicast is
   ---------------------------------------------
   -- MULTICAST -- creation of multicast sockets
   ---------------------------------------------
   -- This is tied directly to a sockets implementation
   -- IP address is given as e.g. "<Class-D>:<Port>"
   --   where Class-D is between 224.xxx .. 239.xxx and
   --   Port number is shared across processes
   -- Use at own risk! Unreliable protocol

   pragma Elaborate_Body;

   type Multicast_Socket_Type is private;

   function Create_Multicast_Socket
               (Group : String;
                Port : Positive;
                Ttl : Positive := 16;
                Self_Loop : Boolean := True) return Multicast_Socket_Type;
   --  Create a multicast socket

   procedure Send (Socket : in Multicast_Socket_Type;
                   Data : in Pace.Stream.Data_Access);
   --  Send data over a multicast socket

   procedure Receive (Socket : in Multicast_Socket_Type;
                      Data : in Pace.Stream.Data_Access);
   --  Receive data over a multicast socket

   function Address (Ip : in String) return String;
   function Port (Ip : in String) return Integer;
   -- Parses Address:Port string

   function In_Range (Ip : in String) return Boolean;

   Multicast_Error : exception;

   ---------------------------------------------------
   -- Command Pattern
   ---------------------------------------------------
   --
   -- Example:
   --      Xmit : Sender := Create ("224.13.194.161:4161");
   --      Recv : Receiver := Create ("224.13.194.161:4161");

   type Sender_Type is limited private;

   type Sender is access Sender_Type;
   function Create (Ip : in String) return Sender;
   procedure Send (Obj : in out Sender; Msg : in Pace.Msg'Class);
   function Ready (Obj : Sender) return Boolean;

   type Receiver_Type is limited private;

   type Receiver is access Receiver_Type;
   function Create (Ip : in String) return Receiver;

private

   -- RAW Stream
   type Multicast_Socket_Type is
      record
         Fd : GNAT.Sockets.Socket_Type;
         Target : GNAT.Sockets.Sock_Addr_Type;
       end record;

   Self_Loop : constant Boolean := True;

   -- Command Pattern
   protected type Sender_Imp (Ip : access String) is
      procedure Send (Msg : in Pace.Msg'Class);
   private
      Sock : Multicast_Socket_Type :=
          Create_Multicast_Socket
             (Address (Ip.all), Port (Ip.all), Self_Loop => Self_Loop);
      Data : Pace.Stream.Data_Access := new Pace.Stream.Data_Stream;
   end Sender_Imp;
   type Sender_Handle is access Sender_Imp;
   type Sender_Type is
      record
         Handle : Sender_Handle;
      end record;

   task type Receiver_Imp (Ip : access String) is
   end Receiver_Imp;
   type Receiver_Handle is access Receiver_Imp;
   type Receiver_Type is
      record
         Handle : Receiver_Handle;
      end record;

------------------------------------------------------------------------------
-- $Id: pace-multicast.ads,v 1.1 2006/04/07 15:34:38 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Multicast;

