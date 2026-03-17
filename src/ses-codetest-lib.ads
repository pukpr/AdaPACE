with Ses.Codetest.Idb;
with Ses.Lib;

package Ses.Codetest.Lib is

   pragma Elaborate_Body;

   function Peek_Image (Pid : in Ses.Lib.Pd;
                        Table : in Ses.Codetest.Idb.Index_Lookup;
                        Pipe_Mode : in Boolean := False) return String;

   type Table_Access is access all Ses.Codetest.Idb.Index_Lookup;
   type Tables is array (Natural range <>) of Table_Access;

   function Peek_Image (P : in Ses.Lib.Processes;
                        T : in Tables;
                        Pipe_Mode : in Boolean := False) return String;

   procedure Poke_Scope (Pid : in Ses.Lib.Pd; Low, High : in Integer);

   Codetest_Error : exception;

end Ses.Codetest.Lib;
