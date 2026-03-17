
--------------------------------------------------------------------------------
-- Implementation of a thick Ada binding to the UNIX popen and pclose
-- commands
--------------------------------------------------------------------------------

with Interfaces.C;
with Ada.Characters.Latin_1;
with Ada.Numerics.Discrete_Random;

package body Gnu.Pipe_Commands is

   use Interfaces.C;
   Lf : constant Interfaces.C_Streams.Int :=
     Character'Pos (Ada.Characters.Latin_1.Lf); -- Unix end of line

   package Ran is new Ada.Numerics.Discrete_Random (Positive);
   G : Ran.Generator;

   function Popen (Command : Char_Array; Mode : Char_Array) return Files;
   pragma Import (C, Popen);

   function Pclose (Filestream : Files) return Interfaces.C_Streams.Int;
   pragma Import (C, Pclose);

   function Fopen (Command : Char_Array; Mode : Char_Array) return Files;
   pragma Import (C, Fopen);

   procedure Mkfifo (Command : Char_Array; Mode : Integer);
   pragma Import (C, Mkfifo);

   procedure Remove (Command : Char_Array);
   pragma Import (C, Remove);

   function Execute (Command : in String; Io_Type : in Io_Mode) return Stream is
      Result : Stream;
      Tmp : constant String := "/tmp/pipe" & Integer'Image (-Ran.Random (G));
   begin
      case Io_Type is
         when Read_File =>
            Result.Filestream_Read := Popen (To_C (Command), To_C ("r"));
         when Write_File =>
            Result.Filestream_Write := Popen (To_C (Command), To_C ("w"));
         when Rw_File =>
            Mkfifo (To_C (Tmp), 8#0666#);
            Result.Filestream_Write :=
              Popen (To_C (Command & " > " & Tmp), To_C ("w"));
            Result.Filestream_Read := Fopen (To_C (Tmp), To_C ("r"));
            Result.Fifo := To_Unbounded_String (Tmp);
      end case;
      Result.Mode := Io_Type;
      return Result;
   end Execute;

   Buflen : constant := 500;  -- smaller values require more recursion

   function Read_Next (Fromfile : in Stream) return String is
--      Result : Unbounded_String := Null_Unbounded_String;
      Char_Buf : Interfaces.C_Streams.Int;
      Temp : Character;

      function Get_Line return String;

      function Get_Line return String is
         Buffer : String (1 .. Buflen);
--         C : Character;
--         Val : Integer;
      begin
         for Nstore in Buffer'Range loop
            Char_Buf := Fgetc (Fromfile.Filestream_Read);
            if Char_Buf = Eof then
               raise End_Of_File;
            end if;
            Temp := Character'Val (Char_Buf);
            if Temp = Ascii.Lf then
               return Buffer (1 .. Nstore - 1);
            else
               Buffer (Nstore) := Temp;
            end if;
         end loop;
         return Buffer & Get_Line;
      end Get_Line;

   begin
      if Fromfile.Mode = Write_File then
         raise Access_Error;
      end if;
      return Get_Line;
--       loop
--          Char_Buf := Fgetc (Fromfile.Filestream_Read);
--          if Char_Buf = Eof then
--             raise End_Of_File;
--          end if;
--          exit when Char_Buf = Lf; -- end of line?
--          Temp := Character'Val (Char_Buf);
--          Result := Result & Temp;
--       end loop;
--      return Result;
   end Read_Next;


   function Read_All (Fromfile : in Stream) return String is
      Char_Buf : Interfaces.C_Streams.Int;

      function Get_All return String;

      function Get_All return String is
         Buffer : String (1 .. Buflen);
      begin
         for Nstore in Buffer'Range loop
            Char_Buf := Fgetc (Fromfile.Filestream_Read);
            if Char_Buf = Eof then
               return Buffer (1 .. Nstore - 1);
            else
               Buffer (Nstore) := Character'Val (Char_Buf);
            end if;
         end loop;
         return Buffer & Get_All;
      end Get_All;

   begin
      if Fromfile.Mode = Write_File then
         raise Access_Error;
      end if;
      return Get_All;
   end Read_All;


   procedure Write (Tofile : in Stream; Message : in String) is
      Rc : Interfaces.C_Streams.Int;
   begin
      if Tofile.Mode = Read_File then
         raise Access_Error;
      end if;
      for I in Message'Range loop
         Rc := Fputc (Character'Pos (Message (I)), Tofile.Filestream_Write);
      end loop;
   end Write;

   procedure Write_Next (Tofile : in Stream; Message : in String) is
      Rc : Interfaces.C_Streams.Int;
   begin
      Write (Tofile, Message);
      Rc := Fputc (Lf, Tofile.Filestream_Write); -- add end of line
   end Write_Next;

   procedure Flush_Pipe (Tofile : in Stream) is
      Rc : Interfaces.C_Streams.Int;
   begin
      if Tofile.Mode = Read_File then
         raise Access_Error;
      end if;
      Rc := Fflush (Tofile.Filestream_Write);
   end Flush_Pipe;


   procedure Close (Openfile : in Stream) is
      Rc : Interfaces.C_Streams.Int;
   begin
      if Openfile.Mode = Read_File then
         Rc := Pclose (Openfile.Filestream_Read);
      elsif Openfile.Mode = Read_File then
         Rc := Pclose (Openfile.Filestream_Write);
      else
         Rc := Pclose (Openfile.Filestream_Write);
         Rc := Fclose (Openfile.Filestream_Read);
         Remove (To_C (To_String (Openfile.Fifo)));
      end if;
   end Close;

begin
   Ran.Reset (G);

end Gnu.Pipe_Commands;

