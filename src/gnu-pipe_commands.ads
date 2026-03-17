with Interfaces.C_Streams;
with Ada.Strings.Unbounded;

package Gnu.Pipe_Commands is

   --------------------------------------------------------------------------------
   -- .Pipe_Commands : UNIX popen and pclose commands
   --------------------------------------------------------------------------------

   use Interfaces.C_Streams;
   use Ada.Strings.Unbounded;

   type Stream is private;

   type Io_Mode is (Read_File, Write_File, Rw_File);

   function Execute (Command : in String; Io_Type : in Io_Mode) return Stream;

   function Read_Next (Fromfile : in Stream) return String;
   function Read_All (Fromfile : in Stream) return String;

   procedure Write (Tofile : in Stream; Message : in String); -- No CRLF
   procedure Write_Next (Tofile : in Stream; Message : in String);

   procedure Flush_Pipe (Tofile : in Stream);

   procedure Close (Openfile : in Stream);

   Access_Error : exception; -- Raised when attempt is made to violate IO_MODE
   End_Of_File : exception; -- Raised on detection of End_of_file during read

private

   type Stream is
      record
         Filestream_Read : Files;
         Filestream_Write : Files;
         Mode : Io_Mode;
         Fifo : Unbounded_String;
      end record;

end Gnu.Pipe_Commands;
