with Interfaces.C_Streams;
with Ada.Finalization;
with System;
----------------------------------------------------
package Gnu.Pdf is  --- Reference package API for generating dynamic PDF 
   --               ----------------------------------------------------
   pragma Elaborate_Body;

   Pdf_Error : exception;

   subtype P_Int is Integer;
   subtype P_Float is Float;

   type P_String is new String;  
   function "-" (Str : P_String) return String;  -- Strips ASCII.NUL terminator
   function "+" (Str : String) return P_String;  -- Adds ASCII.NUL terminator

   -- PDF exceptions that could be handled via the user-supplied error handler 
   type Error_Type is (Pdf_None,  -- will never happen
                       Pdf_Memory_Error, Pdf_Io_Error, Pdf_Runtime_Error,
                       Pdf_Index_Error, Pdf_Type_Error, Pdf_Division_By_Zero,
                       Pdf_Overflow_Error, Pdf_Syntax_Error, Pdf_Value_Error,
                       Pdf_System_Error, Pdf_Nonfatal_Error, Pdf_Unknown_Error);

-- TYPES

   type Pdf is limited private;
   type Pdf_Access is access all Pdf;  
   type Pdf_File is new P_Int;
   type Pdf_Font is new P_Int;
   type Pdf_Image is new P_Int;
   type Pdf_Bookmark is new P_Int;

-- CONTROLLED TYPE

   type Pdf_Handle is new Ada.Finalization.Limited_Controlled with private;
   procedure Initialize (Handle : in out Pdf_Handle);
   procedure Finalize (Handle : in out Pdf_Handle);
   function "+" (Handle : Pdf_Handle) return Pdf_Access;

-- CALLBACKS

   type Write_Proc is
     access function
              (P : access Pdf; Data : String; Size : Integer) return Integer;  
   pragma Convention (C, Write_Proc);

   type Error_Proc is
     access procedure (P : access Pdf; Error : Error_Type; Msg : P_String);
   pragma Convention (C, Error_Proc);

-- MAIN LIBRARY ROUTINES

   -- Gets PDF lib major version numeral .
   function Pdf_Get_Majorversion return Integer;

   -- Gets PDF lib minor version numeral .
   function Pdf_Get_Minorversion return P_Int;

   -- Boots PDF lib
   procedure Pdf_Boot;

   -- Shuts down PDF lib
   procedure Pdf_Shutdown;

   -- Generates new PDF object with client-supplied error handling and memory
   -- allocation routines.
   function Pdf_New2 (Error : Error_Proc;
                      Alloc, Realloc, Free : System.Address :=
                        System.Null_Address;
                      Opaque : System.Address := System.Null_Address)
                     return Pdf_Access;

   -- Get opaque application pointer saved in PDF lib -- for multi-threading.
   -- Extra threading info allocated via PDF_new2 if needed
   function Pdf_Get_Opaque (P : access Pdf) return System.Address;

   -- Generates new PDF object, utilize default error handling and memory management.
   function Pdf_New return Pdf_Access;

   -- Deletes PDF object and deallocate every internal resources.
   procedure Pdf_Delete (P : access Pdf);

   -- Generates new PDF file utilizing the supplied file name.
   function Pdf_Open_File
              (P : access Pdf; File_Name : P_String) return Pdf_File;

   -- Opens new PDF file associated with p, utilize the supplied file handle.
   function Pdf_Open_Fp
              (P : access Pdf; Fp : Interfaces.C_Streams.Files) return Pdf_File;

   -- Opens new PDF in memory, and install the callback for fetching the data.
   procedure Pdf_Open_Mem (P : access Pdf; Write : Write_Proc);

   -- Closes generated PDF file, and free every document-related resources.
   procedure Pdf_Close (P : access Pdf);

   -- Appends new page to the document.
   procedure Pdf_Begin_Page (P : access Pdf; Width : P_Float; Height : P_Float);

   -- Finishes working page.
   procedure Pdf_End_Page (P : access Pdf);

