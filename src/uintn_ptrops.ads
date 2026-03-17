with Interfaces.C.Pointers;
generic
   type The_Element is mod <>;
   type The_Element_Array is
     array (Interfaces.C.Size_T range <>) of aliased The_Element;
package Uintn_Ptrops is
   package C renames Interfaces.C;

   package Operations is new Interfaces.C.Pointers
                               (Index => Interfaces.C.Size_T,
                                Element => The_Element,
                                Element_Array => The_Element_Array,
                                Default_Terminator => 0);

   subtype Pointer is Operations.Pointer;

   function Value (Ref : in Pointer; Terminator : in The_Element)
                  return The_Element_Array renames Operations.Value;

   function Value (Ref : in Pointer; Length : in C.Ptrdiff_T)
                  return The_Element_Array renames Operations.Value;

   --------------------------------
   -- C-style Pointer Arithmetic --
   --------------------------------

   function "+" (Left : in Pointer; Right : in C.Ptrdiff_T) return Pointer
     renames Operations."+";
   function "+" (Left : in C.Ptrdiff_T; Right : in Pointer) return Pointer
     renames Operations."+";
   function "-" (Left : in Pointer; Right : in C.Ptrdiff_T) return Pointer
     renames Operations."-";
   function "-" (Left : in Pointer; Right : in Pointer) return C.Ptrdiff_T
     renames Operations."-";

   procedure Increment (Ref : in out Pointer) renames Operations.Increment;
   procedure Decrement (Ref : in out Pointer) renames Operations.Increment;

   function Virtual_Length (Ref : in Pointer; Terminator : in The_Element := 0)
                           return C.Ptrdiff_T renames Operations.Virtual_Length;

   procedure Copy_Terminated_Array (Source : in Pointer;
                                    Target : in Pointer;
                                    Limit : in C.Ptrdiff_T := C.Ptrdiff_T'Last;
                                    Terminator : in The_Element := 0)
     renames Operations.Copy_Terminated_Array;

   procedure Copy_Array (Source : in Pointer;
                         Target : in Pointer;
                         Length : in C.Ptrdiff_T) renames Operations.Copy_Array;

end Uintn_Ptrops;

