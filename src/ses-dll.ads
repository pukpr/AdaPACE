with System;

package Ses.Dll is

   type Handle_Type is private;

   procedure Open
     (Handle : in out Handle_Type;
      Name   : in String;
      Mode   : in Integer := 1);
   procedure Close (Handle : in out Handle_Type);
   function Error (Handle : in Handle_Type) return String;

   function Symbol
     (Handle : in Handle_Type;
      Name   : in String)
      return   System.Address;

   generic
      type Item_Type is private;
   procedure Sym
     (Handle : in out Handle_Type;
      Name   : in String;
      Item   : out Item_Type);

   Dll_Exception : exception;

private
   type Handle_Type is record
      Os_Handle : System.Address;
   end record;

end Ses.Dll;