-- PARAMETER HANDLING

   -- Sets keyed PDF lib parameter with string value.
   procedure Pdf_Set_Parameter
               (P : access Pdf; Key : P_String; Value : P_String);

   -- Sets value of the keyed PDF lib parameter with a float value.
   procedure Pdf_Set_Value (P : access Pdf; Key : P_String; Value : P_Float);

   -- Gets contents of the keyed PDF lib parameter of string type.
   function Pdf_Get_Parameter
              (P : access Pdf; Key : P_String; Modifier : P_Float)
              return String;


   -- Gets value of the keyed PDF lib parameter with float type.
   function Pdf_Get_Value (P : access Pdf; Key : P_String; Modifier : P_Float)
                          return P_Float;

-- TEXT AND FONT HANDLING

   -- Searches for the font, prepping it for later use.  The metrics will be
   -- loaded, and when embed > 0, the font file will be checked but
   -- unused. Encoding is one of "builtin", "macroman", "winansi", "host", or
   -- the user defined encoding name, or the name of the C(hinese)-Map.
   function Pdf_Findfont (P : access Pdf;
                          Font_Name : P_String;
                          Encoding : P_String;
                          Embed : P_Int) return Pdf_Font;


   -- Sets current font of given size, utilizing the font found via PDF_findfont.
   procedure Pdf_Setfont (P : access Pdf; Font : Pdf_Font; Font_Size : P_Float);

-- TEXT OUTPUT

   -- Puts text in the current font and size at the current position.
   procedure Pdf_Show (P : access Pdf; Text : P_String);


   -- Puts text in the current font at point (x, y).
   procedure Pdf_Show_Xy
               (P : access Pdf; Text : P_String; X : P_Float; Y : P_Float);


   -- Puts text at the next line. Line spacing determined via the "leading" parameter.
   procedure Pdf_Continue_Text (P : access Pdf; Text : P_String);

   -- Formats text in current font and size into the supplied text box
   -- The requested formatting mode has to be one of "left", 
   -- "right", "center", "justify", or "fulljustify". When width and height = 0
   -- only a single line is positioned at the point (left, top) in the
   -- requested mode.
   function Pdf_Show_Boxed (P : access Pdf;
                            Text : P_String;
                            Left : P_Float;
                            Top : P_Float;
                            Width : P_Float;
                            Height : P_Float;
                            Hmode : P_String;
                            Feature : P_String) return P_Int;

   -- Sets text output position.
   procedure Pdf_Set_Text_Pos (P : access Pdf; X : P_Float; Y : P_Float);

   -- Returns width of text of selected font.
   function Pdf_Stringwidth
              (P : access Pdf; Text : P_String; Font : P_Int; Size : P_Float)
              return P_Float;

-- Function which add an extra string length parameter for use with 
-- strings containing null characters. e.g. for Ada with embedded nulls.

   -- Ditto PDF_show but with set string length.
   procedure Pdf_Show2 (P : access Pdf; Text : String; Len : P_Int);


   -- Ditto PDF_show_xy but with sett string length.
   procedure Pdf_Show_Xy2 (P : access Pdf;
                           Text : String;
                           Len : P_Int;
                           X : P_Float;
                           Y : P_Float);


   -- Ditto PDF_continue_text but with set string length.
   procedure Pdf_Continue_Text2 (P : access Pdf; Text : String; Len : P_Int);


   -- Ditto PDF_stringwidth but with set string length.
   function Pdf_Stringwidth2 (P : access Pdf;
                              Text : String;
                              Len : P_Int;
                              Font : P_Int;
                              Size : P_Float) return P_Float;

