with Ada.Strings.Fixed;
with Ada.Characters.Handling;

separate (Pace.Server)
package body Parameters is

   package Characters is
      ------------------------------------------------------------
      -- CHARACTERS -- CGI encoding/decoding
      ------------------------------------------------------------
      -- In order to pass special characters (especially HTML code) within
      -- CGI parameters, it is encoded. There does not appear to be much
      -- standardization, so these utilities do what works. This prevents
      -- special delimeters from being confused as formatting commands.

      function Decode (Encoded : in String) return String;
      function Encode (Html : in String) return String;

      ----------------------------
      -- Special characters may be coded according to the following patterns from
      -- <a href=http://www.utirc.utoronto.ca/HTMLdocs/NewHTML/iso_table.html>a complete table</a>
      -- These are always prefixed with an '&' and end with ';'.
      --
      Quote : constant String := "quot";
      Ampersand : constant String := "amp";
      Less_Than : constant String := "lt";
      Greater_Than : constant String := "gt";

   end Characters;


   type Search_Type is (Bin_Parameter, Key_Parameter,
                        Value_Parameter, Args_Parameter, Method_Parameter);
   type Method_Type is (Post, Get, Unknown);

   function Parse_Cgi
              (Input : in String; Key : in String; Value : in Boolean := True)
              return String is

      function Field_End
                 (Data : String; Field_Separator : Character) return Natural is
         -- Return the position of first Field_Separator in Data.
         -- If there's no Field_Separator, return Data'Last +1.
      begin
         for Pos in Data'Range loop
            if Data (Pos) = Field_Separator then
               return Pos;
            end if;
         end loop;
         return Data'Last + 1;
      end Field_End;

      function Pick_Value
                 (Datum : in String; Pos : in Positive) return String is
      begin
         return Characters.Decode (Datum (Pos + 1 .. Datum'Last));
      end Pick_Value;

      function Pick_Key (Datum : in String; Pos : in Positive) return String is
      begin
         return Characters.Decode (Datum (Datum'First .. Pos - 1));
      end Pick_Key;

      function Find_Cgi_Data (Input : in String) return String is
         Keys : constant Integer := Ada.Strings.Fixed.Count (Input, "&") + 1;
         Pos : Positive := Input'First;
         Last : Natural;
      begin
         for Key_Number in 1 .. Keys loop
            exit when Pos > Input'Last;

            Last := Field_End (Input (Pos .. Input'Last), '&');
            declare
               Item : constant String := Input (Pos .. Last - 1);
               Pos : constant Natural := Field_End (Item, '=');
               Key_Item : constant String := Pick_Key (Item, Pos);
            begin
               if Key_Item = Key then
                  if Value then
                     return Pick_Value (Item, Pos);
                  else
                     return Key_Item;
                  end if;
               end if;
            end;
            Pos := Last + 1; -- Skip over field separator.
         end loop;
         return "";
      end Find_Cgi_Data;

   begin -- Parse
      if Input = "" then
         return "";
      elsif Ada.Strings.Fixed.Index (Input, "=") = 0 then
         -- No "=" found, so this is an "Isindex" request.
         -- An "Isindex" request is turned into a Key of "isindex" at position 1,
         -- with Value(1) as the actual query.???
         return Find_Cgi_Data ("isindex=" & Input);
      else
         return Find_Cgi_Data (Input);
      end if;
   exception
      when others =>
         return "";
   end Parse_Cgi;


   function Parse (Input : in String;
                   Search : in Search_Type;
                   Key : in String := "") return String is
      Start : Integer := Ada.Strings.Fixed.Index (Input, " ");
      Query : Integer := Ada.Strings.Fixed.Index (Input, "?");
      Stop : Integer := Ada.Strings.Fixed.Index
                          (Input, " ", Ada.Strings.Backward);
      Method : Method_Type;
   begin
      if Input = "" then -- no CGI input available
         return "";
      end if;
      declare
         Mt : constant String := Input (Input'First .. Start - 1);
      begin
         Method := Method_Type'Value (Mt);
      exception
         when others =>
            Pace.Display ("WARNING: Unknown CGI method");
      end;
      if Query = 0 then
         Query := Stop;
      end if;
      case Search is
         when Bin_Parameter =>
            return Input (Start + 1 .. Query - 1);
         when Key_Parameter | Value_Parameter =>
            return Parse_Cgi (Input => Input (Query + 1 .. Stop - 1),
                              Key => Key,
                              Value => Search = Value_Parameter);
         when Args_Parameter =>
            return Characters.Decode (Input (Query + 1 .. Stop - 1));
         when Method_Parameter =>
            return Method_Type'Image(Method);
      end case;
   end Parse;


   function Get_Bin (Query : in String) return String is
   begin
      return Parse (Query, Bin_Parameter);
   end Get_Bin;

   --------------------------------------------------------

   function Is_Index (Query : in String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Query, "=") = 0;
   end Is_Index;


   function Value (Query : in String; Key : in String) return String is
      Output : constant String := Parse (Query, Value_Parameter, Key);
   begin
      if Key = "" then
         return Parse (Query, Args_Parameter, Key);
      elsif Output = "" then
         if Key_Exists (Query, Key) then
            return "";
         else
            raise Constraint_Error;
         end if;
      else
         return Output;
      end if;
   end Value;

   function Key_Exists (Query : in String; Key : in String) return Boolean is
   begin
      return Parse (Query, Key_Parameter, Key) = Key;
   end Key_Exists;

   function Value_Count (Query : in String; Key : in String) return Natural is
   begin
      if Key_Exists (Query, Key) then
         return 1;
      else
         return 0;
      end if;
   end Value_Count;

   function Get_Method (Query : in String) return String is
   begin
      return Parse (Query, Method_Parameter, "");
   end;

   function Create_Query_From_Environment return String is
   begin
      return "GET /?" & Pace.Getenv ("QUERY_STRING", "") & " HTTP/1.0";
   end Create_Query_From_Environment;

-- To do: Add complete parsing.
   package body Characters is

      function To_Decimal (C : in Character) return Natural is
      begin
         case C is
            when '0' .. '9' =>
               return Character'Pos (C) - Character'Pos ('0');
            when 'A' .. 'F' =>
               return Character'Pos (C) - Character'Pos ('A') + 10;
            when 'a' .. 'f' =>
               return Character'Pos (C) - Character'Pos ('a') + 10;
            when others =>
               raise Program_Error;
         end case;
      end To_Decimal;

      function Hex_Value (H : in String) return Character is
         -- Given hex string, return its Value as a Natural.
         Value : Natural := 0;
      begin
         for P in H'Range loop
            Value := Value * 16 + To_Decimal (H (P));
         end loop;

         return Character'Val (Value);
      end Hex_Value;

      Hex_Digit : constant array (0 .. 15) of Character :=
        ('0', '1', '2', '3', '4', '5', '6', '7',
         '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
      function Hex_Image (C : in Character) return String is
         Value : constant Natural := Character'Pos (C);
      begin
         return String'(1 => Hex_Digit (Value / 16),
                        2 => Hex_Digit (Value rem 16));
      end Hex_Image;

      function Decode (Encoded : in String) return String is
         -- Decoding will always shrink the string, so allocate
         -- the result as large as the Encoded string and start
         -- filling it up. Then return the slice of what is used.

         -- To handle the incompatibility between Mosaic and Netscape,
         -- a second pass decodes what Mosaic left.

         -- In the given string, convert pattern %HH into alphanumeric characters,
         -- where HH is a hex number. Since this encoding only permits values
         -- from %00 to %FF, there's no need to handle 16-bit characters.
         Result : String := Encoded;
         Last : Natural := Result'Last;
         Pos : Natural;
         procedure Check_And_Replace
                     (Pattern : in String; -- not including '&' at Pos
                      Char : in Character) is
            Length : constant Natural := Pattern'Length;
         begin
            if (Last - Pos) >= Length and then
               Result (Pos + 1 .. Pos + Length) = Pattern then -- Found!
               Result (Pos) := Char;
               Result (Pos + 1 .. Last - Length) :=
                 Result (Pos + Length + 1 .. Last);
               Last := Last - Length;
            end if;
         end Check_And_Replace;
      begin
         First_Pass: -- Convert + to ' '
            for I in Result'Range loop
               if Result (I) = '+' then
                  Result (I) := ' ';
               end if;
            end loop First_Pass;

         Pos := Result'First;
         Second_Pass: -- Convert Hexadecimal Patterns
            while Pos < Last - 1 loop
               if Result (Pos) = '%' and then
                  Ada.Characters.Handling.Is_Hexadecimal_Digit
                    (Result (Pos + 1)) and then
                  Ada.Characters.Handling.Is_Hexadecimal_Digit
                    (Result (Pos + 2)) then
                  Result (Pos) := Hex_Value (Result (Pos + 1 .. Pos + 2));
                  Result (Pos + 1 .. Last - 2) := Result (Pos + 3 .. Last);
                  Last := Last - 2;
               end if;
               Pos := Pos + 1;
            end loop Second_Pass;

         Pos := Result'First;
         Third_Pass: -- Convert Remaining Patterns
            while Pos < Last - 2 loop
               if Result (Pos) = '&' then
                  Check_And_Replace ("#32;", ' ');
                  Check_And_Replace ("gt;", '>');
                  Check_And_Replace ("quot;", '"');
                  Check_And_Replace ("amp;", '&');
                  Check_And_Replace ("lt;", '<');
               end if;
               Pos := Pos + 1;
            end loop Third_Pass;

         return Result (Result'First .. Last);

      end Decode;

      function Encode (Html : in String) return String is
         -- For Mosaic and Netscape, it is sufficient to encode the following:
         --    Space : constant String := "&#32;";
         Lt : constant String := "&lt;";
         Gt : constant String := "&gt;";
         Quote : constant String := "&quot;";

         -- avoid recursion and lots of special string handling by
         -- going through and counting special characters first to
         -- determine the length of the result. Then allocate the
         -- result string and fill it in.
         Length : Natural := 0;
      begin
         Count_Special_Characters:
            for C in Html'Range loop
               case Html (C) is
                  --        when ' '    => Length := Length + Space'Length;
                  when '<' =>
                     Length := Length + Lt'Length;
                  when '>' =>
                     Length := Length + Gt'Length;
                  when '"' =>
                     Length := Length + Quote'Length;
                  when others =>
                     Length := Length + 1;
               end case;
            end loop Count_Special_Characters;

         Build_Result:
            declare
               Result : String (1 .. Length);
               Cursor : Natural := Result'First;
               procedure Insert (S : in String) is
               begin
                  Result (Cursor .. Cursor + S'Length - 1) := S;
                  Cursor := Cursor + S'Length;
               end Insert;
            begin
               for C in Html'Range loop
                  case Html (C) is
                     --          when ' '    => Insert (Space);
                     when '<' =>
                        Insert (Lt);
                     when '>' =>
                        Insert (Gt);
                     when '"' =>
                        Insert (Quote);
                     when others =>
                        Result (Cursor) := Html (C);
                        Cursor := Cursor + 1;
                  end case;
               end loop;

               return Result;
            end Build_Result;
      end Encode;

   end Characters;

------------------------------------------------------------------------------
-- $id: pace-server-parameters.adb,v 1.4 06/26/2003 22:42:51 pukitepa Exp $
------------------------------------------------------------------------------
end Parameters;
