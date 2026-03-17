------------------------------------------------------------------------
-- PDT/COMPANY:         Performance Management / Global Industrial Solutions
-- SYSTEM/Subsystem:    $view: /prog/shared/modsim/ctd/sim.ss/work/int.wrk $
-- FILE NAME:           $id: ses-pp.adb,v 1.3 12/08/2003 14:42:54 pukitepa Exp
--$
-- HISTORY:             $History: Common $
-- STATISTICS:  $Source_lines: 0 $  $Comment_Lines: 0 $  $Total_lines: 0 $
-- DESIGN NOTES:        Allows basic Peak/Poke on selected types (Expect-like)
-- IMPLEMENTATION NOTES:String type mapped to 128 buffer
-- PORTABILITY ISSUES:  Pure Ada Code, Uses Virtual Address mapping
------------------------------------------------------------------------
with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Calendar;
with Interfaces;
with System.Address_To_Access_Conversions;
with System.Storage_Elements;
with Text_IO;
with Pace.Ses.Dll;
with Pace.Log;

package body Pace.Ses.Pp is

   procedure Error (Symbol, Text : in String) is
   begin
      Text_IO.Put_Line ("SES Peak/Poke ERROR: " & Symbol & " : " & Text);
   end Error;

   type Primitive_Type is (
      Int,
      Flt,
      Bool,
      Char,
      Uint,
      Double,
      Str);

   subtype String_Peek is String (1 .. 128);  -- String buffer for peek/poke

   package Ints is new System.Address_To_Access_Conversions (Integer);
   package Flts is new System.Address_To_Access_Conversions (Float);
   package Bools is new System.Address_To_Access_Conversions (Boolean);
   package Chars is new System.Address_To_Access_Conversions (Character);
   package Doubles is new System.Address_To_Access_Conversions (Long_Float);
   package Strs is new System.Address_To_Access_Conversions (String_Peek);
   package Uints is new System.Address_To_Access_Conversions (
      Interfaces.Unsigned_32);
   package Uio is new Text_IO.Modular_IO (Interfaces.Unsigned_32);

   Handle : Dll.Handle_Type;

   function Raw_Parse
     (SA        : in System.Address;
      Addr, Cmd : in String)
      return      String
   is
      Index : constant Integer := Ada.Strings.Fixed.Index (Cmd, ":");
   begin
      if Index = 0 then
         Text_IO.Put (Addr & " = ");
         case Primitive_Type'Value (Cmd) is
            when Int =>
               return Integer'Image (Ints.To_Pointer (SA).all);
            when Flt =>
               return Float'Image (Flts.To_Pointer (SA).all);
            when Bool =>
               return Boolean'Image (Bools.To_Pointer (SA).all);
            when Char =>
               return Integer'Image
                        (Character'Pos (Chars.To_Pointer (SA).all));
            when Double =>
               return Long_Float'Image (Doubles.To_Pointer (SA).all);
            when Str =>
               return Strs.To_Pointer (SA).all;
            when Uint =>
               declare
                  Str : String (1 .. 13);
               begin
                  Uio.Put (Str, Uints.To_Pointer (SA).all, Base => 16);
                  return Str;
               end;
         end case;
      else
         declare
            Val : constant String (1 .. Cmd'Last - Index) :=
               Cmd (Index + 1 .. Cmd'Last);
         begin
            case Primitive_Type'Value (Cmd (Cmd'First .. Index - 1)) is
               when Int =>
                  Ints.To_Pointer (SA).all := Integer'Value (Val);
               when Flt =>
                  Flts.To_Pointer (SA).all := Float'Value (Val);
               when Bool =>
                  Bools.To_Pointer (SA).all := Boolean'Value (Val);
               when Char =>
                  Chars.To_Pointer (SA).all :=
                     Character'Val (Integer'Value (Val));
               when Double =>
                  Doubles.To_Pointer (SA).all := Long_Float'Value (Val);
               when Str =>
                  Strs.To_Pointer (SA).all (1 .. Val'Last) := Val;
               when Uint =>
                  Uints.To_Pointer (SA).all :=
                     Interfaces.Unsigned_32'Value (Val);
            end case;
            return Addr & " := " & Val;
         end;
      end if;
   end Raw_Parse;

   function Raw_Parse
     (Addr, Cmd : in String)
      return      String is
   begin
      if Addr(Addr'First) = '*' then
         return Raw_Parse (
            Dll.Symbol (Handle, Addr (Addr'First+1 .. Addr'Last)),
            Addr, Cmd);
      else
         return Raw_Parse (
           System.Storage_Elements.To_Address
           (System.Storage_Elements.Integer_Address'Value (Addr)),
            Addr, Cmd);
      end if;
   end;

   procedure Raw_Parse (Addr, Cmd : in String) is
   begin
      Text_IO.Put_Line (Raw_Parse (Addr, Cmd));
   exception
      when Storage_Error =>
         raise;
      when E : others =>
         Error (Addr & " " & Cmd, Ada.Exceptions.Exception_Information (E));
   end Raw_Parse;

   Initialized_Parser : Boolean := False;

   procedure Show_Time is
      Y : Calendar.Year_Number;
      M : Calendar.Month_Number;
      D : Calendar.Day_Number;
      S : Calendar.Day_Duration;
   begin
      Calendar.Split (Calendar.Clock, Y, M, D, S);
      Text_IO.Put_Line
        (Ada.Command_Line.Command_Name &
         " @ " &
         Calendar.Month_Number'Image (M) &
         "/" &
         Calendar.Day_Number'Image (D) &
         "/" &
         Calendar.Year_Number'Image (Y) &
         "/" &
         Calendar.Day_Duration'Image (S));
   end Show_Time;

   function Parser return String is
   begin
      if not Initialized_Parser then
         begin
            Dll.Open (Handle, "", 16#101#); -- RTLD_LAZY|RTLD_GLOBAL
            Dll.Self_Test (Handle);
         exception
            when Dll.Dll_Exception =>
               Text_IO.Put_Line ("WARNING: Can't open dynamically loadable symbol table");
         end;
         Text_IO.Put_Line ("P4 is ready");
         Initialized_Parser := True;
      end if;
      loop
         declare
            Text  : constant String  := Text_IO.Get_Line;  --  Ada 2005
            Index : constant Integer := Ada.Strings.Fixed.Index (Text, " ");
         begin
            if Text = "" then -- Blank gets executable name and time
               Show_Time;
            elsif Text (1) = ASCII.EOT then -- In case End of file sent
               raise Text_IO.End_Error;
            elsif Text (1) = '*' then  -- Use DL
               Raw_Parse(
                  Text (1 .. Index - 1),
                  Text (Index + 1 .. Text'Last));
            elsif Text (1) < '0' or Text (1) > '9' then
               return Text; -- not understood
            else -- Peeking/Poking at Raw memory
               Raw_Parse
                 (Text (1 .. Index - 1),
                  Text (Index + 1 .. Text'Last));
            end if;
            Text_IO.Put_Line (Pace.Ses.Output_Marker);
         exception
            when Text_IO.End_Error | Storage_Error =>
               raise;
            when E : others =>
               Error (Text, Ada.Exceptions.Exception_Information (E));
               return Text;
         end;
      end loop;
   exception
      when Text_IO.End_Error | Storage_Error =>
         raise;
   end Parser;

   procedure Default (Text : in String; Quit : out Boolean) is
   begin
      Quit := False;
   end Default;

   procedure Parser (Serial : Serial_Proc := Default'Access) is
      Quit : Boolean;
   begin
      loop
         Serial (Parser, Quit);
         Text_IO.Put_Line (Pace.Ses.Output_Marker);
         exit when Quit;
      end loop;
   exception
      when Text_IO.End_Error =>
         Text_IO.Put_Line ("SES Peak/Poke raise Text_IO.End_Error");
         raise;
   end Parser;

   task type Parser_Task;
   type Parser_Access is access Parser_Task;
   task body Parser_Task is
   begin
      Parser;
   exception
      when Text_IO.End_Error =>
         Pace.Log.Os_Exit (0);
   end Parser_Task;

   procedure Default_Task is
      Pa : Parser_Access;
   begin
      Pa := new Parser_Task;
   end Default_Task;

end Pace.Ses.Pp;