-- GRAPHICS STATE

   -- Sets current dash pattern to b=black and w=white units.
   procedure Pdf_Setdash (P : access Pdf; B : P_Float; W : P_Float);

   -- Sets more complex dash pattern defined via an array.
   subtype Dash_Index is P_Int range 1 .. 8;
   type Dashes is array (Dash_Index) of P_Float;
   procedure Pdf_Setpolydash
               (P : access Pdf; Dash_Array : Dashes; Length : Dash_Index);

   -- Sets flatness to a constrained value.
   subtype Flatness_Type is P_Float range 0.0 .. 100.0;
   procedure Pdf_Setflat (P : access Pdf; Flatness : Flatness_Type);

   -- Sets line join parameter to a constrained value.
   subtype Line_Type is P_Int range 0 .. 2;
   procedure Pdf_Setlinejoin (P : access Pdf; Line_Join : Line_Type);

   -- Sets line cap parameter to a constrained value.
   procedure Pdf_Setlinecap (P : access Pdf; Line_Cap : Line_Type);

   -- Sets miter limit to constrained value >= 1.
   subtype Miter_Type is P_Float range 1.0 .. P_Float'Last;
   procedure Pdf_Setmiterlimit (P : access Pdf; Miter : Miter_Type);

   -- Sets current linewidth to width.
   procedure Pdf_Setlinewidth (P : access Pdf; Width : P_Float);

   -- Resets every color and graphics state parameters to default.
   procedure Pdf_Initgraphics (P : access Pdf);

   -- Saves current graphics state.
   procedure Pdf_Save (P : access Pdf);

   -- Restores most recently saved graphics state.
   procedure Pdf_Restore (P : access Pdf);

   -- Translates origin of the coordinate system.
   procedure Pdf_Translate (P : access Pdf; Tx : P_Float; Ty : P_Float);

   -- Scales coordinate system.
   procedure Pdf_Scale (P : access Pdf; Sx : P_Float; Sy : P_Float);

   -- Rotates coordinate system via phi degrees.
   procedure Pdf_Rotate (P : access Pdf; Phi : P_Float);

   -- Skews coordinate system in x and y direction via alpha and beta degrees.
   procedure Pdf_Skew (P : access Pdf; Alpha : P_Float; Beta : P_Float);

   -- Concatenates matrix to the current transformation matrix.
   procedure Pdf_Concat (P : access Pdf;
                         A : P_Float;
                         B : P_Float;
                         C : P_Float;
                         D : P_Float;
                         E : P_Float;
                         F : P_Float);

   -- Overrides the current transformation matrix.
   procedure Pdf_Setmatrix (P : access Pdf;
                            A : P_Float;
                            B : P_Float;
                            C : P_Float;
                            D : P_Float;
                            E : P_Float;
                            F : P_Float);

-- PATH CONSTRUCTION, PAINTING, AND CLIPPING

   -- Sets current point.
   procedure Pdf_Moveto (P : access Pdf; X : P_Float; Y : P_Float);

   -- Draws line from the current point to (x, y).
   procedure Pdf_Lineto (P : access Pdf; X : P_Float; Y : P_Float);

   -- Draws Bezier curve from the current point, utilize 3 control points.
   procedure Pdf_Curveto (P : access Pdf;
                          X1 : P_Float;
                          Y1 : P_Float;
                          X2 : P_Float;
                          Y2 : P_Float;
                          X3 : P_Float;
                          Y3 : P_Float);

   -- Draws circle with center (x, y) and radius r.
   procedure Pdf_Circle (P : access Pdf; X : P_Float; Y : P_Float; R : P_Float);

   -- Draws counter-clockwise circular arc from alpha to beta degrees.
   procedure Pdf_Arc (P : access Pdf;
                      X : P_Float;
                      Y : P_Float;
                      R : P_Float;
                      Alpha : P_Float;
                      Beta : P_Float);

   -- Draws clockwise circular arc from alpha to beta degrees.
   procedure Pdf_Arcn (P : access Pdf;
                       X : P_Float;
                       Y : P_Float;
                       R : P_Float;
                       Alpha : P_Float;
                       Beta : P_Float);

   -- Draws rectangle at lower left (x, y) of width and height.
   procedure Pdf_Rect (P : access Pdf;
                       X : P_Float;
                       Y : P_Float;
                       Width : P_Float;
                       Height : P_Float);

   -- Closes current path.
   procedure Pdf_Closepath (P : access Pdf);

   -- Draws path with the current color and line width; and then clears.
   procedure Pdf_Stroke (P : access Pdf);

   -- Closes the path and then draws.
   procedure Pdf_Closepath_Stroke (P : access Pdf);

   -- Fills interior of the path with the current fill color.
   procedure Pdf_Fill (P : access Pdf);

   -- Fills and draws path with current fill and stroke color.
   procedure Pdf_Fill_Stroke (P : access Pdf);

   -- Closes path, fills, and then strokes.
   procedure Pdf_Closepath_Fill_Stroke (P : access Pdf);

   -- Uses current path as clipping path.
   procedure Pdf_Clip (P : access Pdf);

