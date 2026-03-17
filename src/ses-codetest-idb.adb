with Unchecked_Conversion;
with Text_Io;
with Ada.Strings.Fixed;
with Ada.Exceptions;

package body Ses.Codetest.Idb is
   package Int_Io is new Text_Io.Integer_Io (Integer);

   Idb_Extension : constant String := ".idb";

   function To_Tag_Overlay is new Unchecked_Conversion (Integer, Tag_Overlay);
   function To_Integer is new Unchecked_Conversion (Low_High, Integer);

   procedure Translate (Timing : in String;
                        Code_Index : out Integer;
                        Seconds : out Float) is
      Data : Tag_Overlay := To_Tag_Overlay (Integer'Value (Timing));
   begin
      Code_Index := Integer (Data.Address);
      Seconds := Float'Compose (Float (Data.Fraction) / Scale,
                                Integer (Data.Exponent));
   end Translate;

   function Translate (Low, High : Interfaces.Unsigned_16) return String is
      Scope : constant Low_High := (Low, High);
   begin
      return Integer'Image (To_Integer (Scope));
   end Translate;

   procedure Read_Idb (Table : out Index_Lookup;
                       Prefix : in String := "codetest") is
      S : String (1 .. 1000);
      Idb : constant String := Prefix & Idb_Extension;
      L, Last : Integer;
      File : Text_Io.File_Type;
      Start : Boolean := False;
      Loc : Integer := 0;
      use Ada.Strings.Unbounded;
   begin
      Int_Io.Default_Base := 16;
      Text_Io.Put_Line (Text_IO.Current_Error, "Opening " & Idb);
      Text_Io.Open (File, Text_Io.In_File, Idb);
      Text_Io.Put_Line (Text_IO.Current_Error, "Opened " & Idb);
      while not Text_Io.End_Of_File (File) loop
         Text_Io.Get_Line (File, S, L);
         exit when S (1 .. 9) = "%%ENTRIES";
         if Start and then S (1) = '%' then
            declare
               V : String :=
                 "16#" & S (2 .. Ada.Strings.Fixed.Index (S, " ") - 1) & "#";
            begin
               Int_Io.Get (V, Loc, Last);
            end;
            Text_Io.Get_Line (File, S, L);
            Text_Io.Get_Line (File, S, L);
            Table (Loc) := To_Unbounded_String (S (1 .. L));
         end if;
         if S (1 .. 11) = "%%FUNCTIONS" then
            Start := True;
         elsif S (1 .. 10) = "%%COVERAGE" then
            Start := False;
         end if;
      end loop;
      -- Fill in #Index on empties
      for I in Table'Range loop
         if Table (I) = Null_Unbounded_String then
            Table (I) := To_Unbounded_String ("#" & Integer'Image (I));
         end if;
      end loop;
   exception
      when Text_Io.Name_Error =>
         Text_Io.Put_Line (Text_IO.Current_Error, 
                           Idb &
                           " file not found, no codetest data available.");
      when E: others =>
         Text_Io.Put_Line (Text_IO.Current_Error,
                           "Cannot process ./codetest.idb at" &
                           Integer'Image (Loc) & " " &
                           Ada.Exceptions.Exception_Information (E));
   end Read_Idb;

   function Get (Table : in Index_Lookup; Index : in Integer) return String is
      use Ada.Strings.Unbounded;
   begin
      return To_String (Table (Index));
   end Get;

end Ses.Codetest.Idb;
