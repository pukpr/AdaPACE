with Ada.Streams;
with System;
package Pace.Stream is
   pragma Elaborate_Body;

   --------------------------------------------------------
   -- STREAM -- Streamable input/output to pre-alloc store
   --------------------------------------------------------
   -- DATA_STREAM and DATA_ACCESS are stream and stream pointer to storage.
   -- RESET_DATA unwinds the stream.
   -- Example:
   --
   --   Data : Data_Access := new Data_Stream;
   --
   --    -- Writing to data stream
   --   INTEGER'Write (Data, 10);
   --
   --    -- Reading from the stream
   --   INTEGER'Read (Data, Value); -- Value is a variable of integer type
   --
   -- NOTE: Careful sequencing of input and output streams is required.
   pragma Elaborate_Body;

   package As renames Ada.Streams;

   -----------------
   -- Data_Stream -- Streamable Storage
   -----------------
   type Data_Stream is new As.Root_Stream_Type with private;

   procedure Read (Stream : in out Data_Stream;
                   Item : out As.Stream_Element_Array;
                   Last : out As.Stream_Element_Offset);
   procedure Write (Stream : in out Data_Stream;
                    Item : in As.Stream_Element_Array);

   -----------------
   -- Data_Access -- Pointer to Data_Stream
   -----------------
   type Data_Access is access all Data_Stream'Class;

   procedure Reset_Data (Data : in Data_Access);
   --
   -- Reset the stream for new data

   subtype Storage_Range is As.Stream_Element_Offset;
   function Data_Size (Data : in Data_Access) return Storage_Range;
   --
   -- Returns the data storage size

   type Storage_Access is access As.Stream_Element_Array;
   function Data_Storage (Data : in Data_Access) return Storage_Access;
   --
   -- Returns the pointer to data storage array

   function Data_Address (Data : in Data_Access; Size_In_Bytes : in Integer)
                          return System.Address;
   --
   -- Overlaying storage area for raw reads and writes.
   -- This gets resized if current storage is too small.


   -- Functions for use when overlaying data is not practical
   function To_Array (Str : String) return As.Stream_Element_Array;
   function To_String (Sto : As.Stream_Element_Array) return String;

   function Get_Array (Data : in Data_Access) return As.Stream_Element_Array;
   procedure Set_Array (Data : in Data_Access;
                        Store : in As.Stream_Element_Array);


   -- For debugging
   function Show_Header (Data : in Data_Access; Number : in Integer := 100) return String;

   --  Command patterns

   procedure Inout_Protocol (Obj : in out Pace.Msg'Class);

   generic
      type Model_Msg is new Pace.Msg with private;
      with function To_String (Item : in Model_Msg) return String;
      with procedure From_String (Text : in String; Obj : out Model_Msg);
      Buffer_Size : in Ada.Streams.Stream_Element_Offset := 1000;
   package Text is
      -----------------------------------------------------------
      -- TEXT -- Construct/deconstruct a character string stream
      -----------------------------------------------------------
      -- Allows interfacing to non-Ada entities.
      --
      -- FOR sockets the following applies (all integers in network byte order)
      --  The first data sent is the size of the actual message:
      --     Integer = Size of message in bytes
      --  The delivered class'wide stream message is defined as follows :
      --     Integer = 1
      --     Integer = Size of External Tag in number of characters
      --     String  = EXTERNAL_TAG (e.g. Pace.MSG)
      --     String  = Text data

      type Msg is new Model_Msg with null record;

   private
      use Ada.Streams;
      procedure Read
        (Stream : access Root_Stream_Type'Class;
         Item   : out Msg);
      for Msg'Read use Read;

      procedure Write
        (Stream : access Root_Stream_Type'Class;
         Item   : in Msg);
      for Msg'Write use Write;

   end Text;

   generic
      type Model_Msg is new Pace.Msg with private;
   package Binary is
      --------------------------------------------------------
      -- BINARY -- Unchecked conversion to a stream message
      --------------------------------------------------------
      -- This is fast but will not construct pointers, XDR reps, etc.

      type Msg is new Model_Msg with null record;

   private
      use Ada.Streams;
      procedure Read
        (Stream : access Root_Stream_Type'Class;
         Item   : out Msg);
      for Msg'Read use Read;

      procedure Write
        (Stream : access Root_Stream_Type'Class;
         Item   : in Msg);
      for Msg'Write use Write;
   end Binary;

   generic
      type Element is private;
   package Binary_Array is

      type Buffer is array (Integer range <>) of Element;

   private
      use Ada.Streams;

      --Buffer
      procedure Read
        (Stream : access Root_Stream_Type'Class;
         Item   : out Buffer);
      for Buffer'Read use Read;

      procedure Write
        (Stream : access Root_Stream_Type'Class;
         Item   : in Buffer);
      for Buffer'Write use Write;

   end Binary_Array;


private

   Initial_Size : constant As.Stream_Element_Offset := 8192;

   type Data_Stream is new As.Root_Stream_Type with
      record
         Store : Storage_Access :=
          new As.Stream_Element_Array (1 .. Initial_Size);
         Size : As.Stream_Element_Offset := Initial_Size;
         Last : As.Stream_Element_Offset := 1;
         Current : As.Stream_Element_Offset := 1;
      end record;

----------------------------------------------------------------------------
----------------------------------------------------------------------------
end Pace.Stream;
