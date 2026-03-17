with Ada.Float_Text_IO;
with Ada.Long_Float_Text_IO;
with Text_IO;
with Pace.Strings;
with Pace.Server.Xml;
with Pace.Log;

with Dom.Core.Documents;
with Dom.Core.Elements;
with Dom.Core.Nodes;
with Dom.Readers;
with Sax.Readers;
with Input_Sources.Strings;
with Unicode.Ces.Utf8;

use Dom.Core;
use Dom.Core.Documents;
use Dom.Core.Elements;
use Dom.Core.Nodes;
use Dom.Readers;
use Sax.Readers;
use Input_Sources.Strings;

package body Pace.Xml is

   procedure Initialize (Object : in out Doc_Type) is
   begin
      null;
   end Initialize;

   procedure Finalize (Object : in out Doc_Type) is
   begin
      Dom.Core.Nodes.Free (Object.D);
   end Finalize;

   function Parse (Xml : String) return Doc_Type is
      Input : String_Input;
      Reader : Tree_Reader;
   begin
      if Xml = "" then
         return (Ada.Finalization.Limited_Controlled with D => null);
      else
         Open (Xml, Unicode.Ces.Utf8.Utf8_Encoding, Input);
         Set_Feature (Reader, Namespace_Feature, False);
         Set_Feature (Reader, Validation_Feature, False);
         Parse (Reader, Input);
         Close (Input);
         return (Ada.Finalization.Limited_Controlled with D => Get_Tree (Reader));
      end if;
   exception
      when E : others =>
         Pace.Log.Put_Line ("Error when parsing the Xml string: " & Xml);
         raise;
   end Parse;

   function Find_Node_With_Type (N : Dom.Core.Node; Ntype : Node_Types) return Dom.Core.Node is
   begin
      if N /= null then
         if Node_Type (N) = Ntype then
            return N;
         elsif Has_Child_Nodes (N) then
            declare
               List : Node_List := Child_Nodes (N);
            begin
               for I in 0 .. Dom.Core.Nodes.Length (List) loop
                  declare
                     Child : Node := Item (List, I);
                  begin
                     if Child /= null then
                        if Node_Type (Child) = Ntype then
                           return Child;
                        end if;
                     end if;
                  end;
               end loop;
            end;
         end if;
      end if;
      return null;
   end Find_Node_With_Type;

   function Tag_Name (N : Dom.Core.Node) return String is
      El : Element := Find_Node_With_Type (N, Element_Node);
   begin
      if El /= null then
         return Node_Name (El);
      else
         return "";
      end if;
   end Tag_Name;

   function Value (N : Dom.Core.Node; Ntype : Node_Types := Text_Node) return String is
      Tn : Node := Find_Node_With_Type (N, Ntype);
   begin
      if Tn /= null then
         return Pace.Strings.Trim_All (Node_Value (Tn));
      else
         return "";
      end if;
   end Value;

   function Search_Xml (Xml : in Doc_Type; Key : in String; Default : in String := "") return String is
   begin
      if Xml.D = null then
         return Default;
      else
         declare
            List : Dom.Core.Node_List := Dom.Core.Documents.Get_Elements_By_Tag_Name (Xml.D, Key);
         begin
            if Dom.Core.Nodes.Length (List) > 0 then
               declare
                  S : constant String := Value (Dom.Core.Nodes.Item (List, 0));
               begin
                  Free (List);
                  return S;
               end;
               -- return Pace.Xml.Value (Dom.Core.Nodes.Item (List, 0));
            else
               return Default;
            end if;
         end;
      end if;
   end Search_Xml;

   function Search_Xml (Xml : in String; Key : in String; Default : in String := "") return String is
   begin
      if Xml = "" then
         return Default;
      else
         declare
            Doc : Doc_Type := Pace.Xml.Parse (Xml);
         begin
            return Search_Xml (Doc, Key, Default);
         end;
      end if;
   end Search_Xml;

   function Search_Xml (Xml : in String; Key : in String) return Strings is
      Doc : Doc_Type := Pace.Xml.Parse (Xml);
   begin
      declare
         List : Dom.Core.Node_List := Dom.Core.Documents.Get_Elements_By_Tag_Name (Doc.D, Key);
         Result : Strings (0 .. Dom.Core.Nodes.Length (List) - 1);
      begin
         for I in Result'Range loop
            Result (I) := Ada.Strings.Unbounded.To_Unbounded_String (Pace.Xml.Value (Dom.Core.Nodes.Item (List, I)));
         end loop;
         return Result;
      end;
   end Search_Xml;

   function Search_Xml(Xml : in Doc_Type; Key : in String) return Strings is
      List : Dom.Core.Node_List := Dom.Core.Documents.Get_Elements_By_Tag_Name(Xml.D, Key);
      Result : Strings (0 .. Dom.Core.Nodes.Length (List) - 1);
   begin
      for I in Result'Range loop
         Result (I) := Ada.Strings.Unbounded.To_Unbounded_String(Pace.Xml.Value(Dom.Core.Nodes.Item (List, I)));
      end loop;
      return Result;
   end Search_Xml;

   -- return the first tag with element Key in the Document
   function Get_Tag_From_Doc (Xml : in Doc_Type; Key : in String) return Dom.Core.Node is
      use Dom.Core;
      use Dom.Core.Documents;
      List : Node_List := Dom.Core.Documents.Get_Elements_By_Tag_Name (Xml.D, Key);
   begin
      if Length (List) > 0 then
         return Item (List, 0);
      else
         return null;
      end if;
   end Get_Tag_From_Doc;

   -- return the first tag with element Key in the Node
   function Get_Tag (Xml : in Dom.Core.Node; Key : in String) return Dom.Core.Node is
      use Dom.Core.Nodes;
      List : Node_List := Child_Nodes (Xml);
   begin
      for I in 0 .. Length(List) loop
         if Tag_Name (Item (List, I)) = Key then
            return Item (List, I);
         end if;
      end loop;
      return null;
   end Get_Tag;

   function Get_Attrs (Xml : in Dom.Core.Node) return String is
      use Dom.Core;
      use Dom.Core.Nodes;
      use Pace.Strings;
      Attrs : Named_Node_Map := Attributes (Xml);
      Attr_Node : Node;
      Result : Us := Ustr.Null_Unbounded_String;
   begin
      for I in 0 .. Length (Attrs)-1 loop
         Attr_Node := Item (Attrs, I);
         Ustr.Append (Result, Pace.Server.Xml.Pair (Pace.Strings.Trim_All (Node_Name (Attr_Node)),
                                                    Pace.Strings.Trim_All (Node_Value (Attr_Node))));
      end loop;
      return Ustr.To_String (Result);
   end Get_Attrs;

   function To_String (Xml : in Dom.Core.Node) return String is
      use Dom.Core.Nodes;
      use Pace.Strings;
      Result : Us := Ustr.Null_Unbounded_String;
   begin
      if Node_Type (Xml) = Text_Node then
         Result := Ustr.To_Unbounded_String (Node_Value (Xml));
      elsif Node_Type (Xml) = Element_Node then
         if Has_Child_Nodes (Xml) then
            declare
               Children : Node_List := Child_Nodes (Xml);
               Attrs : String := Get_Attrs (Xml);
            begin
               for I in 0 .. Length (Children)-1 loop
                  Ustr.Append (Result, To_String (Item (Children, I)));
               end loop;
               Result := Ustr.To_Unbounded_String (Pace.Server.Xml.Item (Tag_Name (Xml),
                                                                         Ustr.To_String (Result),
                                                                         Attrs));
            end;
         else
            Result := Ustr.To_Unbounded_String (Pace.Server.Xml.Item (Tag_Name (Xml), Value (Xml)));
         end if;
      end if;
      return Ustr.To_String (Result);
   end To_String;


   -- Tag construction --------------------------

   function A (Key, Value : in String) return String is
   begin
      if Key = "" then
         return "";
      else
         return " " & Key & "=" & '"' & Value & '"';
      end if;
   end A;

   function A (Key : in String; Value : in Integer) return String is
   begin
      return A (Key, Pace.Strings.Trim (Value));
   end A;

   function A (Key : in String; Value : in Float) return String is
   begin
      return A (Key, Pace.Strings.Trim (Value));
   end A;

   function T (Element : in String;
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
   end T;

   function T (Element : in String;
               Value : in Integer;
               Attribute : in String := "") return String is
   begin
      return T (Element, Pace.Strings.Trim (Value), Attribute);
   end T;

   function T (Element : in String;
               Value : in Float;
               Attribute : in String := "") return String is
      Str : String (1 .. 100);
   begin
      Ada.Float_Text_Io.Put (Str, Value, 6, 0);
      return T (Element, Pace.Strings.Trim (Str), Attribute);
   exception
      when Text_Io.Layout_Error =>
         return T (Element, Pace.Strings.Trim (Value), Attribute);
   end T;

   function T (Element : in String;
               Value : in Long_Float;
               Attribute : in String := "") return String is
      Str : String (1 .. 100);
   begin
      Ada.Long_Float_Text_Io.Put (Str, Value, 14, 0);
      return T (Element, Pace.Strings.Trim (Str), Attribute);
   exception
      when Text_Io.Layout_Error =>
         return T (Element, Pace.Strings.Trim (Float(Value)), Attribute);
   end T;

   function T (Element : in String;
               Value : in Boolean;
               Attribute : in String := "") return String is
   begin
      return T (Element, Boolean'Pos (Value), Attribute);
   end T;

   function T (Element : in String) return String is
   begin
      return "<" & Element & "/>";
   end T;

end Pace.Xml;
