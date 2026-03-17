-- ----------------------------------------------------------------- --
--                AdaSDL                                             --
--                Binding to Simple Direct Media Layer               --
--                Copyright (C) 2001 A.M.F.Vargas                    --
--                Antonio M. F. Vargas                               --
--                Ponta Delgada - Azores - Portugal                  --
--                http://www.adapower.net/~avargas                   --
--                E-mail: avargas@adapower.net                       --
-- ----------------------------------------------------------------- --
--                                                                   --
-- This library is free software; you can redistribute it and/or     --
-- modify it under the terms of the GNU General Public               --
-- License as published by the Free Software Foundation; either      --
-- version 2 of the License, or (at your option) any later version.  --
--                                                                   --
-- This library is distributed in the hope that it will be useful,   --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of    --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details.                          --
--                                                                   --
-- You should have received a copy of the GNU General Public         --
-- License along with this library; if not, write to the             --
-- Free Software Foundation, Inc., 59 Temple Place - Suite 330,      --
-- Boston, MA 02111-1307, USA.                                       --
--                                                                   --
-- As a special exception, if other files instantiate generics from  --
-- this unit, or you link this unit with other files to produce an   --
-- executable, this  unit  does not  by itself cause  the resulting  --
-- executable to be covered by the GNU General Public License. This  --
-- exception does not however invalidate any other reasons why the   --
-- executable file  might be covered by the  GNU Public License.     --
-- ----------------------------------------------------------------- --

--  **************************************************************** --
--  This is an Ada binding to SDL ( Simple DirectMedia Layer from    --
--  Sam Lantinga - www.libsld.org )                                  --
--  **************************************************************** --
--  In order to help the Ada programmer, the comments in this file   --
--  are, in great extent, a direct copy of the original text in the  --
--  SDL header files.                                                --
--  **************************************************************** --

with System;
with Interfaces.C.Strings;
with Interfaces.C.Pointers;
with Ada.Unchecked_Conversion;
with Ada.Strings.Unbounded;
with Sdl.Types;                use Sdl.Types;
-- with SDL.Mutex;
with Sdl.Rwops; use type Interfaces.C.int;
package Sdl.Video is

   package Cs renames Interfaces.C.Strings;
   package Us renames Ada.Strings.Unbounded;

   --  Transparency definitions: These define
   --  alpha as the opacity of a surface.
   Alpha_Opaque      : constant := 255;
   Alpha_Transparent : constant := 0;

   --  Useful data types
   type Rect is record
      X, Y : Sint16;
      W, H : Uint16;
   end record;
   pragma Convention (C, Rect);

   type Rect_Ptr is access all Rect;
   pragma Convention (C, Rect_Ptr);
   type Rect_Ptr_Ptr is access all Rect_Ptr;
   pragma Convention (C, Rect_Ptr_Ptr);
   --  type Rects_Array is array (Natural range <>) of aliased Rect;
   type Rects_Array is array (C.unsigned range <>) of aliased Rect;
   type Rects_Array_Access is access all Rects_Array;

   type Color is record
      R, G, B, Unused : Uint8;
   end record;
   pragma Convention (C, Color);

   type Color_Ptr is access all Color;
   pragma Convention (C, Color_Ptr);

   Null_Color : Color := (0, 0, 0, 123);
   type Colors_Array is array (C.size_t range <>) of aliased Color;
   package Color_Ptrops is new C.Pointers (
      Index => C.size_t,
      Element => Color,
      Element_Array => Colors_Array,
      Default_Terminator => Null_Color);
   --  You must do a "use  Color_PtrOps"
   --  in your code

   type Palette is record
      Ncolors : C.int;
      Colors  : Color_Ptr;
   end record;
   pragma Convention (C, Palette);

   type Palette_Ptr is access Palette;
   pragma Convention (C, Palette_Ptr);

   --  Everything in the pixel format structure
   --  is read-only. In Ada this can be controled
   --  using "access constant".
   type Pixelformat is record
      Palette : Palette_Ptr;
      Bitsperpixel, Bytesperpixel, Rloss, Gloss, Bloss, Aloss, Rshift, Gshift,
