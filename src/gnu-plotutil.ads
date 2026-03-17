-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                              GNU.plotutil                                 --
--                                                                           --
--                                 S P E C                                   --
--                                                                           --
-------------------------------------------------------------------------------
--  Copyright (c) 1999-2001
--  by Juergen Pfeifer
--
--  GNAT libplot binding is free software; you can redistribute it and/or    --
--  modify it under terms of the  GNU General Public License as published by --
--  the Free Software  Foundation;  either version 2,  or (at your option)   --
--  any later version. GNAT libplot binding is distributed in the hope that  --
--  it will be useful, but WITHOUT ANY WARRANTY; without even the implied    --
--  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the --
--  GNU General Public License for  more details.  You should have received  --
--  a copy of the GNU General Public License  distributed with GNAT libplot  --
--  binding;  see  file COPYING.  If not, write to  the                      --
--  Free Software Foundation,  59 Temple Place - Suite 330,  Boston,         --
--  MA 02111-1307, USA.                                                      --
--                                                                           --
--  As a special exception,  if other files  instantiate  generics from this --
--  unit, or you link  this unit with other files  to produce an executable, --
--  this  unit  does not  by itself cause  the resulting  executable  to  be --
--  covered  by the  GNU  General  Public  License.  This exception does not --
--  however invalidate  any other reasons why  the executable file  might be --
--  covered by the  GNU Public License.                                      --
--                                                                           --
-------------------------------------------------------------------------------
--  Author: Juergen Pfeifer <juergen.pfeifer@gmx.net>
-------------------------------------------------------------------------------
with System.Storage_Elements;
with Interfaces.C;

