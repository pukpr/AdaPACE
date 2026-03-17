with System;
with Pace.Stream;
with Ada.Streams;

package Pace.Tcp is
   --------------------------------------
   -- SOCKET.TCP -- TCP/IP implementation
   --------------------------------------
   pragma Elaborate_Body;

   subtype Socket_Type is Integer;

   procedure Physical_Receive (Fd : in Socket_Type;
                               Data : in System.Address;
                               Len : in Integer);
   procedure Physical_Send (Fd : in Socket_Type;
                            Data : in System.Address;
                            Len : in Integer);
   --
   --  Receive and send data. Physical_Receive loops as long as Data has
   --  not been filled and Physical_Send as long as everything has not been
   --  sent.


   function Accept_Connection (Host_And_Port : String) return Socket_Type;
   procedure Accept_Connection (Host_And_Port : String;
                                Port : in out Natural;
                                Fd : out Socket_Type;
                                Client : out Positive);
   --
   --  RECEIVING
   --  Initializes listening port and accepts connections.
   --  The string is in format Host:Port. Host part is ignored because it
   --  must be a Receiver (localhost) name anyways.
   --  In 2nd variation, Port overrides Host_And_Port if not set to 0
   --                    Client returns the calling subnet address

   function Establish_Connection (Host_And_Port : String) return Socket_Type;
   --
   --  SENDING
   --  Establish a socket to a remote location and return the file descriptor.
   --  The string is in format Host:Port

   Communication_Error : exception;


   procedure Shutdown (Fd : in Socket_Type);


   --
   -- String Oriented Socket calls
   --

   function Get_Line (Socket : Socket_Type;
                      Delimiter : Character := ASCII.LF) return String;

   procedure Put_Line (Socket : in Socket_Type; Str : in String);
   procedure Put (Socket : in Socket_Type; Str : in String);

   procedure New_Line (Socket : in Socket_Type; Count : in Natural := 1);


   --
   -- Stream oriented socket calls from external buffer stream
   --

   function Stream_Receive
     (Socket : in Socket_Type; Stream : in Pace.Stream.Data_Access)
      return Boolean;

   function Stream_Receive
     (Socket : in Socket_Type; Stream : in Pace.Stream.Data_Access)
      return Integer;
   -- Returns the size if needed, useful for redirecting stream

   function Stream_Send (Socket : in Socket_Type;
                         Stream : in Pace.Stream.Data_Access;
                         Stream_Size : Integer := 0) return Boolean;
   -- Stream_Size is useful for redirecting received stream

   --
   --  Stream Oriented Socket calls from raw 'read and 'write
   --

   type Socket_Stream_Type is new Ada.Streams.Root_Stream_Type with private;
   type Socket_Stream is access all Socket_Stream_Type;

   procedure New_Socket_Stream
     (Stream : in out Socket_Stream; Socket : in Socket_Type);


   --
   --  Creating a port handler. This returns a unique port number that can
   --  be used in a server Accept_Connection. However, clients can only be
   --  informed of this value through an additional separate Name Service.
   --
   function Create_Port_Handler return Positive;

   --
   -- Command patterns, used with homogeneous platforms
   --
   function Command_Receive (Fd : in Socket_Type) return Msg'Class ;
   procedure Command_Send (Fd : in Socket_Type;
                           Obj : in Msg'Class);
 
private

   type Socket_Stream_Type is new Ada.Streams.Root_Stream_Type with
      record
         S : Socket_Type := 0;
      end record;

   procedure Read (Stream : in out Socket_Stream_Type;
                   Item : out Ada.Streams.Stream_Element_Array;
                   Last : out Ada.Streams.Stream_Element_Offset);

   procedure Write (Stream : in out Socket_Stream_Type;
                    Item : in Ada.Streams.Stream_Element_Array);

   ------------------------------------------------------------------------------
   -- $Id: pace-tcp.ads,v 1.4 2006/07/03 16:48:27 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Tcp;
