with Interfaces;

package Hal.Textures is

   type RGB is record
      R, G, B : Interfaces.Unsigned_8;
   end record;

   type RGBA is record
      R, G, B, A : Interfaces.Unsigned_8;
   end record;

   type RG is record
      R, G : Interfaces.Unsigned_8;
   end record;

   subtype Width is Interfaces.Unsigned_32;

   subtype Depths is Integer range 1 .. 4;

   type Depth4 is
     array (Width range <>, Width range <>, Width range <>) of RGBA;
   type Depth3 is
     array (Width range <>, Width range <>, Width range <>) of RGB;
   type Depth2 is
     array (Width range <>, Width range <>, Width range <>) of RG;
   type Depth1 is
     array (Width range <>,
            Width range <>,
            Width range <>)
            of Interfaces.Unsigned_8;

   type Texture (X, Y, Z : Width; Depth : Depths) is record
      case Depth is
         when 1 =>
            Mono : Depth1 (1 .. X, 1 .. Y, 1 .. Z);
         when 2 =>
            RG : Depth2 (1 .. X, 1 .. Y, 1 .. Z);
         when 3 =>
            RGB : Depth3 (1 .. X, 1 .. Y, 1 .. Z);
         when 4 =>
            RGBA : Depth4 (1 .. X, 1 .. Y, 1 .. Z);
      end case;
   end record;

   -- Converters for raw http, etc.
   
   function To_String (D : Depth1) return String;
   function To_String (D : Depth2) return String;
   function To_String (D : Depth3) return String;
   function To_String (D : Depth4) return String;

   function To_String (T : Texture) return String; -- strips off only the RGBA

   function Get_Texture_Buffer (XML : in String) return Texture;
   -- "<image><x>0</x><y>0</y><width>4</width><height>4</height><depth>4</depth></image>"

end Hal.Textures;
