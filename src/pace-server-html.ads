package Pace.Server.Html is
   ------------------------------------------------------------
   -- HTML -- HTML tag generation
   ------------------------------------------------------------
   pragma Elaborate_Body;

   function Start_Html return String;
   function Head (Text : in String) return String;
   function Title (Text : in String) return String;
   function Start_Body return String;

   -- Header --------
   type H_Align is (Left, Center, Right);
   function Header (Text : in String;
                    Level : in Natural := 1;
                    Align : in H_Align := Left) return String;

   -- Style ---------
   function Bold (Text : in String) return String;
   function Italics (Text : in String) return String;
   function Paragraph return String;

   -- Definition ----
   function Start_Def_List return String;
   function Define (Term : in String; Definition : in String) return String;
   function End_Def_List return String;

   -- Table ---------
   function Table (Border : in Boolean := False) return String;
   function Row return String;
   function Table_Header (Text : in String;
                          Span_Row : in Natural := 1;
                          Span_Col : in Natural := 1) return String;
   function Cell (Text : in String;
                  Span_Row : in Natural := 1;
                  Span_Col : in Natural := 1) return String;
   function End_Table return String;


   package Abbreviations is
      function B (Text : in String) return String renames Bold;
      function I (Text : in String) return String renames Italics;
      function P return String renames Paragraph;
      function Th (Text : in String;
                   Span_Row : in Natural := 1;
                   Span_Col : in Natural := 1) return String
        renames Table_Header;
      function Td (Text : in String;
                   Span_Row : in Natural := 1;
                   Span_Col : in Natural := 1) return String renames Cell;
   end Abbreviations;

   function End_Body_Html return String;


   -- Advanced ---------
   No_Options : constant String := "";

   function Anchor (Href : String; -- Hyperlink ref
                    Options : String := No_Options) return String;
   function Anchor_End return String;    --  </a>
   function Break return String;    --  <br>
   function Center return String;    --  <centre>
   function Center_End return String;    --  </centre>
   function Hard_Rule return String;    --  <hr>
   function Pre return String;    --  <pre>
   function Pre_End return String;    --  </pre>

   -- Lists ---------
   function List return String;    --  <ul>
   function List_End return String;    --  </ul>
   function Numbered_List return String;    --  <ol>
   function Numbered_List_End return String;    --  </ol>
   function List_Item return String;    --  <li>

   -- Forms ---------
   type Method_Type is (Get, Post);
   function Form_Start (Method : Method_Type := Get; -- Get is synched
                        Action : String;
                        Options : String := No_Options) return String;
   function Form_End return String;    --  </form>
   function Select_Start (Name : String) return String;    --  <select name=NAME>
   function Option (Value : String; --  <option value=VALUE SELECTED>
                    Selected : Boolean := False) return String;
   function Select_End return String;    --  </select>

   -- Input ---------
   function Checkbox (Name : String;
                      Value : String;
                      Checked : Boolean := False;
                      Message : String) return String;
   function Radio (Name : String;
                   Value : String;
                   Checked : Boolean := False;
                   Message : String) return String;
   function Hidden (Name : String; Value : String) return String;

   function Text_Input (Name : String;
                        Value : String := "";
                        Size : Positive;
                        Maxlength : Natural) return String;
   function Text_Input (Name : String; Value : String := ""; Size : Positive)
                       return String;
   --  <input type=text name=NAME size=SIZE maxlength=MAXLENGTH valuse=VALUE>

   function Password (Name : String;
                      Value : String := "";
                      Size : Natural := 0;
                      Maxlength : Natural := 0) return String;

   function Submit (Name : String; Value : String) return String;
   --  <input type=submit Name=NAME value=VALUE>

   function Reset (Name : String; Value : String) return String;
   --  <input type=reset name=NAME value=VALUE>



   -- File ---------
   function Read_File (File : in String; --
                       Htdocs_Location : Boolean := True) return String;

   function Back return String;
   -- Go back to previous

   function Navigation_Bar return String;
   -- Select a Back, Reload, or Open new window

   function Replace (Url : in String) return String;
   -- Replace current doc with another URL

   function Reload return String;
   -- Reloads current page.. a hard reload

   function Reload_Frame (Frame : in String) return String;
   -- returns a string with <html><body onLoad='parent.Frame.location.reload()'>
   -- can append content after this and should append a closing </body></html>
   -- before putting the data

   function Reload_First_Frame return String;
   -- Reloads frame[0]

   function Get_Path (Exec, Url : in String) return String;
   -- Replaces URL path with the Exec path unless Url starts with "/"

   generic
      ---------------------------------------------------
      -- TEMPLATE - Expands text between token delimiters
      ---------------------------------------------------
      Start_Token : in String;
      Stop_Token : in String;
      with function Expand (Subtext : in String) return String;
   function Template (Text : in String) return String;

------------------------------------------------------------------------------
-- $id: pace-server-html.ads,v 1.4 11/22/2002 18:56:36 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Server.Html;
