with Ada.Float_Text_Io;
with Text_Io;
with Pace.Strings;

package body Pace.Server.Xml is

   Xml_Style : constant Boolean := True;

   Version : constant String := "1.0";
   Standalone : constant String := "yes";


   procedure Put_Content (Default_Stylesheet : in String := "") is
      Style : constant String := "style";
      Sa : Session_Access := Default_Session;
      Placed : Boolean := Sa.Content_Placed;
   begin
      Pace.Server.Put_Content ("text/xml");
      if not Placed then
         -- if there is no style cgi parameter, or if there is but it has
         -- no value (?style=) then we don't want to send the xml or stylesheet
         -- declaration
         if Pace.Server.Key_Exists (Style) and then
            Pace.Server.Value (Style) /= "" then
            Pace.Server.Put_Data ("<?xml version='1.0' encoding='UTF-8'?>");
            if Pace.Server.Value (Style) = "default" then
               Pace.Server.Put_Data ("<?xml-stylesheet type='text/xsl' " &
                                     "href='" & Default_Stylesheet & "'?>");
            else
               Pace.Server.Put_Data
                 ("<?xml-stylesheet type='text/xsl' " &
                  "href='" & Pace.Server.Value (Style) & "'?>");
            end if;
         end if;
      end if;
   end Put_Content;

   function Pair (Key, Value : in String) return String is
   begin
      if Key = "" then
         return "";
      else
         return " " & Key & "=" & '"' & Value & '"';
      end if;
   end Pair;

   function Pair (Key : in String; Value : in Integer) return String is
   begin
      return Pair (Key, Pace.Strings.Trim (Value));
   end Pair;

   function Pair (Key : in String; Value : in Float) return String is
   begin
      return Pair (Key, Pace.Strings.Trim (Value));
   end Pair;

   ---------------
   -- Begin_Doc --
   ---------------

   function Begin_Doc (Key, Attribute : in String := "") return String is
   begin
      if Xml_Style then
         if Key = "" then
            return "<PaceServerXML>";
         else
            return "<" & Key & " " & Attribute & ">";
         end if;
      else
         return "<html><body>";
      end if;
   end Begin_Doc;

   -------------
   -- End_Doc --
   -------------

   function End_Doc (Key : in String := "") return String is
   begin
      if Xml_Style then
         if Key = "" then
            return "</PaceServerXML>";
         else
            return "</" & Key & ">";
         end if;
      else
         return "</body></html>";
      end if;
   end End_Doc;

   ----------
   -- Item --
   ----------

   function Item (Element : in String;
                  Value : in String;
                  Attribute : in String := "") return String is
   begin
      if Attribute = "" then
         return "<" & Element & ">" & Value & "</" & Element & ">";
      elsif Attribute (Attribute'First) = ' ' then
         return "<" & Element & Attribute &
           ">" & Value & "</" & Element & ">";
      else
         return "<" & Element & " " & Attribute &
                  ">" & Value & "</" & Element & ">";
      end if;
   end Item;

   function Item_U (Element : in String;
                    Value : in String;
                    Attribute : in String := "") return Asu.Unbounded_String is
   begin
      return Asu.To_Unbounded_String (Item (Element, Value, Attribute));
   end Item_U;


   function Item (Element : in Asu.Unbounded_String;
                  Value : in Asu.Unbounded_String;
                  Attribute : in Asu.Unbounded_String := Asu.Null_Unbounded_String) return Asu.Unbounded_String is
      use Asu;
      Lt : Unbounded_String := To_Unbounded_String ("<");
      Lt_Slash : Unbounded_String := To_Unbounded_String ("</");
      Gt : Unbounded_String := To_Unbounded_String (">");
      Space : Unbounded_String := To_Unbounded_String (" ");
   begin
      if Attribute = Asu.Null_Unbounded_String then
         return Lt & Element & Gt & Value & Lt_Slash & Element & Gt;
      elsif Asu.To_String (Attribute) (1) = ' ' then
         return Lt & Element & Attribute &
           Gt & Value & Lt_Slash & Element & Gt;
      else
         return Lt & Element & Space & Attribute &
                  Gt & Value & Lt_Slash & Element & Gt;
      end if;
   end Item;


   use Ada.Strings;

   function Item (Element : in String;
                  Value : in Integer;
                  Attribute : in String := "") return String is
   begin
      return Item (Element, Pace.Strings.Trim (Value), Attribute);
   end Item;

   function Item (Element : in String;
                  Value : in Float;
                  Attribute : in String := "") return String is

      Str : String (1 .. 100);
   begin
      Ada.Float_Text_Io.Put (Str, Value, 6, 0);

      return Item (Element, Pace.Strings.Trim (Str), Attribute);
   exception
      when Text_Io.Layout_Error =>
         return Item (Element, Pace.Strings.Trim (Value), Attribute);
   end Item;

   function Item (Element : in String;
                  Value : in Boolean;
                  Attribute : in String := "") return String is
   begin
      return Item (Element, Boolean'Pos (Value), Attribute);
   end Item;

   function Item (Element : in String) return String is
   begin
      return "<" & Element & "/>";
   end Item;

------------------------------------------------------------------------------
-- $id: pace-server-xml.adb,v 1.12 03/12/2003 21:03:39 ludwiglj Exp $
------------------------------------------------------------------------------
end Pace.Server.Xml;