-- COLOR HANDLING

   -- Makes named spot color from the current color.
   function Pdf_Makespotcolor
              (P : access Pdf; Spot_Name : P_String; Len : P_Int) return P_Int;


   -- Sets current color space and color. fstype is "fill", "stroke", or "both".
   procedure Pdf_Setcolor (P : access Pdf;
                           Fstype : P_String;
                           Colorspace : P_String;  -- "rgb"
                           C1 : P_Float;   -- red
                           C2 : P_Float;   -- green
                           C3 : P_Float;   -- blue
                           C4 : P_Float);  --                             

-- PATTERN DEFINITION

   -- Starts a new pattern definition.
   function Pdf_Begin_Pattern (P : access Pdf;
                               Width : P_Float;
                               Height : P_Float;
                               Xstep : P_Float;
                               Ystep : P_Float;
                               Paint_Type : P_Int) return P_Int;

   -- Finishes pattern definition.
   procedure Pdf_End_Pattern (P : access Pdf);

-- TEMPLATE DEFINITION

   -- Starts new template definition.
   function Pdf_Begin_Template
              (P : access Pdf; Width : P_Float; Height : P_Float)
              return Pdf_Image;

   -- Finishes template definition.
   procedure Pdf_End_Template (P : access Pdf);

-- IMAGE HANDLING

   -- Places image or template with the lower left corner at (x, y), and scales.
   procedure Pdf_Place_Image (P : access Pdf;
                              Image : Pdf_Image;
                              X : P_Float;
                              Y : P_Float;
                              Scale : P_Float);

   -- Uses image data of selected data source. Supported types include
   -- "jpeg", "ccitt", "raw". Supported sources => "memory", "fileref", "url".
   -- Len is only used for type="raw"; Params is only used for type="ccitt".
   function Pdf_Open_Image (P : access Pdf;
                            Image_Type : P_String;
                            Source : P_String;
                            Data : P_String;
                            Length : Long_Integer;
                            Width : P_Int;
                            Height : P_Int;
                            Components : P_Int;
                            Bpc : P_Int;
                            Params : P_String) return Pdf_Image;


   -- Opens image file. Supported types include "jpeg", "tiff", "gif", and "png"
   -- Stringparam is either "", "mask", "masked", or "page". Int_Param is 0 or
   -- the image numeral of the applied mask, or the page.
   function Pdf_Open_Image_File (P : access Pdf;
                                 Image_Type : P_String;
                                 File_Name : P_String;
                                 String_Param : P_String;
                                 Int_Param : P_Int) return Pdf_Image;


   -- Closes image retrieved with one of the PDF_open_image functions.
   procedure Pdf_Close_Image (P : access Pdf; Image : Pdf_Image);

   -- Adds existing image as thumbnail for the current page.
   procedure Pdf_Add_Thumbnail (P : access Pdf; Image : Pdf_Image);

