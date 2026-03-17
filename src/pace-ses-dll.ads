with System;

package Pace.Ses.Dll is

   pragma Elaborate_Body;

   type Handle_Type is private;

   procedure Open
     (Handle : in out Handle_Type;
      Name   : in String;
      Mode   : in Integer := 0);
   procedure Close (Handle : in out Handle_Type);
   function Error (Handle : in Handle_Type) return String;

   function Symbol
     (Handle : in Handle_Type;
      Name   : in String)
      return   System.Address;

   generic
      type Item_Type is private;
   procedure Sym
     (Handle : in Handle_Type;
      Name   : in String;
      Item   : out Item_Type);

   Dll_Exception : exception;

   procedure Self_Test (Handle : in Handle_Type);

   
private
   type Handle_Type is record
      Os_Handle : System.Address;
   end record;

end Pace.Ses.Dll;
