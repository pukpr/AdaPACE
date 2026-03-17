with Ada.Strings.Unbounded;

package Ses.Codetest.Idb is

   pragma Elaborate_Body;

   -- Translates stored value to a CodeTest instrumented index + call time
   procedure Translate (Timing : in String;
                        Code_Index : out Integer;
                        Seconds : out Float);

   function Translate (Low, High : Interfaces.Unsigned_16) return String;

   type Index_Lookup is array (Positive range <>) of
                          Ada.Strings.Unbounded.Unbounded_String;

   procedure Read_Idb (Table : out Index_Lookup;
                       Prefix : in String := "codetest");
   function Get (Table : in Index_Lookup; Index : in Integer) return String;

end Ses.Codetest.Idb;
