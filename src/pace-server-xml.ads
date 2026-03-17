with Ada.Strings.Unbounded;

package Pace.Server.Xml is
   ------------------------------------------------------------
   -- XML -- Basic XML tag generation
   ------------------------------------------------------------
   pragma Elaborate_Body;

   package Asu renames Ada.Strings.Unbounded;

   Content : constant String := "application/xml";

   -- Does 2 things:
   -- 1) puts the content as text/xml
   -- 2) Determines if the xml declaration and a stylesheet declaration
   --    should be sent
   -- Default_Stylesheet is used only when ?style=default is sent as
   -- a cgi parameter.
   procedure Put_Content (Default_Stylesheet : in String := "");

   function Begin_Doc (Key, Attribute : in String := "") return String;

   function Pair (Key, Value : in String) return String;

   function Pair (Key : in String; Value : in Integer) return String;

   function Pair (Key : in String; Value : in Float) return String;

   function Item (Element : in String;
                  Value : in String;
                  Attribute : in String := "") return String;

   -- needs a different name than Item otherwise there are situations when it is unresolvable
   function Item_U (Element : in String;
                    Value : in String;
                    Attribute : in String := "") return Asu.Unbounded_String;

   function Item (Element : in Asu.Unbounded_String;
                  Value : in Asu.Unbounded_String;
                  Attribute : in Asu.Unbounded_String := Asu.Null_Unbounded_String) return Asu.Unbounded_String;

   function Item (Element : in String;
                  Value : in Integer;
                  Attribute : in String := "") return String;

   function Item (Element : in String;
                  Value : in Float;
                  Attribute : in String := "") return String;

   function Item (Element : in String;
                  Value : in Boolean;
                  Attribute : in String := "") return String;

   function Item (Element : in String) return String;

   function End_Doc (Key : in String := "") return String;

------------------------------------------------------------------------------
-- $id: pace-server-xml.ads,v 1.6 03/12/2003 21:03:42 ludwiglj Exp $
------------------------------------------------------------------------------
end Pace.Server.Xml;
