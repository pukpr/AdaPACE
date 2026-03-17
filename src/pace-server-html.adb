with Ada.Streams.Stream_Io;
with Ada.Strings.Fixed;
--with Pace.Semaphore;
with Pace.Config;

package body Pace.Server.Html is
   generic
      Prefix : in String;
      Suffix : in String;
   function Encase (Text : in String) return String;
   function Encase (Text : in String) return String is
   begin
      return Prefix & Text & Suffix;
   end Encase;

   function Start_Html return String is
   begin
      return "<html>";
   end Start_Html;

   function Head_Imp is new Encase ("<head>", "</head>");
   function Head (Text : in String) return String renames Head_Imp;

   function Title_Imp is new Encase ("<title>", "</title>");
   function Title (Text : in String) return String renames Title_Imp;

   function Start_Body return String is
   begin
      return "<body>";
   end Start_Body;

   generic
      type T is (<>);
      Name : in String;
      Default : in T := T'First;
   function If_Not_Default_Attribute (Value : in T) return String;
   function If_Not_Default_Attribute (Value : in T) return String is
   begin
      if Value /= Default then
         return Name & T'Image (Value);
      else
         return "";
      end if;
   end If_Not_Default_Attribute;

   -- Header --------
   function If_Not_Left is new If_Not_Default_Attribute
                                 (H_Align, " align=", Left);

   function Header (Text : in String;
                    Level : in Natural := 1;
                    Align : in H_Align := Left) return String is
      Hl : String := Natural'Image (Level);
   begin
      Hl (Hl'First) := 'h';
      return '<' & Hl & If_Not_Left (Align) & '>' & Text & "</" & Hl & '>';
   end Header;

   -- Style ---------
   function Bold_Imp is new Encase ("<b>", "</b>");
   function Bold (Text : in String) return String renames Bold_Imp;

   function Italics_Imp is new Encase ("<i>", "</i>");
   function Italics (Text : in String) return String renames Italics_Imp;

   function Paragraph return String is
   begin
      return "<p>";
   end Paragraph;

   -- Definition ----
   function Start_Def_List return String is
   begin
      return "<dl>";
   end Start_Def_List;

   function Define (Term : in String; Definition : in String) return String is
   begin
      return "<dt>" & Term & "<dd>" & Definition;
   end Define;

   function End_Def_List return String is
   begin
      return "</dl>";
   end End_Def_List;


   -- Table ---------
   function Table (Border : in Boolean := False) return String is
   begin
      if Border then
         return "<table border=5>";
      else
         return "<table>";
      end if;
   end Table;

   function Row return String is
   begin
      return "<tr>";
   end Row;

   function If_Not_One (Name : in String; Value : in Natural) return String is
   begin
      if Value /= 1 then
         return ' ' & Name & "=""" & Natural'Image (Value) & '"';
      else
         return "";
      end if;
   end If_Not_One;
   function Table_Header (Text : in String;
                          Span_Row : in Natural := 1;
                          Span_Col : in Natural := 1) return String is
   begin
      return "<th" & If_Not_One ("rowspan", Span_Row) &
               If_Not_One ("colspan", Span_Col) & '>' & Text & "</th>";
   end Table_Header;

   function Cell (Text : in String;
                  Span_Row : in Natural := 1;
                  Span_Col : in Natural := 1) return String is
   begin
      return "<td" & If_Not_One ("rowspan", Span_Row) &
               If_Not_One ("colspan", Span_Col) & '>' & Text & "</td>";
   end Cell;
   function End_Table return String is
   begin
      return "</table>";
   end End_Table;

   function End_Body_Html return String is
   begin
      return "</body></html>";
   end End_Body_Html;

   -- Advanced ---------

   function Put_Options (Options : String) return String is
   begin
      if Options'Length /= 0 then
         --  Don't invoke the special Put defined, as that will
         --  filter out any special chars the user has

         return Options;
      else
         return "";
      end if;
   end Put_Options;


   function Anchor (Href : String; Options : String := No_Options)
                   return String is
   begin
      return "<a href= """ & Href & """ " & Put_Options (Options) & '>';
   end Anchor;

   function Anchor_End return String is
   begin
      return "</a>";
   end Anchor_End;


   function Break return String is
   begin
      return "<br>";
   end Break;

   function Center return String is
   begin
      return "<center>";
   end Center;

   function Center_End return String is
   begin
      return "</center>";
   end Center_End;


   function Hard_Rule return String is
   begin
      return "<hr>";
   end Hard_Rule;


   function Pre return String is
   begin
      return "<pre>";
   end Pre;

   function Pre_End return String is
   begin
      return "</pre>";
   end Pre_End;

   -- Lists ---------
   function List return String is
   begin
      return "<ul>";
   end List;

   function List_End return String is
   begin
      return "</ul>";
   end List_End;

   function Numbered_List return String is
   begin
      return "<ol>";
   end Numbered_List;

   function Numbered_List_End return String is
   begin
      return "</ol>";
   end Numbered_List_End;

   function List_Item return String is
   begin
      return "<li>";
   end List_Item;

   -- Forms ---------
   function Form_Start (Method : Method_Type := Get;
                        Action : String;
                        Options : String := No_Options) return String is
   begin
      return "<form method=" & '"' & Method_Type'Image (Method) & '"' &
               " " & Options & " action=" & '"' & Action & '"' & ">";
   end Form_Start;


   function Form_End return String is
   begin
      return "</form>";
   end Form_End;


   function Select_Start (Name : String) return String is
   begin
      return "<select name =""" & Name & """>";
   end Select_Start;

   function Option (Value : String; Selected : Boolean := False)
                   return String is
      function Is_Selected return String is
      begin
         if Selected then
            return " selected";
         else
            return "";
         end if;
      end Is_Selected;
   begin
      return "<option value=""" & Value & '"' & Is_Selected & '>';
   end Option;
   --  <option value=VALUE SELECTED>


   function Select_End return String is
   begin
      return "</select>";
   end Select_End;
   --  </select>

   ------------------
   -- Input_Fields --
   ------------------

   function Input_Fields (Kind : String;
                          Name : String;
                          Value : String;
                          Checked : Boolean;
                          Message : String) return String is

      function Is_Checked return String is
      begin
         if Checked then
            return " CHECKED ";
         else
            return "";
         end if;
      end Is_Checked;

   begin
      return "<input type=" & Kind & " NAME=""" & Name & """ VALUE=""" &
               Value & """ " & Is_Checked & "> " & Message;
   end Input_Fields;


   --------------
   -- Checkbox --
   --------------

   function Checkbox (Name : String;
                      Value : String;
                      Checked : Boolean := False;
                      Message : String) return String is
   begin
      return Input_Fields ("checkbox", Name, Value, Checked, Message);
   end Checkbox;


   -----------
   -- Radio --
   -----------

   function Radio (Name : String;
                   Value : String;
                   Checked : Boolean := False;
                   Message : String) return String is
   begin
      return Input_Fields ("radio", Name, Value, Checked, Message);
   end Radio;


   --------------------------------
   -- Generic_Input_Without_Tail --
   --------------------------------

   function Generic_Input_Without_Tail
              (Kind : String; Name : String; Value : String) return String is
   begin
      return "<Input type=" & Kind & " name=""" & Name & """ value=""" & Value;
   end Generic_Input_Without_Tail;


   ------------
   -- Hidden --
   ------------

   --  <Input type=hidden name=NAME value=VALUE >
   function Hidden (Name : String; Value : String) return String is
   begin
      return Generic_Input_Without_Tail ("hidden", Name, Value) & """>";
   end Hidden;


   --------------
   -- Password --
   --------------

   function Password (Name : String;
                      Value : String := "";
                      Size : Natural := 0;
                      Maxlength : Natural := 0) return String is
   begin
      return Generic_Input_Without_Tail ("password", Name, Value) &
               """ size=""" & Integer'Image (Size) &
               """ maxlength=""" & Integer'Image (Maxlength) & """>";

   end Password;


   ----------------
   -- Text_Input --
   ----------------

   function Text_Input (Name : String;
                        Value : String := "";
                        Size : Positive;
                        Maxlength : Natural) return String is
   begin

      --  <input type=text name=NAME size=SIZE maxlength=MAXLENGTH value=VALUE>
      return Generic_Input_Without_Tail ("text", Name, Value) &
               """ size=""" & Integer'Image (Size) &
               " maxlength=""" & Integer'Image (Maxlength) & """>";
   end Text_Input;

   function Text_Input (Name : String; Value : String := ""; Size : Positive)
                       return String is
   begin

      --  <input type=text name=NAME size=SIZE maxlength=MAXLENGTH value=VALUE>
      return Generic_Input_Without_Tail ("text", Name, Value) &
               """ size=" & Integer'Image (Size) & """>";
   end Text_Input;


   ------------
   -- Submit --
   ------------

   function Submit (Name : String; Value : String) return String is
   begin
      return Generic_Input_Without_Tail ("submit", Name, Value) & """>";
   end Submit;


   -----------
   -- Reset --
   -----------

   function Reset (Name : String; Value : String) return String is
   begin
      return Generic_Input_Without_Tail ("reset", Name, Value) & """>";
   end Reset;


--   File_Mutex : aliased Pace.Semaphore.Mutex;

   function Read_File (File : in String; Htdocs_Location : Boolean := True)
                      return String is

      function Error_String (Text : in String) return String is
      begin
         Pace.Display (Text);
         return Text;
      end Error_String;

      function Read_Stream (Name : in String) return String is
         package Io renames Ada.Streams.Stream_Io;
         Fd : Io.File_Type;
         Length : Io.Count;
--         L : Pace.Semaphore.Lock (File_Mutex'Access);
      begin
         Io.Open (Fd, Io.In_File, Name);
         Length := Io.Size (Fd);
         declare
            Text : String (1 .. Integer (Length));
            S : Io.Stream_Access := Io.Stream (Fd);
         begin
            String'Read (S, Text);
            Io.Close (Fd);
            return Text;
         end;
      exception
         when others =>
            if Io.Is_Open (Fd) then
               Io.Close (Fd);
            end if;
            return Error_String ("ERROR: Reading served file : '" & Name &
                                 "'. The file you wanted was called '" & File &
                                 "'. If string returned blank, not found in $PACE");
      end Read_Stream;

      function Get_Stream_File return String is
      begin
         if Htdocs_Location then
            return Pace.Config.Find_File ("/html/" & File);
         else
            declare
               Result : String := Pace.Config.Find_File (File);
            begin
               if Result /= "" then
                  return Result;
               else
                  return File;
               end if;
            end;
         end if;
      end Get_Stream_File;

   begin
      return Read_Stream (Get_Stream_File);
   exception
      when others =>
         return Error_String ("ERROR: Opening served file : " & File);
   end Read_File;


   function Back return String is
   begin
      return "<script type='text/javascript'>history.back();</script>";
   end Back;

   function Navigation_Bar return String is
      -- Uses JavaScript
   begin
      return
        "<form>" & "<input type='button' value='Back' onClick='history.back()'>" &
          "<input type='button' value='Reload' onClick='location.reload()'>" &
          "<input type='button' value='Window' onClick='window.open(location.href)'>" &
          "</form><hr/>";
   end Navigation_Bar;

   function Replace (Url : in String) return String is
   begin
      return "<script type='text/javascript'>location.replace('" &
               Url & "');</script>";
   end Replace;

   function Reload return String is
   begin
      return "<script type='javascript'>location.reload();</script>";
   end Reload;

   function Reload_Frame (Frame : in String) return String is
   begin
      return "<html><body onLoad='parent." & Frame & ".location.reload()'>";
   end Reload_Frame;

   function Reload_First_Frame return String is
   begin
      return
        "<script type='text/javascript'>parent.frames[0].location.reload();</script>";
   end Reload_First_Frame;

   function Get_Path (Exec, Url : in String) return String is
      Slash_Index : Integer;
      use Ada.Strings.Fixed;
   begin
      if Url (Url'First) = '/' then
         return Url;
      else
         Slash_Index := Index (Exec, "/", Going => Ada.Strings.Backward);
         return Exec (Exec'First .. Slash_Index) & Url;
      end if;
   end Get_Path;

   function Template (Text : in String) return String is
      Start, Stop : Natural;
   begin
      -- Look for start delimiter
      --
      Start := Ada.Strings.Fixed.Index (Text, Start_Token);
      if Start > 0 then
         --
         -- if found then look for stop delimiter
         --
         Stop := Ada.Strings.Fixed.Index
                   (Text (Start + 1 .. Text'Last), Stop_Token);
         if Stop > Start then
            --
            -- Replace the template subtext by expanding in place, then recurse
            --
            return Text (Text'First .. Start - 1) &
                     Expand (Text (Start + Start_Token'Length .. Stop - 1)) &
                     Template (Text (Stop + Stop_Token'Length .. Text'Last));
         else
            return Text;  -- No more templates found
         end if;
      else
         return Text; -- No more templates found
      end if;
   end Template;
      ------------------------------------------------------------------------------
      -- $id: pace-server-html.adb,v 1.7 01/09/2003 23:24:25 pukitepa Exp $
      ------------------------------------------------------------------------------
end Pace.Server.Html;
