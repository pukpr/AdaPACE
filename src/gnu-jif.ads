with Interfaces;
with Ada.Sequential_IO;
with Ada.Finalization;

------- -------      -----------------------------------------
package Gnu.Jif is   -- Efficient compressed graphics creation
   ------- -------      -----------------------------------------

   pragma Elaborate_Body; -- uses Unchecked_Allocation, Text_IO

   subtype J_Int is Integer;  -- Integer Computation type

   ----------------------------
   -- Image type (the main ADT)  -- Internally Controlled
   ----------------------------
   type Image (Sx, Sy : J_Int) is tagged private;

   ----------------------------
   -- Output functions
   ----------------------------
   procedure Callback (Obj : in out Image;    -- Don't call this directly;
     Data : in String); -- if not overridden goes to stdout
   procedure Image_Gif (Im : in out Image'Class);  -- Dispatches to Callback

   -- Convenience for writing files through callback
   package Sio is new Ada.Sequential_IO (Character);

   ----------------------------
   -- Color types
   ----------------------------
   type Color is private;
   Styled         : constant Color;
   Brushed        : constant Color;
   Styled_Brushed : constant Color;
   Tiled          : constant Color;
   Transparent    : constant Color;

   type RGB is  -- Red-Green-Blue spectrum
   record
      R, G, B : J_Int range 0 .. 255;
   end record;

   ----------------------------
   -- Auxiliary types
   ----------------------------
   type Point is record
      X : J_Int;
      Y : J_Int;
   end record;

   type Points is array (Positive range <>) of Point;

   ----------------------------
   -- Input functions
   ----------------------------

   procedure Image_Set_Pixel (Im : Image; P : Point; Col : Color);

   function Image_Get_Pixel (Im : Image; P : Point) return Color;

   procedure Image_Line
     (Im  : Image;
      P1  : Point;
      P2  : Point;
      Col : Color);

   procedure Image_Dashed_Line
     (Im  : Image;
      P1  : Point;
      P2  : Point;
      Col : Color);

   procedure Image_Rectangle
     (Im  : Image;
      P1  : Point;
      P2  : Point;
      Col : Color);

   procedure Image_Filled_Rectangle
     (Im  : Image;
      P1  : Point;
      P2  : Point;
      Col : Color);

   function Image_Bounds_Safe (Im : Image; P : Point) return Boolean;

   procedure Image_Polygon (Im : Image; P : Points; Col : Color);

   procedure Image_Filled_Polygon (Im : Image; P : Points; Col : Color);

   function Image_Color_Allocate (Im : Image; Col : RGB) return Color;

   function Image_Color_Closest (Im : Image; Col : RGB) return Color;

   function Image_Color_Exact (Im : Image; Col : RGB) return Color;

   procedure Image_Color_Deallocate (Im : Image; Col : Color);

   procedure Image_Color_Transparent (Im : Image; Col : Color);

   procedure Image_Arc
     (Im            : Image;
      Center        : Point;
      Width         : J_Int;
      Height        : J_Int;
      Start_Degrees : J_Int;
      End_Degrees   : J_Int;
      Col           : Color);

   procedure Image_Fill_To_Border
     (Im     : Image;
      P      : Point;
      Border : Color;
      Col    : Color);

   procedure Image_Fill (Im : Image; P : Point; Col : Color);

   procedure Image_Copy
     (Dst    : Image;
      Src    : Image;
      To     : Point;
      From   : Point;
      Width  : J_Int;
      Height : J_Int);

   procedure Image_Copy_Resized
     (Dst         : Image;
      Src         : Image;
      To          : Point;
      From        : Point;
      To_Width    : J_Int;
      To_Height   : J_Int;
      From_Width  : J_Int;
      From_Height : J_Int);

   procedure Image_Rotate (Dst : Image; Src : Image; Rotation : J_Int);
   -- in degrees

   ----------------------------
   -- Input Special Effects
   ----------------------------
   procedure Image_Set_Brush (Im : Image; Brush : Image);

   procedure Image_Set_Tile (Im : Image; Tile : Image);

   type Color_Array is array (Natural range <>) of Color;

   procedure Image_Set_Style  -- apply a modulus of colors
     (Im    : Image;
      Style : Color_Array);

   procedure Image_Interlace (Im : Image; Interlace_Arg : J_Int);

   function Deallocation_Report return String; -- for debugging

   -------------------------------------------------------------------
   -------------------------------------------------------------------
private
   -------------------------------------------------------------------
   -------------------------------------------------------------------
   type Color is new J_Int;
   subtype J_Byte is Interfaces.Unsigned_8;

   Dashsize : constant := 4;

   Styled         : constant Color := -2;
   Brushed        : constant Color := -3;
   Styled_Brushed : constant Color := -4;
   Tiled          : constant Color := -5;
   Transparent    : constant Color := -6;

   Max_Color_Map_Size : constant := 256;

   type Pixmap is array (J_Int range <>, J_Int range <>) of J_Byte;

   subtype Color_Range is Color range 0 .. Max_Color_Map_Size - 1;
   type Table is array (Color_Range) of Color;

   type Color_Style is access all Color_Array;

   type Block is array (0 .. 255) of J_Byte;

   type Encoding is record
      A_Count        : J_Int                  := 0;
      Code_Clear     : J_Int                  := 0;
      Code_Eof       : J_Int                  := 0;
      Countdown      : Long_Integer           := 0;
      Curx           : J_Int                  := 0;
      Cury           : J_Int                  := 0;
      Height         : J_Int                  := 0;
      Interlace_C    : J_Int                  := 0;
      Just_Cleared   : J_Int                  := 0;
      Max_Ocodes     : J_Int                  := 0;
      Obits          : J_Int                  := 0;
      Oblen          : J_Int                  := 0;
      Oblock         : Block                  := (others => 0);
      Obuf           : Interfaces.Unsigned_32 := 0;
      Out_Bits       : J_Int                  := 0;
      Out_Bits_Init  : J_Int                  := 0;
      Out_Bump       : J_Int                  := 0;
      Out_Bump_Init  : J_Int                  := 0;
      Out_Clear      : J_Int                  := 0;
      Out_Clear_Init : J_Int                  := 0;
      Out_Count      : J_Int                  := 0;
      Pass           : J_Int                  := 0;
      Rl_Basecode    : J_Int                  := 0;
      Rl_Count       : J_Int                  := 0;
      Rl_Pixel       : J_Int                  := 0;
      Rl_Table_Max   : J_Int                  := 0;
      Rl_Table_Pixel : J_Int                  := 0;
      Width          : J_Int                  := 0;
   end record;

   --
   -- Making this controlled requires special care for
   -- composed brush & tile objects as others may point to these images
   --
   type Image_Data (Sx, Sy : J_Int);
   type Image_Access is access all Image_Data;
   type Image (Sx, Sy : J_Int) is new Ada.Finalization.Controlled with record
      This : Image_Access := null;
   end record;
   procedure Initialize (Obj : in out Image);
   procedure Adjust (Obj : in out Image);
   procedure Finalize (Obj : in out Image);

   type Image_Data (Sx, Sy : J_Int) is record
      Pixels          : Pixmap (1 .. Sx, 1 .. Sy) :=
        (others => (others => 0));
      Colors_Total    : Color_Range               := 0;
      Red             : Table                     := (others => 0);
      Green           : Table                     := (others => 0);
      Blue            : Table                     := (others => 0);
      Open            : Table                     := (others => 0);
      Transparent     : Color                     := -1;
      Brush           : Image_Access              := null;  -- watch for
                                                            --dangling
                                                            --pointers !
      Tile            : Image_Access              := null;   -- ditto !
      Brush_Color_Map : Table                     := (others => 0);
      Tile_Color_Map  : Table                     := (others => 0);
      Style_Length    : J_Int                     := 0;
      Style_Pos       : J_Int                     := 0;
      Style           : Color_Style               := null;  -- should be safe
                                                            --(internally
                                                            --created)
      Interlace       : J_Int                     := 0;
      Dx              : Encoding;
   end record;

   -- These are not needed for user code because of Controlled inheritance
   procedure Image_Destroy (Im : in out Image);
   -- function Image_Create (Sx : J_Int; Sy : J_Int) return Image;

   ------------------------------------------------------
   -- Extra Character Drawing Functions for child packages
   --   This is essentially a pixmap for fixed-size fonts
   ------------------------------------------------------

   type Font_Data (Nchars : J_Int) is record
      Offset : J_Int;
      Width  : J_Int;
      Height : J_Int;
      Data   : String (1 .. Nchars);
   end record;

   type Font is access all Font_Data;

   procedure Image_Char
     (Im  : Image;
      F   : Font;
      P   : Point;
      Ch  : Character;
      Col : Color);

   procedure Image_Char_Up
     (Im  : Image;
      F   : Font;
      P   : Point;
      Ch  : Character;
      Col : Color);

   procedure Image_String
     (Im  : Image;
      F   : Font;
      P   : Point;
      S   : String;
      Col : Color);

   procedure Image_String_Up
     (Im  : Image;
      F   : Font;
      P   : Point;
      S   : String;
      Col : Color);

   ----------------------------------------------------------------------------
   ----
   -- $id: gnu-jif.ads,v 1.1 09/16/2002 18:18:14 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Gnu.Jif;
