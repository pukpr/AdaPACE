package Ses.Symbols is

   pragma Elaborate_Body;
   -- Loads all Symbol Tables on the Host for sending to the 
   -- Target via a raw address if available

   function Init return Integer;

   function Get_Address (Pid : in Integer; Symval : in String) return String;
   -- SymVal in the form ".symbol" or ".symbol value"
   -- returns 16#XXXXYYYY# type[:value]

   function Get_Symbol (Pid : in Integer; Addr : in String) return String;
   -- Addr in the form 16#XXXXYYYY#
   -- returns "symbol"

end Ses.Symbols;

