
package body Sdl.Types is

   --  ===================================================================
   --  generic
   --     type Data_Type is private;
   --     type Amount_Type is private;
   --  function Shift_Left (
   --     Data : Data_Type;
   --     Amount : Amount_Type) return Data_Type;

   --  function Shift_Left (
   --     Value : Value_Type;
   --     Amount : Amount_Type) return Data_Type
   --  is
   --     use Interfaces;
   --  begin
   --     return Uint8 (Shift_Left (Unsigned_8 (Value), Amount));
   --  end Shift_Left;

   --  ===================================================================
   function Shift_Left (Value : Uint8; Amount : Integer) return Uint8 is
      use Interfaces;
   begin
      return Uint8 (Shift_Left (Unsigned_8 (Value), Amount));
   end Shift_Left;


   --  ===================================================================
   function Shift_Right (Value : Uint8; Amount : Integer) return Uint8 is
      use Interfaces;
   begin
      return Uint8 (Shift_Right (Unsigned_8 (Value), Amount));
   end Shift_Right;

   --  ===================================================================
   function Shift_Left (Value : Uint16; Amount : Integer) return Uint16 is
      use Interfaces;
   begin
      return Uint16 (Shift_Left (Unsigned_16 (Value), Amount));
   end Shift_Left;


   --  ===================================================================
   function Shift_Right (Value : Uint16; Amount : Integer) return Uint16 is
      use Interfaces;
   begin
      return Uint16 (Shift_Right (Unsigned_16 (Value), Amount));
   end Shift_Right;

   --  ===================================================================
   function Shift_Left (Value : Uint32; Amount : Integer) return Uint32 is
      use Interfaces;
   begin
      return Uint32 (Shift_Left (Unsigned_32 (Value), Amount));
   end Shift_Left;


   --  ===================================================================
   function Shift_Right (Value : Uint32; Amount : Integer) return Uint32 is
      use Interfaces;
   begin
      return Uint32 (Shift_Right (Unsigned_32 (Value), Amount));
   end Shift_Right;

   --  ===================================================================
   function Increment (Pointer : Uint8_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint8_Ptrs.Object_Pointer is
      use Uint8_Ptrops;
   begin
      return Uint8_Ptrs.Object_Pointer
               (Uint8_Ptrops.Pointer (Pointer) + C.Ptrdiff_T (Amount));
   end Increment;

   --  ===================================================================
   function Decrement (Pointer : Uint8_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint8_Ptrs.Object_Pointer is
      use Uint8_Ptrops;
   begin
      return Uint8_Ptrs.Object_Pointer
               (Uint8_Ptrops.Pointer (Pointer) - C.Ptrdiff_T (Amount));
   end Decrement;

   --  ===================================================================
   function Increment (Pointer : Uint16_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint16_Ptrs.Object_Pointer is
      use Uint16_Ptrops;
   begin
      return Uint16_Ptrs.Object_Pointer
               (Uint16_Ptrops.Pointer (Pointer) + C.Ptrdiff_T (Amount));
   end Increment;

   --  ===================================================================
   function Decrement (Pointer : Uint16_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint16_Ptrs.Object_Pointer is
      use Uint16_Ptrops;
   begin
      return Uint16_Ptrs.Object_Pointer
               (Uint16_Ptrops.Pointer (Pointer) - C.Ptrdiff_T (Amount));
   end Decrement;

   --  ===================================================================
   function Increment (Pointer : Uint32_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint32_Ptrs.Object_Pointer is
      use Uint32_Ptrops;
   begin
      return Uint32_Ptrs.Object_Pointer
               (Uint32_Ptrops.Pointer (Pointer) + C.Ptrdiff_T (Amount));
   end Increment;

   --  ===================================================================
   function Decrement (Pointer : Uint32_Ptrs.Object_Pointer; Amount : Natural)
                      return Uint32_Ptrs.Object_Pointer is
      use Uint32_Ptrops;
   begin
      return Uint32_Ptrs.Object_Pointer
               (Uint32_Ptrops.Pointer (Pointer) - C.Ptrdiff_T (Amount));
   end Decrement;

   --  ===================================================================
   procedure Copy_Array (Source : Uint8_Ptrs.Object_Pointer;
                         Target : Uint8_Ptrs.Object_Pointer;
                         Lenght : Natural) is
   begin
      Uint8_Ptrops.Copy_Array
        (Uint8_Ptrops.Pointer (Source),
         Uint8_Ptrops.Pointer (Target), C.Ptrdiff_T (Lenght));
   end Copy_Array;

   --  ===================================================================
end Sdl.Types;