-- FAX-COMPRESSED DATA PROCESSING

   -- Opens raw CCITT image.
   function Pdf_Open_Ccitt (P : access Pdf;
                            File_Name : P_String;
                            Width : P_Int;
                            Height : P_Int;
                            Bit_Reverse : P_Int;
                            K : P_Int;
                            Black_Is_1 : P_Int) return Pdf_Image;


   -- Adds nested bookmark under parent, or new top level bookmark if
   -- parent = 0. Returns bookmark descriptor that could be
   -- used as parent for subsequent nested bookmarks. If open = 1, child
   -- bookmarks will be folded out, but are invisible if open = 0.
   function Pdf_Add_Bookmark (P : access Pdf;
                              Text : P_String;
                              Parent : Pdf_Bookmark;
                              Open : P_Int) return Pdf_Bookmark;


   -- Fills document information field key with value. Key is either "Subject",
   -- "Title", "Creator", "Author", "Keywords", or the user-defined key.
   procedure Pdf_Set_Info (P : access Pdf; Key : P_String; Value : P_String);

-- FILE ATTACHMENTS, NOTES, AND LINKS

   -- Adds file attachment annotation. Icon is either "graph", "paperclip", "pushpin", or "tag".
   procedure Pdf_Attach_File (P : access Pdf;
                              Llx : P_Float;
                              Lly : P_Float;
                              Urx : P_Float;
                              Ury : P_Float;
                              File_Name : P_String;
                              Description : P_String;
                              Author : P_String;
                              Mime_Type : P_String;
                              Icon : P_String);


   -- Links note annotation. Icon is either "comment", "insert", "note",
   -- "paragraph", "newparagraph", "key", or "help".
   procedure Pdf_Add_Note (P : access Pdf;
                           Llx : P_Float;
                           Lly : P_Float;
                           Urx : P_Float;
                           Ury : P_Float;
                           Contents : P_String;
                           Title : P_String;
                           Icon : P_String;
                           Open : P_Int);


   -- Links the file link annotation -- to the PDF target.
   procedure Pdf_Add_Pdflink (P : access Pdf;
                              Llx : P_Float;
                              Lly : P_Float;
                              Urx : P_Float;
                              Ury : P_Float;
                              File_Name : P_String;
                              Page : P_Int;
                              Dest : P_String);


   -- Link the launch annotation -- to the target of selected file type.
   procedure Pdf_Add_Launchlink (P : access Pdf;
                                 Llx : P_Float;
                                 Lly : P_Float;
                                 Urx : P_Float;
                                 Ury : P_Float;
                                 File_Name : P_String);


   -- Links local annotation to the target within the current PDF file.
   procedure Pdf_Add_Locallink (P : access Pdf;
                                Llx : P_Float;
                                Lly : P_Float;
                                Urx : P_Float;
                                Ury : P_Float;
                                Page : P_Int;
                                Dest : P_String);


   -- Links a weblink annotation to the target URL on the net.
   procedure Pdf_Add_Weblink (P : access Pdf;
                              Llx : P_Float;
                              Lly : P_Float;
                              Urx : P_Float;
                              Ury : P_Float;
                              Url : P_String);


   -- Sets border style for every annotation. Style is "solid" or "dashed".
   procedure Pdf_Set_Border_Style
               (P : access Pdf; Style : P_String; Width : P_Float);


   -- Sets border color for every annotation.
   procedure Pdf_Set_Border_Color
               (P : access Pdf; Red : P_Float; Green : P_Float; Blue : P_Float);

   -- Sets border dash style for every annotation. See PDF_setdash.
   procedure Pdf_Set_Border_Dash (P : access Pdf; B : P_Float; W : P_Float);

-- OUTPUT STREAM HANDLING

   -- Get contents of the PDF output buffer. The result has to be used by
   -- the client before calling any other PDF library function.
   function Pdf_Get_Buffer
              (P : access Pdf; Size : access Long_Integer) return String;

