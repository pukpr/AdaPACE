with Unchecked_Conversion;
with Pace.Xml;
with Pace.Log;

package body Hal.Textures is

   function To_String (D : Depth1) return String is
      subtype S is String (1..D'Size/8);
      function To_S is new Unchecked_Conversion(Depth1, S);
   begin
      return To_S (D);
   end;

   function To_String (D : Depth2) return String is
      subtype S is String (1..D'Size/8);
      function To_S is new Unchecked_Conversion(Depth2, S);
   begin
      return To_S (D);
   end;

   function To_String (D : Depth3) return String is
      subtype S is String (1..D'Size/8);
      function To_S is new Unchecked_Conversion(Depth3, S);
   begin
      return To_S (D);
   end;

   function To_String (D : Depth4) return String is
      subtype S is String (1..D'Size/8);
      function To_S is new Unchecked_Conversion(Depth4, S);
   begin
      return To_S (D);
   end;


   function To_String (T : Texture) return String is
   begin
      case T.Depth is
         when 1 =>
            return To_String (T.Mono);
         when 2 =>
            return To_String (T.RG);
         when 3 =>
            return To_String (T.RGB);
         when 4 =>
            return To_String (T.RGBA);
      end case;

   end;

   function Get_Texture_Buffer (XML : in String) return Texture is
      use Pace.Xml;
      Xml_Doc : Doc_Type := Parse (Xml);
      W : constant Width := Width'Value(Search_Xml (Xml_Doc, "width", ""));
      H : constant Width := Width'Value(Search_Xml (Xml_Doc, "height", ""));
      D : constant Integer := Integer'Value(Search_Xml (Xml_Doc, "depth", ""));
      subtype Tx is Texture(W,H,1,D);
      pragma Warnings (Off);
      T : Tx;
      pragma Warnings (On);
      use type Interfaces.Unsigned_32;
   begin
      if T.X = 0 or T.Y = 0 or T.Depth = 0 then
         Pace.Log.Put_Line ("Texture Buffer incompletely configured!");
      end if;
      return T;
   end;

end Hal.Textures;