package GNU.plotutil is
   pragma Linker_Options ("-lm");  
   pragma Linker_Options ("-lz");  
   -- pragma Linker_Options ("-lplot");  --PP made into a GNAT project
   
   --
   --  #######################################################################
   --
   type Plotter is private;

   --
   Plot_Exception : exception;
   --  This exception is raised if in any of the C functions an error is
   --  returned. The binding provides all the error code returning functions
   --  as procedures and raises an exception in case of an error.
   --
   --  #######################################################################
   --
   procedure Delete (P : in Plotter);
   --  A Plotter that is not currently selected may be deleted, and its storage
   --  freed, by calling `Delete'. A Plot_Exception is raised if you try to
   --  delete the current Plotter.
   --
   --  #######################################################################
   --
   procedure Open (P : in Plotter);
   --  Open opens a Plotter.  Depending on the type of the Plotter,
   --  it may write initialization commands to an output stream.
   --  A Plot_Exception is raised if the Plotter could not be opened.
   --  An X Plotter, which has no output stream, pops up a window on its
   --  X Window System display instead.  Currently, a new window is
   --  popped up with each invocation of `Open'.  Future releases may
   --  support window re-use.

   procedure Close (P : in Plotter);
   --  Close closes a Plotter.  If the currently selected Plotter does
   --  not do real-time plotting (i.e., if it is a Postscript, Fig, or
   --  HP-GL Plotter), it writes the plotted objects to the output
   --  stream.  A Plot_Exception is raised if the Plotter could not
   --  be closed.

   procedure Erase (P : in Plotter);
   --  Erase begins the next frame of a multiframe page, by clearing all
   --  previously plotted objects from the graphics display, and filling
   --  it with the background color (if any).
   --
   --  It is frequently useful to invoke erase at the beginning of each
   --  page, i.e., immediately after invoking Open.  That is because
   --  some Plotters are persistent, in the sense that objects drawn
   --  within an `Open'...`Close' pair remain on the graphics display
   --  even after a new page is begun by a subsequent invocation of
   --  `Open'.  Currently, only X Drawable Plotters and Tektronix
   --  Plotters are persistent.  Future releases may support optional
   --  persistence for X Plotters also.
   --
   --  On X Plotters and X Drawable Plotters the effects of invoking Erase
   --  will be altogether different if the device driver parameter
   --  `USE_DOUBLE_BUFFERING' is set to "yes".  In this case, objects
   --  will be written to an off-screen buffer rather than to the graphics
   --  display, and invoking erase will (1) copy the contents of this
   --  buffer to the display, and (2) erase the buffer by filling it with
   --  the background color.  This `double buffering' feature facilitates
   --  smooth animation.

   procedure Flush (P : in Plotter);
   --  Flush flushes (i.e., pushes onward) all plotting commands to the
   --  display device.  This is useful only if the currently selected
   --  Plotter does real-time plotting, since it may be used to ensure
   --  that all previously plotted objects have been sent to the display
   --  and are visible to the user.  It has no effect on Plotters that do
   --  not do real-time plotting.
   --
   --  #######################################################################
   --
   procedure Push_State (P : in Plotter);
   --  Push_State pushes the current graphics context onto the stack of
   --  drawing states.  The graphics context consists largely of
   --  `libplot''s drawing parameters, which are set by the attribute
   --  functions documented in this binding.  A path under construction,
   --  if any, is regarded as part of the drawing state.  That is because
   --  paths may be drawn incrementally, one segment (line segment,
   --  circular arc segment, or elliptic arc segment) at a time.  When a
   --  graphics context is returned to, the path under construction may
   --  be continued.

   procedure Pop_State (P : in Plotter);
   --  Pop_State pops the current graphics context off the stack of
   --  drawing states.  The graphics context consists largely of
   --  `libplot''s drawing parameters, which are set by the attribute
   --  functions documented in this binding.  So popping off the graphics
   --  context restores the drawing parameters to values they previously
   --  had.  A path under construction is regarded as part of the graphics
   --  context.  For this reason, calling Pop_State automatically calls
   --  End_Path to terminate the path under construction, if any.  All
   --  graphics contexts on the stack are popped off when `Close' is
   --  called, as if `Pop_State' had been called repeatedly.
   --
   --  #######################################################################
   --
   type Line_Type is (Disconnected,
                      Solid,
                      Dotted,
                      DotDashed,
                      ShortDashed,
                      LongDashed,
                      DotDotDashed,
                      DotDotDotDashed);

   procedure Line_Mode (P     : in Plotter;
                        Mode  : in Line_Type);
   --  Line_Mode sets the line mode (i.e., line style) for all paths,
   --  circles, and ellipses subsequently drawn on the graphics display.
   --  The modes supported are Disconnected, Solid, Dotted, Dot_Dashed,
   --  Short_Dashed, Long_Dashed. A `Disconnected' path joining a sequence
   --  of points is invisible, though the points themselves are visible.
   --  Disconnected polylines are never filled. The other five linemodes
   --  correspond more or less to the following
   --  bit patterns:
   --       Solid             --------------------------------
   --       Dotted            - - - - - - - - - - - - - - - -
   --       Dotdashed         -----------  -  -----------  -
   --       Shortdashed       --              --
   --       Longdashed        -------         -------
   --
   --  #######################################################################
   --
   type Cap_Style is (Butt,
                      Round,
                      Projecting);

   procedure Cap_Mode  (P     : in Plotter;
                        Style : in Cap_Style := Butt);
   --  Cap_Mode sets the cap mode (i.e., Cap_Style) for all paths
   --  subsequently drawn on the graphics display.  Recognized styles are
   --  Butt (the default), Round, and Projecting.  This function
   --  has no effect on Tektronix Plotters.  Also, it has no effect on
   --  HP-GL Plotters if the parameter `HPGL_VERSION' is set to a value
   --  less than "2" (the default).
   --
   --  #######################################################################
   --
   type Filltype_Level is new Integer range 0 .. 65535;

   procedure Filltype  (P     : in Plotter;
                        Level : in Filltype_Level := 0);
   --  Filltype sets the fill fraction for all subsequently drawn objects.
   --  A value of 0 for Level indicates that objects should be unfilled,
   --  or transparent.  This is the default.  A value in the range
   --  0x0001...0xffff, i.e., 1...65535, indicates that objects should be
   --  filled.  A value of 1 signifies 100% filling (the fill color will
   --  simply be the color specified by calling fillcolor or
   --  fillcolorname).  If Level=0xffff, the fill color will be white.
   --  Values between 0x0001 and 0xffff are interpreted as specifying a
   --  desaturation, or gray level.  For example, 0x8000 specifies 50%
   --  filling (the fill color will be intermediate between the color
   --  specified by calling fillcolor or fillcolorname, and white).
   --
   --  If the object to be filled is a self-intersecting path, the
   --  `even-odd rule' will be applied to determine which points are
   --  inside, i.e., which of the regions bounded by the path should be
   --  filled.  The even-odd rule is explained in the `Postscript
   --  Language Reference Manual'.
   --
   --  Tektronix Plotters do not support filling, and HP-GL Plotters
   --  support filling only if the parameter `HPGL_VERSION' is equal to
   --  "1.5" or "2" (the default).  Also, *white* filling is fully
   --  supported only if the value of the parameter `HPGL_VERSION' is "2"
   --  and the value of the parameter `HPGL_OPAQUE_MODE' is "yes".
   --
   --  #######################################################################
   --
   type Join_Style is (Miter,
                       Round,
                       Bevel);

   procedure Join_Mode (P     : in Plotter;
                        Style : in Join_Style := Miter);
   --  Join_Mode sets the join mode (i.e., Join_Style) for all paths
   --  subsequently drawn on the graphics display.  Recognized styles are
   --  Miter (the default), Round, and Bevel.  This function has no
   --  effect on Tektronix Plotters.  Also, it has no effect on HP-GL
   --  Plotters if the parameter `HPGL_VERSION' is set to a value less
   --  than "2" (the default).
   --
   procedure Miter_Limit (P     : in Plotter;
                          Limit : in Interfaces.C.double);
   --  Miter_Limit sets the miter limit for all paths subsequently drawn
   --  on the graphics display.  The miter limit controls the treatment of
   --  corners, if the join mode is set to "Miter" (the default).  At a
   --  join point of a path, the `miter length' is defined to be the
   --  distance between the inner corner and the outer corner.  The miter
   --  limit is the maximum value that will be tolerated for the miter
   --  length divided by the line thickness.  If this value is exceeded,
   --  the miter will be cut off: the "bevel" join mode will be used
   --  instead.
   --
   --  Examples of typical values for LIMIT are 10.43 (the default, which
   --  cuts off miters if the join angle is less than 11 degrees), 2.0
   --  (the same, for 60 degrees), and 1.414 (the same, for 90 degrees).
   --  In general, the miter limit is the cosecant of one-half the
   --  minimum angle for mitered joins.  The minimum meaningful value for
   --  LIMIT is 1.0, which converts all mitered joins to beveled joins,
   --  irrespective of join angle.  Specifying a value less than 1.0
   --  resets the limit to the default.
   --
   --  This function has no effect on X Drawable Plotters or X Plotters,
   --  since the X Window System miter limit, which is also 10.43, cannot
   --  be altered.  It also has no effect on Tektronix Plotters or Fig
   --  Plotters, or on HP-GL Plotters if the parameter `HPGL_VERSION' is
   --  set to a value less than "2" (the default).
   --
   --  #######################################################################
   --
   type RGB_Value is new Integer range 0 .. 65535;

   procedure Pen_Color (P                : in Plotter;
                        Red, Green, Blue : in RGB_Value);
   --  Pen_Color sets the pen color of all objects subsequently drawn on
   --  the graphics display, using a 48-bit RGB color model.  The
   --  arguments Red, Green and Blue specify the red, green and blue
   --  intensities of the pen color.  Each is an integer in the range
   --  0x0000...0xffff, i.e., 0...65535.  The choice (0, 0, 0) signifies
   --  black, and the choice (65535, 65535, 65535) signifies white.
   --
   --  HP-GL Plotters support drawing with a white pen only if the value
   --  of the parameter `HPGL_VERSION' is "2" (the default), and the
   --  value of the parameter `HPGL_OPAQUE_MODE' is "yes".

   procedure Pen_ColorName (P    : in Plotter;
                            Name : in String);
   --  Pen_ColorName sets the pen color of all objects subsequently drawn
   --  on the graphics display to be Name.  For information on what color
   --  names are recognized, see the documentation.
   --  Unrecognized colors are interpreted as "black".
   --
   --  HP-GL Plotters support drawing with a white pen only if the value
   --  of the parameter `HPGL_VERSION' is "2" (the default), and the
   --  value of the parameter `HPGL_OPAQUE_MODE' is "yes".

   type Pen_Type_Level is (No_Outline,
                           Outline);
   for Pen_Type_Level use (No_Outline => 0,
                           Outline    => 1);

   procedure Pen_Type (P     : in Plotter;
                       Level : in Pen_Type_Level := Outline);
   --  Pen_Type sets the pen level for all subsequently drawn paths,
   --  circles, and ellipses.  A value of Outline for LEVEL specifies that an
   --  outline of each of these objects should be drawn, in the color
   --  previously specified by calling pencolor or pencolorname.  This is
   --  the default.  A value of No_Outline specifies that outlines should
   --  not be drawn.
   --
   --  To draw the region bounded by a path, circle, or ellipse in an
   --  edgeless way, you would call pentype to turn off the drawing of the
   --  boundary, and filltype to turn on the filling of the interior.

   procedure Fill_Color (P                : in Plotter;
                         Red, Green, Blue : in RGB_Value);
   --  Fill_Color sets the fill color of all objects subsequently drawn on
   --  the graphics display, using a 48-bit RGB color model.  The
   --  arguments Red, Green and Blue specify the red, green and blue
   --  intensities of the fill color.  Each is an integer in the range
   --  0x0000...0xffff, i.e., 0...65535.  The choice (0, 0, 0) signifies
   --  black, and the choice (65535, 65535, 65535) signifies white.  Note
   --  that the physical fill color depends also on the fill fraction,
   --  which is specified by calling filltype.

   procedure Fill_ColorName (P    : in Plotter;
                             Name : in String);
   --  Fill_ColorName sets the fill color of all objects subsequently drawn
   --  on the graphics display to be Name.  For information on what color
   --  names are recognized, see the documentation.  Unrecognized
   --  colors are interpreted as "black".  Note that the physical fill
   --  color depends also on the fill fraction, which is specified by
   --  calling filltype.

   procedure Color (P                : in Plotter;
                    Red, Green, Blue : in RGB_Value);
   --  Color is a convenience function.  Calling Color is equivalent to
   --  calling both Pen_Color and Fill_Color, to set both the the pen color
   --  and fill color of all objects subsequently drawn on the graphics
   --  display.  Note that the physical fill color depends also on the
   --  fill fraction, which is specified by calling filltype.

   procedure ColorName (P    : in Plotter;
                        Name : in String);
   --  ColorName is a convenience function.  Calling ColorName is
   --  equivalent to calling both Pen_ColorName and Fill_colorName, to set
   --  both the the pen color and fill color of all objects subsequently
   --  drawn on the graphics display.  Note that the physical fill color
   --  depends also on the fill fraction, which is specified by calling
   --  filltype.
   --
   procedure Background_Color (P                : in Plotter;
                               Red, Green, Blue : in RGB_Value);
   --  Background_Color sets the background color for the graphics display,
   --  using a 48-bit RGB color model.  The arguments Red, Green and Blue
   --  specify the red, green and blue intensities of the background color.
   --  Each is an integer in the range 0..65535.  The choice (0, 0, 0)
   --  signifies black, and the choice (65535, 65535,65535) signifies white.
   --
   --  Background_Color has an effect only on Plotters that produce a
   --  bitmap, i.e. X Plotters, X Drawable Plotters, PNM Plotters, and GIF
   --  Plotters.
   --  Its effect is simple: the next time the erase operation is invoked
   --  on such a Plotter, its display will be filled with the specified
   --  color.

   procedure Background_ColorName (P    : in Plotter;
                                   Name : in String);
   --  Background_ColorName sets the background color for the the graphics
   --  display to be 'Name'.  For information on what color names are
   --  recognized, see the documentation.  Unrecognized colors are
   --  interpreted as "white".
   --
   --  This call  has an effect only on Plotters that produce a bitmap, i.e.
   --  X Plotters, X Drawable Plotters, PNM Plotters, and GIF Plotters.
   --  Its effect is simple: the next time the erase operation is invoked on
   --  such a Plotter, its display will be filled with the specified color.

   --  #######################################################################
   --
   type Horizontal_Justification is (Left,
                                     Center,
                                     Right);

   type Vertical_Justification is (Bottom,
                                   Baseline,
                                   Center,
                                   Top,
                                   Cap_Line);

   procedure Label (P         : in Plotter;
                    H_Justify : in Horizontal_Justification := Left;
                    V_Justify : in Vertical_Justification   := Baseline;
                    Text      : in String);
   --  Label takes three arguments H_Justify, V_Justify, and Text,
   --  which specify an `adjusted label,' i.e., a justified text string.
   --  The path under construction (if any) is ended, and the string Text is
   --  drawn according to the specified justifications.  If H_Justify
   --  is equal to Left, Center, or Right, then the string will be drawn with
   --  left, center or right justification, relative to the current
   --  graphics cursor position.  If V_Justify is equal to Bottom, Baseline,
   --  Center, or Top, then the bottom, baseline, center or top of the
   --  string will be placed even with the current graphics cursor
   --  position.  The graphics cursor is moved to the right end of the
   --  string if left justification is specified, and to the left end if
   --  right justification is specified.
   --
   --  The string may contain escape sequences of various sorts, though it
   --  should not contain line feeds or carriage returns.  In fact it should
   --  include only printable characters, from the byte ranges 0x20...0x7e
   --  and 0xa0...0xff.  The string may be plotted at a nonzero angle, if
   --  `Text_Angle' has been called.
   --
   --  #######################################################################
   --
   procedure End_Path (P : in Plotter);
   --  End_Path terminates the path under construction, if any.  Paths,
   --  which are formed by repeated calls to Continue, Arc,
   --  Elliptical_Arc or Line, are also terminated if any other object is
   --  drawn or any path-related drawing attribute is set.  So endpath is
   --  almost redundant.  However, if a Plotter plots objects in real time,
   --  calling endpath will ensure that a constructed path is drawn on the
   --  graphics display without delay.
   --
   --  #######################################################################
   --
   procedure End_Subpath (P : in Plotter);
   --  End_Subpath terminates the simple path under construction, if any,
   --  and signals that the construction of the next simple path in a
   --  compound path is to begin.  Immediately after End_Subpath is called,
   --  it is permissible to call move or fmove to reposition the graphics
   --  cursor.  (At other times in the drawing of a compound path,
   --  calling Move would force a premature end to the path, by
   --  automatically invoking End_Path.)
   --
   --  #######################################################################
   --
   type Direction is (Clockwise, Counterclockwise);

   procedure Orientation (P   : in Plotter;
                          Dir : in Direction := Counterclockwise);
   --  Orientation sets the orientation for all circles, ellipses, and
   --  boxes subsequently drawn on the graphics display.

   --  Orientation will have a visible effect on a circle, ellipse, or box
   --  only if it is dashed, or if it is one of the simple paths in a
   --  filled compound path.  Its effects on filling, when the
   --  "nonzero-winding" fill rule is used, are dramatic, since it is the
   --  orientation of each simple path in a compound path that determines
   --  which points are `inside' and which are `outside'.
   --
   --  #######################################################################
   --
   type Capability_Existence is (No, Yes, Maybe);

   function Has_Capability (P          : in Plotter;
                            Capability : String) return Capability_Existence;
   --  Has_Capability tests whether or not a Plotter has a specified
   --  capability. For unrecognized capabilities the return value is `No'.
   --  Recognized capabilities include "WIDE_LINES" (i.e., the ability to
   --  draw lines with a non-default thickness), "DASH_ARRAY" (the ability to
   --  draw in arbitrary dashing styles, as requested by the linedash
   --  function), "SETTABLE_BACKGROUND" (the ability to set the color of the
   --  background), and "SOLID_FILL".
   --  The "HERSHEY_FONTS", "PS_FONTS", "PCL_FONTS", and "STICK_FONTS"
   --  capabilities indicate whether or not fonts of a particular class
   --  are supported.
   --
   --  #######################################################################
   --
   type Marker_Type is (None,
                        Dot,
                        Plus,
                        Asterisk,
                        Circle,
                        Cross,
                        Square,
                        Triangle,
                        Diamond,
                        Star,
                        Inverted_Triangle,
                        Starburst,
                        Fancy_Plus,
                        Fancy_Cross,
                        Fancy_Square,
                        Fancy_Diamond,
                        Filled_Circle,
                        Filled_Square,
                        Filled_Triangle,
                        Filled_Diamond,
                        Filled_Inverted_Triangle,
                        Filled_Fancy_Square,
                        Filled_Fancy_Diamond,
                        Half_Filled_Circle,
                        Half_Filled_Square,
                        Half_Filled_Triangle,
                        Half_Filled_Diamond,
                        Half_Filled_Inverted_Triangle,
                        Half_Filled_Fancy_Square,
                        Half_Filled_Fancy_Diamond,
                        Octagon,
                        Filled_Octagon);
   --
   --  #######################################################################
   --
   --  Inline most of the binding routines
   pragma Inline (Open);
   pragma Inline (Close);
   pragma Inline (Delete);
   pragma Inline (Erase);
   pragma Inline (Push_State);
   pragma Inline (Pop_State);
   pragma Inline (ColorName);
   pragma Inline (Color);
   pragma Inline (Fill_ColorName);
   pragma Inline (Fill_Color);
   pragma Inline (Pen_ColorName);
   pragma Inline (Pen_Color);
   pragma Inline (Pen_Type);
   pragma Inline (Background_Color);
   pragma Inline (Background_ColorName);
   pragma Inline (Filltype);
   pragma Inline (End_Path);
   pragma Inline (End_Subpath);
   pragma Inline (Orientation);
   pragma Inline (Has_Capability);
   pragma Inline (Label);
   pragma Inline (Join_Mode);
   pragma Inline (Miter_Limit);
   pragma Inline (Cap_Mode);
   pragma Inline (Line_Mode);
   --
   --  #######################################################################
   --
private
   type Plotter           is new System.Storage_Elements.Integer_Address;
   No_Plotter           : constant Plotter := 0;

end GNU.plotutil;
