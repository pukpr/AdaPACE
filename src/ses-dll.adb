with Interfaces.C.Strings;
with Ada.Unchecked_Conversion;

package body Ses.Dll is

   pragma Linker_Options ("-ldl");

   -- Map UNIX-style dynamic-library functions to ada routines

   function Dlopen
     (Lib_Name : Interfaces.C.Strings.chars_ptr;
      Mode     : Interfaces.C.int)
      return     System.Address;
   pragma Import (C, Dlopen, "dlopen");

   function Dlsym
     (Handle   : System.Address;
      Sym_name : Interfaces.C.Strings.chars_ptr)
      return     System.Address;
   pragma Import (C, Dlsym, "dlsym");

   function Dlclose (Handle : System.Address) return Interfaces.C.int;
   pragma Import (C, Dlclose, "dlclose");

   function Dlerror return Interfaces.C.Strings.chars_ptr;
   pragma Import (C, Dlerror, "dlerror");

   function Error (Handle : in Handle_Type) return String is
      C_Str : Interfaces.C.Strings.chars_ptr;
      use type Interfaces.C.Strings.chars_ptr;
   begin
      C_Str := Dlerror;

      if C_Str = Interfaces.C.Strings.Null_Ptr then
         return "";
      else
         return Interfaces.C.Strings.Value (C_Str);
      end if;
   end Error;

   procedure Open
     (Handle : in out Handle_Type;
      Name   : in String;
      Mode   : in Integer := 1)
   is
      Raw_Address : System.Address;
      C_Str       : Interfaces.C.Strings.chars_ptr;
      use type System.Address;
   begin
      C_Str := Interfaces.C.Strings.New_String (Name);

      if Name = "" then
         Raw_Address :=
            Dlopen
              (Lib_Name => Interfaces.C.Strings.Null_Ptr,
               Mode     => Interfaces.C.int (Mode));
      else
         Raw_Address :=
            Dlopen (Lib_Name => C_Str, Mode => Interfaces.C.int (Mode));
      end if;
      Interfaces.C.Strings.Free (C_Str);

      Handle.Os_Handle := Raw_Address;
      if Name /= "" and Raw_Address = System.Null_Address then
         raise Dll_Exception;
      end if;
   end Open;

   procedure Close (Handle : in out Handle_Type) is
      Os_Ret_Code : Interfaces.C.int;
      use type Interfaces.C.int;
   begin
      Os_Ret_Code := Dlclose (Handle.Os_Handle);
      if Os_Ret_Code /= 0 then
         raise Dll_Exception;
      end if;
   end Close;

   procedure Sym
     (Handle : in out Handle_Type;
      Name   : in String;
      Item   : out Item_Type)
   is
      function Address_To_Access is new Ada.Unchecked_Conversion (
         Source => System.Address,
         Target => Item_Type);
      Raw_Address : System.Address;
      C_Str       : Interfaces.C.Strings.chars_ptr;
      use type System.Address;
   begin
      C_Str := Interfaces.C.Strings.New_String (Name);

      Raw_Address := Dlsym (Handle => Handle.Os_Handle, Sym_name => C_Str);

      Interfaces.C.Strings.Free (C_Str);

      Item := Address_To_Access (Raw_Address);
      if Raw_Address = System.Null_Address then
         raise Dll_Exception;
      end if;
   end Sym;

   function Symbol
     (Handle : in Handle_Type;
      Name   : in String)
      return   System.Address
   is
      Raw_Address : System.Address;
      C_Str       : Interfaces.C.Strings.chars_ptr;
      use type System.Address;
   begin
      C_Str := Interfaces.C.Strings.New_String (Name);

      Raw_Address := Dlsym (Handle => Handle.Os_Handle, Sym_name => C_Str);

      Interfaces.C.Strings.Free (C_Str);

      if Raw_Address = System.Null_Address then
         raise Dll_Exception;
      end if;
      return Raw_Address;
   end Symbol;

end Ses.Dll;
