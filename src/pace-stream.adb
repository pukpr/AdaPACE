with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Ada.Characters.Handling;

package body Pace.Stream is

   No_Swap : constant Boolean := System."=" (System.Default_Bit_Order, System.High_Order_First) or
                                 Pace.Getenv ("NO_BYTE_SWAP", 0) = 1;

   procedure Free is new Ada.Unchecked_Deallocation
     (As.Stream_Element_Array, Storage_Access);

   procedure Scale_Storage (Store : in out Storage_Access;
                            Size : in out As.Stream_Element_Offset;
                            Scale : in As.Stream_Element_Offset) is
      New_Size : As.Stream_Element_Offset;
      New_Store : Storage_Access;
      use type As.Stream_Element_Offset;
   begin
      New_Size := Size * Scale;
      New_Store := new As.Stream_Element_Array (1 .. New_Size);
      New_Store (1 .. Size) := Store.all;
      Free (Store);
      Store := New_Store;
      Size := New_Size;
   end Scale_Storage;

   procedure Reset_Data (Data : in Data_Access) is
      M : Data_Stream renames Data_Stream (Data.all);
   begin
      M.Current := 1;
   end Reset_Data;

   function Data_Size (Data : in Data_Access) return Storage_Range is
      M : Data_Stream renames Data_Stream (Data.all);
      use type As.Stream_Element_Offset;
   begin
      return M.Last - 1;
   end Data_Size;

   function Data_Storage (Data : in Data_Access) return Storage_Access is
      M : Data_Stream renames Data_Stream (Data.all);
   begin
      return M.Store;
   end Data_Storage;

   function Data_Address (Data : in Data_Access; Size_In_Bytes : in Integer)
                          return System.Address is
      M : Data_Stream renames Data_Stream (Data.all);
   begin
      if Size_In_Bytes > Integer (M.Size) then
         Scale_Storage (M.Store, M.Size,
                        As.Stream_Element_Offset
                        (Size_In_Bytes / Integer (M.Size) + 1));
      end if;
      return M.Store.all'Address;
   end Data_Address;

   function Show_Header (Data : in Data_Access; Number : in Integer := 100) return String is
      M : Data_Stream renames Data_Stream (Data.all);
      Str : String(1..Number);
      for Str'Address use M.Store.all'Address;
   begin
      return Ada.Characters.Handling.To_Basic (Str);
   end;

   pragma Suppress (All_Checks);
   -- Need to make the stream transfer as efficient as possible

   procedure Write (Stream : in out Data_Stream;
                    Item : in As.Stream_Element_Array) is
      use type As.Stream_Element_Offset;
      Index : constant As.Stream_Element_Offset :=
        Stream.Current + Item'Length;
   begin
      while Index > Stream.Size loop
         Scale_Storage (Stream.Store, Stream.Size, 2);
      end loop;
      if No_Swap then
         Stream.Store (Stream.Current .. Index - 1) := Item; -- (Item'Range)
      else -- heterogeneous between transfer Big and Little-Endian hosts
         for i in Item'Range loop
            Stream.Store (Index - i) := Item (i);
         end loop;
      end if;
      Stream.Current := Index;
      Stream.Last := Index;
   end Write;

   procedure Read (Stream : in out Data_Stream;
                   Item : out As.Stream_Element_Array;
                   Last : out As.Stream_Element_Offset) is
      use type As.Stream_Element_Offset;
      Index : constant As.Stream_Element_Offset :=
        Stream.Current + Item'Length;
   begin
      if No_Swap then
         Item := Stream.Store (Stream.Current .. Index - 1); -- (Item'Range)
      else -- heterogeneous between transfer Big and Little-Endian hosts
         for i in Item'Range loop
            Item (i) := Stream.Store (Index - i);
         end loop;
      end if;
      Stream.Current := Index;
      Stream.Last := Index;
      Last := Item'Last;
   end Read;


   function To_Array (Str : String) return As.Stream_Element_Array is
      Sto : As.Stream_Element_Array (1..As.Stream_Element_Offset(Str'Length));
   begin
      for I in Str'Range loop
         Sto(As.Stream_Element_Offset(I)) := As.Stream_Element(Character'Pos(Str(I)));
      end loop;
      return Sto;
   end;

   function To_String (Sto : As.Stream_Element_Array) return String is
      Str : String (1..Integer(Sto'Length));
   begin
      for I in Sto'Range loop
         Str(Integer(I)) := Character'Val (Integer(Sto(I)));
      end loop;
      return Str;
   end;


   function Get_Array (Data : in Data_Access) return As.Stream_Element_Array is
   begin
      return Data_Storage (Data).all(1..Data_Size(Data));
   end;

   procedure Set_Array (Data : in Data_Access;
                        Store : in As.Stream_Element_Array) is
   begin
      -- May want to check to resize this just in case
      --         if Size_In_Bytes > Integer (M.Size) then
      --             Scale_Storage (M.Store, M.Size,
      --                            As.Stream_Element_Offset
      --                               (Size_In_Bytes / Integer (M.Size) + 1));
      --         end if;
      Data.Store(1..Store'Length) := Store;
      Data.Current := 1;
      Data.Last := Store'Length;
   end;

   procedure Inout_Protocol (Obj : in out Pace.Msg'Class) is
   begin
      Obj.Enum := Two_Way;
   end Inout_Protocol;

   package body Text is
      function To_Character is new Ada.Unchecked_Conversion (
         Stream_Element,
         Character);
      function From_Character is new Ada.Unchecked_Conversion (
         Character,
         Stream_Element);
      procedure Read
        (Stream : access Root_Stream_Type'Class;
         Item   : out Msg)
      is
         S     : Stream_Element_Array (1 .. Buffer_Size);
         L     : Stream_Element_Offset;
         Index : Integer := 0;
         Ch    : Character;
         Text  : String (1 .. Integer (Buffer_Size));
      begin
         Read (Stream.all, S, L);
         for I in  1 .. L loop
            Ch           := To_Character (S (I));
            Index        := Index + 1;
            Text (Index) := Ch;
         end loop;
         From_String (Text (1 .. Index), Model_Msg (Item));
      end Read;

      procedure Write
        (Stream : access Root_Stream_Type'Class;
         Item   : in Msg)
      is
         Str   : constant String       := To_String (Model_Msg (Item));
         S     : Stream_Element_Array (
            1 .. Stream_Element_Offset (Str'Length));
         Index : Stream_Element_Offset := 0;
      begin
         for I in  Str'Range loop
            Index     := Index + 1;
            S (Index) := From_Character (Str (I));
         end loop;
         Write (Stream.all, S);
      end Write;
   end Text;

   -- Fast
   package body Binary is
      subtype S_Msg is Stream_Element_Array (
         1 .. Stream_Element_Offset (Msg'Size / 8));
      function To_Msg is new Ada.Unchecked_Conversion (S_Msg, Msg);
      function From_Msg is new Ada.Unchecked_Conversion (Msg, S_Msg);

      procedure Read
        (Stream : access Root_Stream_Type'Class;
         Item   : out Msg)
      is
         T : S_Msg;
         L : Stream_Element_Offset;
      begin
         Read (Stream.all, T, L);
         Item := To_Msg (T);
      end Read;

      procedure Write
        (Stream : access Root_Stream_Type'Class;
         Item   : in Msg)
      is
      begin
         Write (Stream.all, From_Msg (Item));
      end Write;
   end Binary;

   package body Binary_Array is

      procedure Read
        (Stream : access Root_Stream_Type'Class;
         Item   : out Buffer)
      is
         Size : constant Integer := Item'Size / 8;
         subtype S_Buffer is Stream_Element_Array (
            1 .. Stream_Element_Offset (Size));
         subtype C_Buffer is Buffer (Item'Range);
         function To_Buffer is new Ada.Unchecked_Conversion (
            S_Buffer,
            C_Buffer);
         T : S_Buffer;
         L : Stream_Element_Offset;
      begin
         Read (Stream.all, T, L);
         Item := To_Buffer (T);
      end Read;

      procedure Write
        (Stream : access Root_Stream_Type'Class;
         Item   : in Buffer)
      is
         Size : constant Integer := Item'Size / 8;
         subtype S_Buffer is Stream_Element_Array (
            1 .. Stream_Element_Offset (Size));
         subtype C_Buffer is Buffer (Item'Range);
         function From_Buffer is new Ada.Unchecked_Conversion (
            C_Buffer,
            S_Buffer);
      begin
         Write (Stream.all, From_Buffer (Item));
      end Write;

   end Binary_Array;

----------------------------------------------------------------------------
----------------------------------------------------------------------------
end Pace.Stream;