Bshift, Ashift : Uint8;
      Rmask, Gmask, Bmask, Amask : Uint32;

      --  RGB color key information
      Colorkey : Uint32;

      --  Alpha value information (per-surface alpha)
      Alpha : Uint8;
   end record;
   pragma Convention (C, Pixelformat);

   type Pixelformat_Ptr is access constant Pixelformat;
   pragma Convention (C, Pixelformat_Ptr);

   type Private_Hwdata_Ptr is new System.Address;

   type Blitmap_Ptr is new System.Address;

   type Surface_Flags is mod 2 ** 32;
   for Surface_Flags'Size use 32;

   --  This structure should be treated as read-only
   type Surface is record
      Flags  : Surface_Flags;     --  Read-only
      Format : Pixelformat_Ptr;  --  Read-only
      W, H   : C.int;              --  Read-only
      Pitch  : Uint16;            --  Read-only
      Pixels : System.Address;  --  Read-write
      Offset : C.int;            --  Private

      --  Hardware-specific surface info
      Hwdata : Private_Hwdata_Ptr;

      --  Clipping information
      Clip_Rect : Rect;          --  Read-only
      Unused1   : Uint32;          --  For binary compatibility

      --  Allow recursive locks
      Locked : Uint32;           --  Private

      --  Info for fast blit mapping to other surfaces
      Map : Blitmap_Ptr; --  Private

      --  Format version, bumped at every change to
      --  invalidate blit maps.
      Format_Version : C.unsigned; -- Private

      --  Reference count -- used when freeing surface
      Refcount : C.int;          -- Read-mostly
   end record;
   pragma Convention (C, Surface);

   type Surface_Ptr is access all Surface;
   pragma Convention (C, Surface_Ptr);

   --  These are the currently supported flags for
   --  the SDL_surface.

   --  ----------------------------------------------
   --  Available for CreateRGBSurface or SetVideoMode.

   --  Surface is in system memory
   Swsurface : constant Surface_Flags := 16#00000000#;

   --  Surface is in video memory
   Hwsurface : constant Surface_Flags := 16#00000001#;

   --  Use asynchronous blits if possible
   Asyncblit : constant Surface_Flags := 16#00000004#;

   --  ----------------------------------------------
   --  Available for SetVideoMode

   --  Allow any video depth/pixel-format
   Anyformat : constant Surface_Flags := 16#10000000#;

   --  Surface has exclusive palette
   Hwpalette : constant Surface_Flags := 16#20000000#;

   --  Set up double-buffered video mode
   Doublebuf : constant Surface_Flags := 16#40000000#;

   --  Surface is a full screen display
   Fullscreen : constant Surface_Flags := 16#80000000#;

   --  Create an OpenGL rendering context
   Opengl : constant Surface_Flags := 16#00000002#;

   --  Create an OpenGL rendering context and use if
   --  for blitting
   Openglblit : constant Surface_Flags := 16#0000000A#;

   --  This video mode may be resized
   Resizable : constant Surface_Flags := 16#00000010#;

   --  No window caption or edge frame
   Noframe : constant Surface_Flags := 16#00000020#;

   --  -----------------------------------------------
   --  Use internally (read-only

   --  Blit uses hardware acceleration
   Hwaccel : constant Surface_Flags := 16#00000100#;

   --  Blit uses a source color key
   Srccolorkey : constant Surface_Flags := 16#00001000#;

   --  Private flag
   Rleaccelok : constant Surface_Flags := 16#00002000#;

   --  Surface is RLE encoded
   Rleaccel : constant Surface_Flags := 16#00004000#;

   --  Blit uses source alpha blending
   Srcalpha : constant Surface_Flags := 16#00010000#;

   --  Surface uses preallocated memory
   Prealloc : constant Surface_Flags := 16#01000000#;

   --  Evaluates to true if the surface needs to be locked
   --  before access.
   function Mustlock (Surface : Surface_Ptr) return Boolean;
   pragma Inline (Mustlock);

   --  Useful for determining the video hardware capabilities

   type Videoinfo is record
      Hw_Available : Bits1;  --  Flag: Can you create hardware surfaces?
      Wm_Available : Bits1;  --  Flag: Can you talk to a window manager?
      Unusedbits1  : Bits6;
      Unusedbits2  : Bits1;
      Blit_Hw      : Bits1;  --  Flag: Accelerated blits HW --> HW
      Blit_Hw_Cc   : Bits1;  --  Flag: Accelerated blits with Colorkey
      Blit_Hw_A    : Bits1;  --  Flag: Accelerated blits with Alpha
      Blit_Sw      : Bits1;  --  Flag: Accelerated blits SW --> HW
      Blit_Sw_Cc   : Bits1;  --  Flag: Accelerated blits with Colorkey
      Blit_Sw_A    : Bits1;  --  Flag: Accelerated blits with Alpha
      Blit_Fill    : Bits1;  --  Flag: Accelerated color fill
      Unusedbits3  : Bits16;
      Video_Mem    : Uint32; --  The total amount of video memory (in K)
      --  Value: The format of the video surface
      Vfmt : Pixelformat_Ptr;
   end record;

   -- for Videoinfo use
   --    record
   --       Hw_Available at 0 range 0 .. 0;
   --       Wm_Available at 0 range 1 .. 1;
   --       Unusedbits1 at 0 range 2 .. 7;
   --       Unusedbits2 at 1 range 0 .. 0;
   --       Blit_Hw at 1 range 1 .. 1;
   --       Blit_Hw_Cc at 1 range 2 .. 2;
   --       Blit_Hw_A at 1 range 3 .. 3;
   --       Blit_Sw at 1 range 4 .. 4;
   --       Blit_Sw_Cc at 1 range 5 .. 5;
   --       Blit_Sw_A at 1 range 6 .. 6;
   --       Blit_Fill at 1 range 7 .. 7;
   --       Unusedbits3 at 2 range 0 .. 15;
   --       Video_Mem at 4 range 0 .. 31;
   --       Vfmt at 8 range 0 .. 31;
   --    end record;


   pragma Convention (C, Videoinfo);

   type Videoinfo_Ptr is access all Videoinfo;
   pragma Convention (C, Videoinfo_Ptr);

   type Videoinfo_Constptr is access constant Videoinfo;
   pragma Convention (C, Videoinfo_Constptr);

   --  The most common video ovelay formats.
   --  For an explanation of this pixel formats, see:
   --      http://www.webartz.com/fourcc/indexyuv.htm

   --  For information on the relationship between color spaces, see
   --  http://www.neuro.sfc.keio.ac.jp/~aly/polygon/info/color-space-faq.html

   --  Planar mode: Y + V + U (3 planes)
   Yv12_Overlay : constant := 16#32315659#;
   --  Planar mode: Y + U + V (3 planes)
   Iyuv_Overlay : constant := 16#56555949#;
   --  Packed mode: Y0 + U0 + Y1 + V0 (1 plane)
   Yuy2_Overlay : constant := 16#32595559#;
   --  Packed mode: U0 + Y0 + V0 + Y1 (1 plane)
   Uyvy_Overlay : constant := 16#59565955#;
   --  Packed mode: Y0 + V0 + Y1 + U0 (1 plane)
   Yvyu_Overlay : constant := 16#55595659#;

   type Private_Yuvhwfuncs_Ptr is new System.Address;
   type Private_Yuvhwdata_Ptr is new System.Address;

   --  The YUV hardware video overlay
   type Overlay is record
      Format  : Uint32;          --  Read-only
      H, W    : C.int;            --  Read-only
      Planes  : C.int;           --  Read-only
      Pitches : Uint16_Ptr;     --  Read-only
      Pixels  : Uint8_Ptr_Ptr;   --  Read-write

      --  Hardware-specific surface info
      Hwfuncs : Private_Yuvhwfuncs_Ptr;
      Hwdata  : Private_Yuvhwdata_Ptr;

      --  Special flags
      Hw_Overlay : Bits1;
      Unusedbits : Bits31;
   end record;

   -- for Overlay use
   --    record
   --       Format at 0 range 0 .. 31;
   --       H at 4 range 0 .. 31;
   --       W at 8 range 0 .. 31;
   --       Planes at 12 range 0 .. 31;
   --       Pitches at 16 range 0 .. 31;
   --       Pixels at 20 range 0 .. 31;
   --       Hwfuncs at 24 range 0 .. 31;
   --       Hwdata at 28 range 0 .. 31;
   --       Hw_Overlay at 32 range 0 .. 0;
   --       Unusedbits at 32 range 1 .. 31;
   --    end record;

   pragma Convention (C, Overlay);

   type Overlay_Ptr is access all Overlay;
   pragma Convention (C, Overlay_Ptr);

   type Glattr is new C.int;
   Gl_Red_Size         : constant Glattr := 0;
   Gl_Green_Size       : constant Glattr := 1;
   Gl_Blue_Size        : constant Glattr := 2;
   Gl_Alpha_Size       : constant Glattr := 3;
   Gl_Buffer_Size      : constant Glattr := 4;
   Gl_Doublebuffer     : constant Glattr := 5;
   Gl_Depth_Size       : constant Glattr := 6;
   Gl_Stencil_Size     : constant Glattr := 7;
   Gl_Accum_Red_Size   : constant Glattr := 8;
   Gl_Accum_Green_Size : constant Glattr := 9;
   Gl_Accum_Blue_Size  : constant Glattr := 10;
   Gl_Accum_Alpha_Size : constant Glattr := 11;

   Logpal  : constant := 16#01#;
   Physpal : constant := 16#02#;

   ---------------------------
   --  Function prototypes  --
   ---------------------------

   --  These functions are used internally, and should
   --  not be used unless you have a specific need to specify
   --  the video driver you want to use.
   --
   --  Binding note: I will not make this functions private
   --  because I wish to make them available just like the
   --  original C interface.
   --
   --  VideoInit initializes the video  subsystem --
   --  sets up a connection to the window manager, etc, and
   --  determines the current video mode and pixel format,
   --  but does not initialize a window or graphics mode.
   --  Note that event handling is activated by this routine.
   --
   --  If you use both sound and video in you application, you
   --  need to call Init before opening the sound device,
   --  otherwise under Win32 DirectX, you won't be able to set
   --  the full-screen display modes.

   function Videoinit
     (Namebuf : C.Strings.chars_ptr;
      Maxlen  : C.int)
      return    C.Strings.chars_ptr;
   pragma Import (C, Videoinit, "SDL_VideoInit");

   procedure Videoquit;
   pragma Import (C, Videoquit, "SDL_VideoQuit");

   --  This function fills the given character buffer with the
   --  name of the video driver, and returns a pointer to it
   --  if the video driver has been initialized. It returns NULL
   --  if no driver has been initialized.
   function Videodrivername
     (Namebuf : C.Strings.chars_ptr;
      Maxlen  : C.int)
      return    C.Strings.chars_ptr;
   pragma Import (C, Videodrivername, "SDL_VideoDriverName");

   --  This function returns a pointer to the current display
   --  surface. If SDL is doing format conversion on the display
   --  surface, this function returns the publicly visible surface,
   --  not the real video surface.
   function Getvideosurface return Surface_Ptr;
   pragma Import (C, Getvideosurface, "SDL_GetVideoSurface");

   --  This function returns a Read-only pointer to information
   --  about the video hardware. If this is called before SetVideoMode,
   --  the 'vfmt' member of the returned structure will contain the
   --  pixel format of the "best" video mode.
   function Getvideoinfo return Videoinfo_Constptr;
   pragma Import (C, Getvideoinfo, "SDL_GetVideoInfo");

   --  Check to see if a particular video mode is supported.
   --  It returns 0 if the requested video mode is not supported
   --  under any bit depth, or retuns the bits-per-pixel of the
   --  closest available mode with the given width and height. If
   --  this bits-per-pixel is different from the one used when
   --  setting the video mode, SetVideoMode will succeed, but
   --  will emulate the requested bits-per-pixel with a shadow
   --  surface.
   --
   --  The arguments to VideoModeOK are the same ones you would
   --  pass to SetVideoMode.
   function Videomodeok
     (Width  : C.int;
      Height : C.int;
      Bpp    : C.int;
   --  flags  : Uint32)
      Flags  : Surface_Flags)
      return   C.int;
   pragma Import (C, Videomodeok, "SDL_VideoModeOK");

   --  Return a pointer to an array of available screen dimensions
   --  for the given format and video flags, sorted largest to
   --  smallest. Returns NULL if there are no dimensions available
   --  for a particular format, or Rect_ptr_ptr(-1) if any dimension
   --  is okay for the given format.
   --
   --  If 'format' is NULL, the mode list will be the format given
   --  by GetVideoInfo.all.vfmt
   function Listmodes
     (Format : Pixelformat_Ptr;
      Flags  : Surface_Flags)
      return   Rect_Ptr_Ptr;
   pragma Import (C, Listmodes, "SDL_ListModes");

   --  Necessary to verify if ListModes returns
   --  a non-pointer value like 0 or -1.
   function Rectpp_To_Int is new Ada.Unchecked_Conversion (
      Rect_Ptr_Ptr,
      C.int);

   --  Necessary to manipulate C pointer from Ada
   type Rect_Ptr_Array is array (C.size_t range <>) of aliased Rect_Ptr;
   package Rect_Ptr_Ptrops is new C.Pointers (
      Index => C.size_t,
      Element => Rect_Ptr,
      Element_Array => Rect_Ptr_Array,
      Default_Terminator => null);
   --  You must do a --> use Rect_ptr_Ptrs; in your code.

   --  The limit of 20 is arbitrary
   --  The array scan should stop before 20 when a null is found.
   --  type Modes_Array is array (0 .. 19) of Rect_ptr;
   --  function ListModes (
   --     format : PixelFormat_ptr;
   --     flags  : Surface_Flags)
   --     return Modes_Array;
   --  pragma Import (C, ListModes, "SDL_ListModes");

   --  Set up a video mode with the specified width, height and
   --  and bits-per-pixel.
   --
   --  If 'bpp' is 0, it is treated as the current display
   --  bits-per-pixel.
   --
   --  If ANYFORMAT is set in 'flags', the SDL library will
   --  try to set the requestd bits-per-pixel, but will return
   --  whatever video pixel format is available. The default is
   --  to emulate the requested pixel format if it is not natively
   --  available.
   --
   --  If HWSURFACE is set in 'flags', the video surface will be
   --  placed in video memory, if possible, and you may have to
   --  call LockSurface in order to access the raw buffer. Otherwise
   --  the video surface will be created in the system memory.
   --
   --  If ASYNCBLIT is set in 'flags', SDL will try to perform
   --  rectangle updates asynchronously, but you must always lock
   --  before accessing pixels. SDL will wait for updates to
   --  complete before returning from the lock.
   --
   --  If HWPALETTE is set in 'flags', the SDL library will
   --  garantee that the colors set by SetColors will be the
   --  colors you get. Otherwise, in 8-bit mode, SetColors my
   --  not be able to set all of the colors exactly the way
   --  they are requested, and you should look at the video
   --  surface structure to determine the actual palette. If
   --  SDL cannot garantee that the colors you request can be
   --  set, i.e. if the color map is shared, then the video
   --  surface my be created under emulation in system memory,
   --  overriding the HWSURFACE flag.
   --
   --  If FULLSCREEN is set in 'flags', the SDL library will
   --  try to set a fullscreen video mode. The default is to
   --  create a windowed mode if the current graphics system
   --  has a window manager.
   --  If the SDL library is able to set a fullscreen mode,
   --  this flag will be set in the surface that is returned.
   --
   --  If DOUBLEBUF is set in 'flags', the SDL library will
   --  try to set up two surfaces in video memory and swap
   --  between them when you call Flip. This is usually slower
   --  than the normal single-buffering scheme, but prevents
   --  "tearing" artifacts caused by modifying video memory
   --  while the monitor is refreshing. It should only be used
   --  by applications that redraw the entire screen on every
   --  update.
   --
   --  This function returns the video buffer surface, or NULL
   --  if it fails.
   function Setvideomode
     (Width  : C.int;
      Height : C.int;
      Bpp    : C.int;
      Flags  : Surface_Flags)
      return   Surface_Ptr;
   pragma Import (C, Setvideomode, "SDL_SetVideoMode");

   --  Makes sure the given list of rectangles is updated on the
   --  given screen. If 'x','y','w' and 'h' are all 0, UpdateRect
   --  will update the entire screen.
   --  These functions  should  not be called while 'screen' is locked.
   procedure Updaterects
     (Screen   : Surface_Ptr;
      Numrects : C.int;
      Rects    : Rect_Ptr);

   procedure Updaterects
     (Screen   : Surface_Ptr;
      Numrects : C.int;
      Rects    : Rects_Array);

   pragma Import (C, Updaterects, "SDL_UpdateRects");

   procedure Updaterect
     (Screen : Surface_Ptr;
      X      : Sint32;
      Y      : Sint32;
      W      : Uint32;
      H      : Uint32);
   pragma Import (C, Updaterect, "SDL_UpdateRect");

   procedure Update_Rect (Screen : Surface_Ptr; The_Rect : Rect);
   pragma Inline (Update_Rect);

   --  On hardware that supports double-buffering, this function sets up a flip
   --  and returns.  The hardware will wait for vertical retrace, and then swap
   --  video buffers before the next video surface blit or lock will return.
   --  On hardware that doesn not support double-buffering, this is equivalent
   --  to calling UpdateRect (screen, 0, 0, 0, 0);
   --  The DOUBLEBUF flag must have been passed to SetVideoMode when
   --  setting the video mode for this function to perform hardware flipping.
   --  This function returns 0 if successful, or -1 if there was an error.
   function Flip (Screen : Surface_Ptr) return C.int;
   procedure Flip (Screen : Surface_Ptr);
   pragma Import (C, Flip, "SDL_Flip");

   --  Set the gamma correction for each of the color channels.
   --  The gamma values range (approximately) between 0.1 and 10.0
   --
   --  If this function isn't supported directly by the hardware, it will
   --  be emulated using gamma ramps, if available.  If successful, this
   --  function returns 0, otherwise it returns -1.
   function Setgamma
     (Red   : C.C_float;
      Green : C.C_float;
      Blue  : C.C_float)
      return  C.int;

   procedure Setgamma
     (Red   : C.C_float;
      Green : C.C_float;
      Blue  : C.C_float);

   pragma Import (C, Setgamma, "SDL_SetGamma");

   --  Set the gamma translation table for the red, green, and blue channels
   --  of the video hardware.  Each table is an array of 256 16-bit quantities,
   --  representing a mapping between the input and output for that channel.
   --  The input is the index into the array, and the output is the 16-bit
   --  gamma value at that index, scaled to the output color precision.
   --
   --  You may pass NULL for any of the channels to leave it unchanged.
   --  If the call succeeds, it will return 0.  If the display driver or
   --  hardware does not support gamma translation, or otherwise fails,
   --  this function will return -1.
   function Setgammaramp
     (Red   : Uint16_Ptr;
      Green : Uint16_Ptr;
      Blue  : Uint16_Ptr)
      return  C.int;

   type Ramp_Array is array (Natural range 0 .. 255) of aliased Uint16;

   function Setgammaramp
     (Red   : Ramp_Array;
      Green : Ramp_Array;
      Blue  : Ramp_Array)
      return  C.int;

   pragma Import (C, Setgammaramp, "SDL_SetGammaRamp");

   --  Retrieve the current values of the gamma translation tables.
   --
   --  You must pass in valid pointers to arrays of 256 8-bit quantities.
   --  Any of the pointers may be NULL to ignore that channel.
   --  If the call succeeds, it will return 0.  If the display driver or
   --  hardware does not support gamma translation, or otherwise fails,
   --  this function will return -1.
   function Getgammaramp
     (Red   : Uint16_Ptr;
      Green : Uint16_Ptr;
      Blue  : Uint16_Ptr)
      return  C.int;
   pragma Import (C, Getgammaramp, "SDL_GetGammaRamp");

   --  Sets a portion of the colormap for the given 8-bit surface.  If
   --  'surface' is not a palettized surface, this function does nothing,
   --  returning 0. If all of the colors were set as passed to SetColors,
   --  it will return 1.  If not all the color entries were set exactly as
   --  given, it will return 0, and you should look at the surface palette to
   --  determine the actual color palette.
   --
   --  When 'surface' is the surface associated with the current display, the
   --  display colormap will be updated with the requested colors.  If
   --  HWPALETTE was set in SetVideoMode flags, SetColors
   --  will always return 1, and the palette is guaranteed to be set the way
   --  you desire, even if the window colormap has to be warped or run under
   --  emulation.
   function Setcolors
     (Surface    : Surface_Ptr;
      Colors     : Color_Ptr;
      Firstcolor : C.int;
      Ncolor     : C.int)
      return       C.int;

   procedure Setcolors
     (Surface    : Surface_Ptr;
      Colors     : Color_Ptr;
      Firstcolor : C.int;
      Ncolor     : C.int);

   function Setcolors
     (Surface    : Surface_Ptr;
      Colors     : Colors_Array;
      Firstcolor : C.int;
      Ncolor     : C.int)
      return       C.int;

   procedure Setcolors
     (Surface    : Surface_Ptr;
      Colors     : Colors_Array;
      Firstcolor : C.int;
      Ncolor     : C.int);

   pragma Import (C, Setcolors, "SDL_SetColors");

   --  Sets a portion of the colormap for a given 8-bit surface.
   --  'flags' is one or both of:
   --  LOGPAL  -- set logical palette, which controls how blits are mapped
   --                 to/from the surface,
   --  PHYSPAL -- set physical palette, which controls how pixels look on
   --                 the screen
   --  Only screens have physical palettes. Separate change of physical/logical
   --  palettes is only possible if the screen has HWPALETTE set.
   --
   --  The return value is 1 if all colours could be set as requested, and 0
   --  otherwise.
   --
   --  SetColors is equivalent to calling this function with
   --      flags = (LOGPAL or PHYSPAL).
   function Setpalette
     (Surface    : Surface_Ptr;
      Flags      : C.int;
      Colors     : Color_Ptr;
      Firstcolor : C.int;
      Ncolors    : C.int)
      return       C.int;

   function Setpalette
     (Surface    : Surface_Ptr;
      Flags      : C.int;
      Colors     : Colors_Array;
      Firstcolor : C.int;
      Ncolors    : C.int)
      return       C.int;

   procedure Setpalette
     (Surface    : Surface_Ptr;
      Flags      : C.int;
      Colors     : Color_Ptr;
      Firstcolor : C.int;
      Ncolors    : C.int);

   procedure Setpalette
     (Surface    : Surface_Ptr;
      Flags      : C.int;
      Colors     : Colors_Array;
      Firstcolor : C.int;
      Ncolors    : C.int);

   pragma Import (C, Setpalette, "SDL_SetPalette");

   --  Maps an RGB triple to an opaque pixel value for a given pixel format
   function Maprgb
     (Format : Pixelformat_Ptr;
      R      : Uint8;
      G      : Uint8;
      B      : Uint8)
      return   Uint32;
   pragma Import (C, Maprgb, "SDL_MapRGB");

   --  Maps an RGBA quadruple to a pixel value for a given pixel format
   function Maprgba
     (Format : Pixelformat_Ptr;
      R      : Uint8;
      G      : Uint8;
      B      : Uint8;
      A      : Uint8)
      return   Uint32;
   pragma Import (C, Maprgba, "SDL_MapRGBA");

   --  Maps a pixel value into the RGB components for a given pixel format
   procedure Getrgb
     (Pixel : Uint32;
      Fmt   : Pixelformat_Ptr;
      R     : Uint8_Ptr;
      G     : Uint8_Ptr;
      B     : Uint8_Ptr);
   pragma Import (C, Getrgb, "SDL_GetRGB");

   --  Maps a pixel value into the RGBA components for a given pixel format
   procedure Getrgba
     (Pixel : Uint32;
      Fmt   : Pixelformat_Ptr;
      R     : Uint8_Ptr;
      G     : Uint8_Ptr;
      B     : Uint8_Ptr;
      A     : Uint8_Ptr);
   pragma Import (C, Getrgba, "SDL_GetRGBA");

   --  Allocate and free an RGB surface (must be called after SetVideoMode)
   --  If the depth is 4 or 8 bits, an empty palette is allocated for the
   --  surface. If the depth is greater than 8 bits, the pixel format is set
   --  using the flags '[RGB]mask'.
   --  If the function runs out of memory, it will return NULL.
   --
   --  The 'flags' tell what kind of surface to create.
   --  SWSURFACE means that the surface should be created in system memory.
   --  HWSURFACE means that the surface should be created in video memory,
   --  with the same format as the display surface.  This is useful for
   --  surfaces that will not change much, to take advantage of hardware
   --  acceleration when being blitted to the display surface.
   --  ASYNCBLIT means that SDL will try to perform asynchronous blits with
   --  this surface, but you must always lock it before accessing the pixels.
   --  SDL will wait for current blits to finish before returning from the
   --  lock. SRCCOLORKEY indicates that the surface will be used for colorkey
   --  blits. If the hardware supports acceleration of colorkey blits between
   --  two surfaces in video memory, SDL will try to place the surface in
   --  video memory. If this isn't possible or if there is no hardware
   --  acceleration available, the surface will be placed in system memory.
   --  SRCALPHA means that the surface will be used for alpha blits and
   --  if the hardware supports hardware acceleration of alpha blits between
   --  two surfaces in video memory, to place the surface in video memory
   --  if possible, otherwise it will be placed in system memory.
   --  If the surface is created in video memory, blits will be _much_ faster,
   --  but the surface format must be identical to the video surface format,
   --  and the only way to access the pixels member of the surface is to use
   --  the LockSurface and UnlockSurface calls.
   --  If the requested surface actually resides in video memory, HWSURFACE
   --  will be set in the flags member of the returned surface.  If for some
   --  reason the surface could not be placed in video memory, it will not have
   --  the HWSURFACE flag set, and will be created in system memory instead.
   function Creatergbsurface
     (Flags  : Surface_Flags;
      Width  : C.int;
      Height : C.int;
      Depth  : C.int;
      Rmask  : Uint32;
      Gmask  : Uint32;
      Bmask  : Uint32;
      Amask  : Uint32)
      return   Surface_Ptr;
   pragma Import (C, Creatergbsurface, "SDL_CreateRGBSurface");

   function Creatergbsurfacefrom
     (Pixels : Void_Ptr;
      Width  : C.int;
      Height : C.int;
      Depth  : C.int;
      Pitch  : C.int;
      Rmask  : Uint32;
      Gmask  : Uint32;
      Bmask  : Uint32;
      Amask  : Uint32)
      return   Surface_Ptr;
   pragma Import (C, Creatergbsurfacefrom, "SDL_CreateRGBSurfaceFrom");

   procedure Freesurface (Surface : Surface_Ptr);
   pragma Import (C, Freesurface, "SDL_FreeSurface");

   function Allocsurface
     (Flags  : Surface_Flags;
      Width  : C.int;
      Height : C.int;
      Depth  : C.int;
      Rmask  : Uint32;
      Gmask  : Uint32;
      Bmask  : Uint32;
      Amask  : Uint32)
      return   Surface_Ptr renames Creatergbsurface;

   --  LockSurface sets up a surface for directly accessing the pixels.
   --  Between calls to LockSurface/UnlockSurface, you can write
   --  to and read from 'the_surface_ptr.pixels', using the pixel format
   --  stored in  'the_surface_ptr.format'.  Once you are done accessing
   --  the surface, you should use UnlockSurface to release it.
   --
   --  Not all surfaces require locking.  If MUSTLOCK(surface) evaluates
   --  to 0, then you can read and write to the surface at any time, and the
   --  pixel format of the surface will not change.  In particular, if the
   --  HWSURFACE flag is not given when calling SetVideoMode, you
   --  will not need to lock the display surface before accessing it.
   --
   --  No operating system or library calls should be made between lock/unlock
   --  pairs, as critical system locks may be held during this time.
   --
   --  LockSurface returns 0, or -1 if the surface couldn't be locked.
   function Locksurface (Surface : Surface_Ptr) return C.int;
   pragma Import (C, Locksurface, "SDL_LockSurface");

   procedure Unlocksurface (Surface : Surface_Ptr);
   pragma Import (C, Unlocksurface, "SDL_UnlockSurface");

   --  Load a surface from a seekable SDL data source (memory or file.)
   --  If 'freesrc' is non-zero, the source will be closed after being read.
   --  Returns the new surface, or NULL if there was an error.
   --  The new surface should be freed with FreeSurface.
   function Loadbmp_Rw
     (Src     : Sdl.Rwops.Rwops_Ptr;
      Freesrc : C.int)
      return    Surface_Ptr;
   pragma Import (C, Loadbmp_Rw, "SDL_LoadBMP_RW");

   --  Load a surface from a file.
   function Loadbmp (File : C.Strings.chars_ptr) return Surface_Ptr;
   pragma Inline (Loadbmp);

   function Loadbmp (File : String) return Surface_Ptr;
   pragma Inline (Loadbmp);

   --  Save a surface to a seekable SDL data source (memory or file.)
   --  If 'freedst' is non-zero, the source will be closed after being written.
   --  Returns 0 if successful or -1 if there was an error.
   function Savebmp_Rw
     (Surface : Surface_Ptr;
      Dst     : Sdl.Rwops.Rwops_Ptr;
      Freedst : C.int)
      return    C.int;
   pragma Import (C, Savebmp_Rw, "SDL_SaveBMP_RW");

   --  Save a surface to a file
   function Savebmp
     (Surface : Surface_Ptr;
      File    : C.Strings.chars_ptr)
      return    C.int;
   pragma Inline (Savebmp);

   --  Sets the color key (transparent pixel) in a blittable surface.
   --  If 'flag' is SRCCOLORKEY (optionally OR'd with RLEACCEL),
   --  'key' will be the transparent pixel in the source image of a blit.
   --  RLEACCEL requests RLE acceleration for the surface if present,
   --  and removes RLE acceleration if absent.
   --  If 'flag' is 0, this function clears any current color key.
   --  This function returns 0, or -1 if there was an error.
   function Setcolorkey
     (Surface : Surface_Ptr;
   --  flag    : Uint32;
      Flag    : Surface_Flags;
      Key     : Uint32)
      return    C.int;

   procedure Setcolorkey
     (Surface : Surface_Ptr;
   --  flag    : Uint32;
      Flag    : Surface_Flags;
      Key     : Uint32);

   pragma Import (C, Setcolorkey, "SDL_SetColorKey");

   --  This function sets the alpha value for the entire surface, as opposed to
   --  using the alpha component of each pixel. This value measures the range
   --  of transparency of the surface, 0 being completely transparent to 255
   --  being completely opaque. An 'alpha' value of 255 causes blits to be
   --  opaque, the source pixels copied to the destination (the default). Note
   --  that per-surface alpha can be combined with colorkey transparency.
   --
   --  If 'flag' is 0, alpha blending is disabled for the surface.
   --  If 'flag' is SRCALPHA, alpha blending is enabled for the surface.
   --  OR:ing the flag with RLEACCEL requests RLE acceleration for the
   --  surface; if RLEACCEL is not specified, the RLE accel will be removed.
   function Setalpha
     (Surface : Surface_Ptr;
      Flag    : Surface_Flags;
      Alpha   : Uint8)
      return    C.int;

   procedure Setalpha
     (Surface : Surface_Ptr;
      Flag    : Surface_Flags;
      Alpha   : Uint8);

   pragma Import (C, Setalpha, "SDL_SetAlpha");

   --  Sets the clipping rectangle for the destination surface in a blit.
   --
   --  If the clip rectangle is NULL, clipping will be disabled.
   --  If the clip rectangle doesn't intersect the surface, the function will
   --  return SDL_FALSE and blits will be completely clipped.  Otherwise the
   --  function returns SDL_TRUE and blits to the surface will be clipped to
   --  the intersection of the surface area and the clipping rectangle.
   --
   --  Note that blits are automatically clipped to the edges of the source
   --  and destination surfaces.
   function Setcliprect
     (Surface : Surface_Ptr;
      Rect    : Rect_Ptr)
      return    C.int;  -- The return must be SDL_true or SDL_false,

   function Setcliprect
     (Surface  : Surface_Ptr;
      The_Rect : Rect)
      return     C.int;  -- The return must be SDL_true or SDL_false,

   procedure Setcliprect (Surface : Surface_Ptr; Rect : Rect_Ptr);

   procedure Setcliprect (Surface : Surface_Ptr; The_Rect : Rect);

   pragma Import (C, Setcliprect, "SDL_SetClipRect");

   procedure Disable_Clipping (Surface : Surface_Ptr);
   pragma Inline (Disable_Clipping);

   --  Gets the clipping rectangle for the destination surface in a blit.
   --  'prect' must be a pointer to a valid rectangle which will be filled
   --   with the correct values.
   procedure Getcliprect (Surface : Surface_Ptr; Prect : access Rect);

   procedure Getcliprect (Surface : Surface_Ptr; The_Rect : Rect);

   pragma Import (C, Getcliprect, "SDL_GetClipRect");

   --  Creates a new surface of the specified format, and then copies and maps
   --  the given surface to it so the blit of the converted surface will be as
   --  fast as possible.  If this function fails, it returns NULL.
   --
   --  The 'flags' parameter is passed to CreateRGBSurface and has those
   --  semantics.
   --
   --  This function is used internally by SDL_DisplayFormat.
   function Convertsurface
     (Src   : Surface_Ptr;
      Fmt   : Pixelformat_Ptr;
      Flags : Surface_Flags)
      return  Surface_Ptr;
   pragma Import (C, Convertsurface, "SDL_ConvertSurface");

   --  This performs a fast blit from the source surface to the destination
   --  surface.  It assumes that the source and destination rectangles are
   --  the same size.  If either 'srcrect' or 'dstrect' are NULL, the entire
   --  surface (src or dst) is copied.  The final blit rectangles are saved
   --  in 'srcrect' and 'dstrect' after all clipping is performed.
   --  If the blit is successful, it returns 0, otherwise it returns -1.
   --
   --  The blit function should not be called on a locked surface.
   --
   --  The blit semantics for surfaces with and without alpha and colorkey
   --  are defined as follows:
   --
   --  RGBA->RGB:
   --      SDL_SRCALPHA set:
   --       alpha-blend (using alpha-channel).
   --       SDL_SRCCOLORKEY ignored.
   --      SDL_SRCALPHA not set:
   --       copy RGB.
   --       if SDL_SRCCOLORKEY set, only copy the pixels matching the
   --       RGB values of the source colour key, ignoring alpha in the
   --       comparison.
   --
   --  RGB->RGBA:
   --      SDL_SRCALPHA set:
   --       alpha-blend (using the source per-surface alpha value);
   --       set destination alpha to opaque.
   --      SDL_SRCALPHA not set:
   --       copy RGB, set destination alpha to opaque.
   --      both:
   --       if SDL_SRCCOLORKEY set, only copy the pixels matching the
   --       source colour key.
   --
   --  RGBA->RGBA:
   --      SDL_SRCALPHA set:
   --       alpha-blend (using the source alpha channel) the RGB values;
   --       leave destination alpha untouched. [Note: is this correct?]
   --       SDL_SRCCOLORKEY ignored.
   --      SDL_SRCALPHA not set:
   --       copy all of RGBA to the destination.
   --       if SDL_SRCCOLORKEY set, only copy the pixels matching the
   --       RGB values of the source colour key, ignoring alpha in the
   --       comparison.
   --
   --  RGB->RGB:
   --      SDL_SRCALPHA set:
   --       alpha-blend (using the source per-surface alpha value).
   --      SDL_SRCALPHA not set:
   --       copy RGB.
   --      both:
   --       if SDL_SRCCOLORKEY set, only copy the pixels matching the
   --       source colour key.

   --  If either of the surfaces were in video memory, and the blit returns -2,
   --  the video memory was lost, so it should be reloaded with artwork and
   --  re-blitted:
   --   while BlitSurface (image, imgrect, screen, dstrect) = -2  loop
   --      while SDL_LockSurface (image) < 0 loop
   --         Sleep(10);
   --      end loop;
   --      -- Write image pixels to image->pixels --
   --      UnlockSurface (image);
   --   end loop;
   --  This happens under DirectX 5.0 when the system switches away from your
   --  fullscreen application.  The lock will also fail until you have access
   --  to the video memory again.

   --  This is the public blit function, BlitSurface, and it performs
   --  rectangle validation and clipping before passing it to LowerBlit
   function Upperblit
     (Src     : Surface_Ptr;
      Srcrect : Rect_Ptr;
      Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr)
      return    C.int;

   function Upperblit
     (Src     : Surface_Ptr;
      Srcrect : Rect;
      Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr)
      return    C.int;

   function Upperblit
     (Src     : Surface_Ptr;
      Srcrect : Rect_Ptr;
      Dst     : Surface_Ptr;
      Dstrect : Rect)
      return    C.int;

   function Upperblit
     (Src     : Surface_Ptr;
      Srcrect : Rect;
      Dst     : Surface_Ptr;
      Dstrect : Rect)
      return    C.int;

   procedure Upperblit
     (Src     : Surface_Ptr;
      Srcrect : Rect_Ptr;
      Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr);

   procedure Upperblit
     (Src     : Surface_Ptr;
      Srcrect : Rect;
      Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr);

   procedure Upperblit
     (Src     : Surface_Ptr;
      Srcrect : Rect_Ptr;
      Dst     : Surface_Ptr;
      Dstrect : Rect);

   procedure Upperblit
     (Src     : Surface_Ptr;
      Srcrect : Rect;
      Dst     : Surface_Ptr;
      Dstrect : Rect);

   pragma Import (C, Upperblit, "SDL_UpperBlit");

   --  You should call BlitSurface unless you know exactly how SDL
   --  blitting works internally and how to use the other blit functions.
   function Blitsurface
     (Src     : Surface_Ptr;
      Srcrect : Rect_Ptr;
      Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr)
      return    C.int renames Upperblit;

   function Blitsurface
     (Src     : Surface_Ptr;
      Srcrect : Rect;
      Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr)
      return    C.int renames Upperblit;

   function Blitsurface
     (Src     : Surface_Ptr;
      Srcrect : Rect_Ptr;
      Dst     : Surface_Ptr;
      Dstrect : Rect)
      return    C.int renames Upperblit;

   function Blitsurface
     (Src     : Surface_Ptr;
      Srcrect : Rect;
      Dst     : Surface_Ptr;
      Dstrect : Rect)
      return    C.int renames Upperblit;

   procedure Blitsurface
     (Src     : Surface_Ptr;
      Srcrect : Rect_Ptr;
      Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr) renames Upperblit;

   procedure Blitsurface
     (Src     : Surface_Ptr;
      Srcrect : Rect;
      Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr) renames Upperblit;

   procedure Blitsurface
     (Src     : Surface_Ptr;
      Srcrect : Rect_Ptr;
      Dst     : Surface_Ptr;
      Dstrect : Rect) renames Upperblit;

   procedure Blitsurface
     (Src     : Surface_Ptr;
      Srcrect : Rect;
      Dst     : Surface_Ptr;
      Dstrect : Rect) renames Upperblit;

   --  This is a semi-private blit function and it performs low-level surface
   --  blitting only.
   function Lowerblit
     (Src     : Surface_Ptr;
      Srcrect : Rect_Ptr;
      Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr)
      return    C.int;
   pragma Import (C, Lowerblit, "SDL_LowerBlit");

   --  This function performs a fast fill of the given rectangle with 'color'
   --  The given rectangle is clipped to the destination surface clip area
   --  and the final fill rectangle is saved in the passed in pointer.
   --  If 'dstrect' is NULL, the whole surface will be filled with 'color'
   --  The color should be a pixel of the format used by the surface, and
   --  can be generated by the MapRGB function.
   --  This function returns 0 on success, or -1 on error.
   function Fillrect
     (Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr;
      Color   : Uint32)
      return    C.int;

   procedure Fillrect
     (Dst     : Surface_Ptr;
      Dstrect : Rect_Ptr;
      Color   : Uint32);

   procedure Fillrect
     (Dst     : Surface_Ptr;
      Dstrect : in out Rect; --  Not really changed inside FillRect.
      Color   : Uint32);     --     bu used to avoid some Unchecked_Access

   pragma Import (C, Fillrect, "SDL_FillRect");

   --  This function takes a surface and copies it to a new surface of the
   --  pixel format and colors of the video framebuffer, suitable for fast
   --  blitting onto the display surface.  It calls ConvertSurface
   --
   --  If you want to take advantage of hardware colorkey or alpha blit
   --  acceleration, you should set the colorkey and alpha value before
   --  calling this function.
   --
   --  If the conversion fails or runs out of memory, it returns NULL
   function Displayformat (Surface : Surface_Ptr) return Surface_Ptr;
   pragma Import (C, Displayformat, "SDL_DisplayFormat");

   --  This function takes a surface and copies it to a new surface of the
   --  pixel format and colors of the video framebuffer (if possible),
   --  suitable for fast alpha blitting onto the display surface.
   --  The new surface will always have an alpha channel.
   --
   --  If you want to take advantage of hardware colorkey or alpha blit
   --  acceleration, you should set the colorkey and alpha value before
   --  calling this function.
   --
   --  If the conversion fails or runs out of memory, it returns NULL
   function Displayformatalpha (Surface : Surface_Ptr) return Surface_Ptr;
   pragma Import (C, Displayformatalpha, "SDL_DisplayFormatAlpha");

   --  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
   --  * YUV video surface overlay functions                               *
   --  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

   --  This function creates a video output overlay
   --  Calling the returned surface an overlay is something of a misnomer
   --  because the contents of the display surface underneath the area where
   --  the overlay is shown is undefined - it may be overwritten with the
   --  converted YUV data.
   function Createyuvoverlay
     (Width   : C.int;
      Height  : C.int;
      Format  : Uint32;
      Display : Surface_Ptr)
      return    Overlay_Ptr;
   pragma Import (C, Createyuvoverlay, "SDL_CreateYUVOverlay");

   --  Lock an overlay for direct access, and unlock it when you are done
   function Lockyuvoverlay (Overlay : Overlay_Ptr) return C.int;
   pragma Import (C, Lockyuvoverlay, "SDL_LockYUVOverlay");

   procedure Unlockyuvoverlay (Overlay : Overlay_Ptr);
   pragma Import (C, Unlockyuvoverlay, "SDL_UnlockYUVOverlay");

   --  Blit a video overlay to the display surface.
   --  The contents of the video surface underneath the blit destination are
   --  not defined.
   --  The width and height of the destination rectangle may be different from
   --  that of the overlay, but currently only 2x scaling is supported.
   function Displayyuvoverlay
     (Overlay : Overlay_Ptr;
      Dstrect : Rect_Ptr)
      return    C.int;
   pragma Import (C, Displayyuvoverlay, "SDL_DisplayYUVOverlay");

   --  Free a video overlay
   procedure Freeyuvoverlay (Overlay : Overlay_Ptr);
   pragma Import (C, Freeyuvoverlay, "SDL_FreeYUVOverlay");

   --  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
   --  * OpenGL support functions.                                     *
   --  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

   --  *
   --  * Dynamically load a GL driver, if SDL is built with dynamic GL.
   --  *
   --  * SDL links normally with the OpenGL library on your system by default,
   --  * but you can compile it to dynamically load the GL driver at runtime.
   --  * If you do this, you need to retrieve all of the GL functions used in
   --  * your program from the dynamic library using GL_GetProcAddress.
   --  *
   --  * This is disabled in default builds of SDL.
   function Gl_Loadlibrary (Path : C.Strings.chars_ptr) return C.int;
   pragma Import (C, Gl_Loadlibrary, "SDL_GL_LoadLibrary");

   --  Get the address of a GL function (for extension functions)
   procedure Gl_Getprocaddress (Proc : C.Strings.chars_ptr);
   pragma Import (C, Gl_Getprocaddress, "SDL_GL_GetProcAddress");

   --  Set an attribute of the OpenGL subsystem before intialization.
   function Gl_Setattribute (Attr : Glattr; Value : C.int) return C.int;

   procedure Gl_Setattribute (Attr : Glattr; Value : C.int);

   pragma Import (C, Gl_Setattribute, "SDL_GL_SetAttribute");

   --  Get an attribute of the OpenGL subsystem from the windowing
   --  interface, such as glX. This is of course different from getting
   --  the values from SDL's internal OpenGL subsystem, which only
   --  stores the values you request before initialization.
   --
   --  Developers should track the values they pass into GL_SetAttribute
   --  themselves if they want to retrieve these values.
   function Gl_Getattribute
     (Attr  : Glattr;
      Value : access C.int)
      return  C.int;

   procedure Gl_Getattribute (Attr : Glattr; Value : access C.int);

   procedure Gl_Getattribute (Attr : Glattr; Value : out C.int);

   pragma Import (C, Gl_Getattribute, "SDL_GL_GetAttribute");

   --  Swap the OpenGL buffers, if double-buffering is supported.
   procedure Gl_Swapbuffers;
   pragma Import (C, Gl_Swapbuffers, "SDL_GL_SwapBuffers");

   --  ----------------------------------------------------
   --  Internal functions that should not be called unless you have read
   --  and understood the source code for these functions.

   procedure Gl_Updaterects (Numrects : C.int; Rects : Rect_Ptr);
   pragma Import (C, Gl_Updaterects, "SDL_UpdateRects");

   procedure Gl_Lock;
   pragma Import (C, Gl_Lock, "SDL_GL_Lock");

   procedure Gl_Unlock;
   pragma Import (C, Gl_Unlock, "SDL_GL_Unlock");

   --  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
   --  * These functions allow interaction with the window manager, if any.  *
   --  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

   --  *
   --  * Sets/Gets the title and icon text of the display window
   procedure Wm_Setcaption
     (Title : C.Strings.chars_ptr;
      Icon  : C.Strings.chars_ptr);
   pragma Import (C, Wm_Setcaption, "SDL_WM_SetCaption");

   procedure Wm_Set_Caption (Title : in String; Icon : in String);
   pragma Inline (Wm_Set_Caption);

   procedure Wm_Set_Caption_Title (Title : in String);
   pragma Inline (Wm_Set_Caption_Title);

   procedure Wm_Set_Caption_Icon (Icon : in String);
   pragma Inline (Wm_Set_Caption_Icon);

   procedure Wm_Getcaption (Title : Chars_Ptr_Ptr; Icon : Chars_Ptr_Ptr);
   pragma Import (C, Wm_Getcaption, "SDL_WM_GetCaption");

   procedure Wm_Get_Caption
     (Title : out Us.Unbounded_String;
      Icon  : out Us.Unbounded_String);
   pragma Inline (Wm_Get_Caption);

   procedure Wm_Get_Caption_Title (Title : out Us.Unbounded_String);
   pragma Inline (Wm_Get_Caption_Title);

   procedure Wm_Get_Caption_Icon (Icon : out Us.Unbounded_String);
   pragma Inline (Wm_Get_Caption_Icon);

   --  Sets the icon for the display window.
   --  This function must be called before the first call to SetVideoMode.
   --  It takes an icon surface, and a mask in MSB format.
   --  If 'mask' is NULL, the entire icon surface will be used as the icon.
   procedure Wm_Seticon (Icon : Surface_Ptr; Mask : Uint8_Ptr);   --  Allowing
                                                                  --"null"

   type Icon_Mask_Array is array (Integer range <>) of Uint8;
   pragma Convention (C, Icon_Mask_Array);

   procedure Wm_Seticon (Icon : Surface_Ptr; Mask : in Icon_Mask_Array);
   pragma Import (C, Wm_Seticon, "SDL_WM_SetIcon");

   --  This function iconifies the window, and returns 1 if it succeeded.
   --  If the function succeeds, it generates an APPACTIVE loss event.
   --  This function is a noop and returns 0 in non-windowed environments.
   function Wm_Iconifywindow return C.int;
   procedure Wm_Iconifywindow;
   pragma Import (C, Wm_Iconifywindow, "SDL_WM_IconifyWindow");

   --  Toggle fullscreen mode without changing the contents of the screen.
   --  If the display surface does not require locking before accessing
   --  the pixel information, then the memory pointers will not change.
   --
   --  If this function was able to toggle fullscreen mode (change from
   --  running in a window to fullscreen, or vice-versa), it will return 1.
   --  If it is not implemented, or fails, it returns 0.
   --
   --  The next call to SetVideoMode will set the mode fullscreen
   --  attribute based on the flags parameter - if SDL_FULLSCREEN is not
   --  set, then the display will be windowed by default where supported.
   --
   --  This is currently only implemented in the X11 video driver.
   function Wm_Togglefullscreen (Surface : Surface_Ptr) return C.int;
   pragma Import (C, Wm_Togglefullscreen, "SDL_WM_ToggleFullScreen");

   type Grabmode is new C.int;
   Grab_Query      : constant Grabmode := -1;
   Grab_Off        : constant Grabmode := 0;
   Grab_On         : constant Grabmode := 1;
   Grab_Fullscreen : constant Grabmode := 2; -- Used internally

   --  This function allows you to set and query the input grab state of
   --  the application.  It returns the new input grab state.

   --  Grabbing means that the mouse is confined to the application window,
   --  and nearly all keyboard input is passed directly to the application,
   --  and not interpreted by a window manager, if any.
   --  function WM_GrabInput (
   --     mode : C.int    -- Might be GRAB_QUERY, GRAB_OFF, or GRAB_FULLSCREEN
   --     ) return C.int; -- Might be GRAB_QUERY, GRAB_OFF, or GRAB_FULLSCREEN
   function Wm_Grabinput (Mode : Grabmode) return Grabmode;
   pragma Import (C, Wm_Grabinput, "SDL_WM_GrabInput");

end Sdl.Video;