-- PAGE SIZE CONSTANTS IN POINTS (72 points/inch)
   Inches : constant := 72.0;
   A0_Width : constant := 2380.0;  
   A0_Height : constant := 3368.0;  
   A1_Width : constant := 1684.0;  
   A1_Height : constant := 2380.0;  
   A2_Width : constant := 1190.0;  
   A2_Height : constant := 1684.0;  
   A3_Width : constant := 842.0;  
   A3_Height : constant := 1190.0;  
   A4_Width : constant := 595.0;  
   A4_Height : constant := 842.0;  
   A5_Width : constant := 421.0;  
   A5_Height : constant := 595.0;  
   A6_Width : constant := 297.0;  
   A6_Height : constant := 421.0;  
   B5_Width : constant := 501.0;  
   B5_Height : constant := 709.0;  
   Letter_Width : constant := 612.0;  -- 72 * 8.5
   Letter_Height : constant := 792.0;  -- 72 * 11.0              
   Legal_Width : constant := 612.0;  
   Legal_Height : constant := 1008.0;  
   Ledger_Width : constant := 1224.0;  
   Ledger_Height : constant := 792.0;  
   P11X17_Width : constant := 792.0;  
   P11X17_Height : constant := 1224.0;

private
   type Pdf is
      record
         null; -- Internals : System.Address;  -- Invisible
      end record;

   type Pdf_Handle is new Ada.Finalization.Limited_Controlled with
      record
         Obj : Pdf_Access;
      end record;

   pragma Import (C, Pdf_Add_Bookmark, "PDF_add_bookmark");  
   pragma Import (C, Pdf_Add_Launchlink, "PDF_add_launchlink");  
   pragma Import (C, Pdf_Add_Locallink, "PDF_add_locallink");  
   pragma Import (C, Pdf_Add_Note, "PDF_add_note");  
   pragma Import (C, Pdf_Add_Pdflink, "PDF_add_pdflink");  
   pragma Import (C, Pdf_Add_Thumbnail, "PDF_add_thumbnail");  
   pragma Import (C, Pdf_Add_Weblink, "PDF_add_weblink");  
   pragma Import (C, Pdf_Arc, "PDF_arc");  
   pragma Import (C, Pdf_Arcn, "PDF_arcn");  
   pragma Import (C, Pdf_Attach_File, "PDF_attach_file");  
   pragma Import (C, Pdf_Begin_Page, "PDF_begin_page");  
   pragma Import (C, Pdf_Begin_Pattern, "PDF_begin_pattern");  
   pragma Import (C, Pdf_Begin_Template, "PDF_begin_template");  
   pragma Import (C, Pdf_Boot, "PDF_boot");  
   pragma Import (C, Pdf_Circle, "PDF_circle");  
   pragma Import (C, Pdf_Clip, "PDF_clip");  
   pragma Import (C, Pdf_Close, "PDF_close");  
   pragma Import (C, Pdf_Close_Image, "PDF_close_image");  
   pragma Import (C, Pdf_Closepath, "PDF_closepath");  
   pragma Import (C, Pdf_Closepath_Fill_Stroke, "PDF_closepath_fill_stroke");  
   pragma Import (C, Pdf_Closepath_Stroke, "PDF_closepath_stroke");
   pragma Import (C, Pdf_Concat, "PDF_concat");  
   pragma Import (C, Pdf_Continue_Text, "PDF_continue_text");  
   pragma Import (C, Pdf_Continue_Text2, "PDF_continue_text2");  
   pragma Import (C, Pdf_Curveto, "PDF_curveto");  
   pragma Import (C, Pdf_Delete, "PDF_delete");  
   pragma Import (C, Pdf_End_Page, "PDF_end_page");  
   pragma Import (C, Pdf_End_Pattern, "PDF_end_pattern");  
   pragma Import (C, Pdf_End_Template, "PDF_end_template");  
   pragma Import (C, Pdf_Fill, "PDF_fill");  
   pragma Import (C, Pdf_Fill_Stroke, "PDF_fill_stroke");  
   pragma Import (C, Pdf_Findfont, "PDF_findfont");
   --    pragma Import(C, PDF_get_buffer, "PDF_get_buffer");            
   pragma Import (C, Pdf_Get_Majorversion, "PDF_get_majorversion");
   pragma Import (C, Pdf_Get_Minorversion, "PDF_get_minorversion");
   pragma Import (C, Pdf_Get_Opaque, "PDF_get_opaque");
   --    pragma Import(C, PDF_get_parameter, "PDF_get_parameter");      
   pragma Import (C, Pdf_Get_Value, "PDF_get_value");  
   pragma Import (C, Pdf_Initgraphics, "PDF_initgraphics");  
   pragma Import (C, Pdf_Lineto, "PDF_lineto");  
   pragma Import (C, Pdf_Makespotcolor, "PDF_makespotcolor");  
   pragma Import (C, Pdf_Moveto, "PDF_moveto");  
   pragma Import (C, Pdf_New, "PDF_new");  
   pragma Import (C, Pdf_New2, "PDF_new2");  
   pragma Import (C, Pdf_Open_Ccitt, "PDF_open_CCITT");  
   pragma Import (C, Pdf_Open_File, "PDF_open_file");  
   pragma Import (C, Pdf_Open_Fp, "PDF_open_fp");  
   pragma Import (C, Pdf_Open_Image, "PDF_open_image");  
   pragma Import (C, Pdf_Open_Image_File, "PDF_open_image_file");  
   pragma Import (C, Pdf_Open_Mem, "PDF_open_mem");  
   pragma Import (C, Pdf_Place_Image, "PDF_place_image");  
   pragma Import (C, Pdf_Rect, "PDF_rect");  
   pragma Import (C, Pdf_Restore, "PDF_restore");  
   pragma Import (C, Pdf_Rotate, "PDF_rotate");  
   pragma Import (C, Pdf_Save, "PDF_save");  
   pragma Import (C, Pdf_Scale, "PDF_scale");  
   pragma Import (C, Pdf_Set_Border_Color, "PDF_set_border_color");
   pragma Import (C, Pdf_Set_Border_Dash, "PDF_set_border_dash");  
   pragma Import (C, Pdf_Set_Border_Style, "PDF_set_border_style");
   pragma Import (C, Pdf_Set_Info, "PDF_set_info");  
   pragma Import (C, Pdf_Set_Parameter, "PDF_set_parameter");  
   pragma Import (C, Pdf_Set_Text_Pos, "PDF_set_text_pos");  
   pragma Import (C, Pdf_Set_Value, "PDF_set_value");  
   pragma Import (C, Pdf_Setcolor, "PDF_setcolor");  
   pragma Import (C, Pdf_Setdash, "PDF_setdash");  
   pragma Import (C, Pdf_Setflat, "PDF_setflat");  
   pragma Import (C, Pdf_Setfont, "PDF_setfont");  
   pragma Import (C, Pdf_Setlinecap, "PDF_setlinecap");  
   pragma Import (C, Pdf_Setlinejoin, "PDF_setlinejoin");  
   pragma Import (C, Pdf_Setlinewidth, "PDF_setlinewidth");  
   pragma Import (C, Pdf_Setmatrix, "PDF_setmatrix");  
   pragma Import (C, Pdf_Setmiterlimit, "PDF_setmiterlimit");  
   pragma Import (C, Pdf_Setpolydash, "PDF_setpolydash");  
   pragma Import (C, Pdf_Show, "PDF_show");  
   pragma Import (C, Pdf_Show2, "PDF_show2");  
   pragma Import (C, Pdf_Show_Boxed, "PDF_show_boxed");  
   pragma Import (C, Pdf_Show_Xy, "PDF_show_xy");  
   pragma Import (C, Pdf_Show_Xy2, "PDF_show_xy2");  
   pragma Import (C, Pdf_Shutdown, "PDF_shutdown");  
   pragma Import (C, Pdf_Skew, "PDF_skew");  
   pragma Import (C, Pdf_Stringwidth, "PDF_stringwidth");  
   pragma Import (C, Pdf_Stringwidth2, "PDF_stringwidth2");  
   pragma Import (C, Pdf_Stroke, "PDF_stroke");  
   pragma Import (C, Pdf_Translate, "PDF_translate");

end Gnu.Pdf;
