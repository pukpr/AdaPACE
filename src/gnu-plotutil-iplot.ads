-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                            GNU.plotutil.iplot                             --
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
--
-------------------------------------------------------------------------------
--  Author: Juergen Pfeifer <juergen.pfeifer@gmx.net>
-------------------------------------------------------------------------------
generic
   type Int is range <>;

package GNU.plotutil.iplot is

   procedure Space (P      : in Plotter;
                    X0, Y0 : in Int;
                    X1, Y1 : in Int);
   --  Space takes two pairs of arguments, specifying the
   --  positions of the lower left corner and upper right corner of the
   --  graphics display, in user coordinates.  In other words, calling
   --  Space sets the affine transformation from user coordinates to device
   --  coordinates. This operation must be performed at the beginning of each
   --  page of graphics, i.e., immediately after Open is invoked.

   procedure Space_Extended (P      : in Plotter;
                             X0, Y0 : in Int;
                             X1, Y1 : in Int;
                             X2, Y2 : in Int);
   --  The Arguments are the three defining vertices of an `affine
   --  window' (a drawing parallelogram), in user coordinates.  The
   --  specified vertices are the lower left, the lower right, and the
   --  upper left.  This window will be mapped affinely onto the graphics
   --  display.

   procedure Move (P    : in Plotter;
                   X, Y : in Int);
   --  Move takes two arguments specifying the coordinates (X,Y) of a point
   --  to which the graphics cursor should be moved.  The path under
   --  construction (if any) is ended, and the graphics cursor is moved to
   --  (X, Y).  This is equivalent to lifting the pen on a plotter and moving
   --  it to a new position, without drawing any line.
   procedure Move_Relative (P    : in Plotter;
                            X, Y : in Int);
   --  Move_Relative is similar to Move but uses cursor-relative coordinates.

   procedure Continue (P    : in Plotter;
                       X, Y : in Int);
   --  Continue takes two arguments specifying the coordinates (X,Y) of a
   --  point.  If a path is under construction, the line segment from the
   --  current graphics cursor position to the point (X, Y) is added to it.
   --  Otherwise the line segment begins a new path.  In all cases the
   --  graphics cursor is moved to (X, Y).
   procedure Continue_Relative (P    : in Plotter;
                                X, Y : in Int);
   --  Continue_Relative is similar to Continue, but uses cursor-relative
   --  coordinates.

   procedure Line_Width (P    : in Plotter;
                         Size : in Int'Base);
   --  Line_Width sets the width, in the user frame, of all paths, circles,
   --  and ellipses subsequently drawn on the graphics display.  A negative
   --  value means that a default width should be used.  This default width
   --  depends on the type of Plotter.  The interpretation of zero line width
   --  is does also (for some types of Plotter, a zero-width line is the
   --  thinnest line that can be drawn; for others, a zero-width line is
   --  invisible).
   --
   --  Tektronix Plotters do not support drawing with other than a default
   --  width, and HP-GL Plotters do not support doing so if the parameter
   --  `HPGL_VERSION' is set to a value less than "2" (the default)
   --
   procedure Line_Width (P : in Plotter);
   --  Called without argument it sets the default line width for the plotter.
   --
   procedure Line (P      : in Plotter;
                   X0, Y0 : in Int;
                   X1, Y1 : in Int);
   --  Line takes four arguments specifying the start point (X0,Y0)
   --  and end point (X1, Y1) of a line segment.  If the graphics
   --  cursor is at (X0, Y0) and a path is under construction, the line
   --  segment is added to it.  Otherwise the path under construction
   --  (if any) is ended, and the line segment begins a new path.  In all
   --  cases the graphics cursor is moved to (X1, Y1).
   procedure Line_Relative (P      : in Plotter;
                            X0, Y0 : in Int;
                            X1, Y1 : in Int);
   --  Line_Relative is similar to Line, but uses cursor-relative coordinates.

   procedure Point (P    : in Plotter;
                    X, Y : in Int);
   --  Point takes two arguments specifying the coordinates (X,Y) of a point.
   --  The path under construction (if any) is ended, and the point is plotted.
   --  (A `point' is usually a small solid circle, perhaps the smallest that
   --  can be plotted.)  The graphics cursor is moved to (X, Y).
   procedure Point_Relative (P    : in Plotter;
                             X, Y : in Int);
   --  Point_Relative is similar to Point but uses cursor-relative coordinates.

   procedure Arc (P      : in Plotter;
                  XC, YC : in Int;
                  X0, Y0 : in Int;
                  X1, Y1 : in Int);
   --  Arc takes six arguments specifying the beginning (X0, Y0),
   --  end (X1, Y1), and center (XC, YC) of a circular arc.  If the
   --  graphics cursor is at (X0, Y0) and a path is under construction,
   --  then the arc is added to the path.  Otherwise the current path
   --  (if any) is ended, and the arc begins a new path.  In all cases
   --  the graphics cursor is moved to (X1, Y1).
   --
   --  The direction of the arc (clockwise or counterclockwise) is
   --  determined by the convention that the arc, centered at (XC, YC),
   --  sweep through an angle of at most 180 degrees.  If the three
   --  points appear to be collinear, the direction is taken to be
   --  counterclockwise.  If (XC, YC) is not equidistant from (X0, Y0) and
   --  (X1, Y1) as it should be, it is corrected by being moved to the
   --  closest point on the perpendicular bisector of the line segment
   --  joining (X0, Y0) and (X1, Y1).
   procedure Arc_Relative (P      : in Plotter;
                           XC, YC : in Int;
                           X0, Y0 : in Int;
                           X1, Y1 : in Int);
   --  Arc_Relative is similar to Arc but uses cursor-relative coordinates.

   procedure Elliptical_Arc (P      : in Plotter;
                             XC, YC : in Int;
                             X0, Y0 : in Int;
                             X1, Y1 : in Int);
   --  Elliptical_Arc takes six arguments specifying the three points
   --  `pc'=(XC,YC), `p0'=(X0,Y0), and `p1'=(X1,Y1) that define a
   --  so-called quarter ellipse.  This is an elliptic arc from `p0' to
   --  `p1' with center `pc'.  If the graphics cursor is at point `p0'
   --  and a path is under construction, the quarter-ellipse is added to
   --  it.  Otherwise the path under construction (if any) is ended, and
   --  the quarter-ellipse begins a new path.  In all cases the graphics
   --  cursor is moved to `p1'.
   --
   --  The quarter-ellipse is an affinely transformed version of a quarter
   --  circle.  It is drawn so as to have control points `p0', `p1', and
   --  `p0'+`p1'-`pc'.  This means that it is tangent at `p0' to the line
   --  segment joining `p0' to `p0'+`p1'-`pc', and is tangent at `p1' to
   --  the line segment joining `p1' to `p0'+`p1'-`pc'.  So it fits
   --  snugly into a triangle with these three control points as
   --  vertices.  Notice that the third control point is the reflection of
   --  `pc 'through the line joining `p0' and `p1'.
   procedure Elliptical_Arc_Relative (P      : in Plotter;
                                      XC, YC : in Int;
                                      X0, Y0 : in Int;
                                      X1, Y1 : in Int);
   --  Elliptical_Arc_Relative is similar to Elliptical_Arc, but uses
   --  cursor-relative coordinates.

   procedure Circle (P      : in Plotter;
                     XC, YC : in Int;
                     R      : in Int'Base);
   --  Circle takes three arguments specifying the center (XC,YC)
   --  and radius (R) of a circle.  The path under construction
   --  (if any) is ended, and the circle is drawn.  The graphics cursor
   --  is moved to (XC, YC).
   procedure Circle_Relative (P      : in Plotter;
                              XC, YC : in Int;
                              R      : in Int'Base);
   --  Circle_Relative is similar to Circle, but uses cursor-relative
   --  coordinates for XC and YC.

   procedure Ellipse (P      : in Plotter;
                      XC, YC : in Int;
                      Rx, Ry : in Int'Base;
                      Angle  : in Int'Base);
   --  Ellipse takes five arguments specifying the center (XC,YC) of an
   --  ellipse, the lengths of its semiaxes (Rx and Ry), and the inclination
   --  of the first semiaxis in the counterclockwise direction from the x axis
   --  in the user frame.  The path under construction (if any) is ended, and
   --  the ellipse is drawn.  The graphics cursor is moved to (XC, YC).
   procedure Ellipse_Relative (P      : in Plotter;
                               XC, YC : in Int;
                               Rx, Ry : in Int'Base;
                               Angle  : in Int'Base);
   --  Ellipse_Relative is similar to Ellipse, but uses cursor-relative
   --  coordinates.

   procedure Box (P      : in Plotter;
                  X0, Y0 : in Int;
                  X1, Y1 : in Int);
   --  Box takes four arguments specifying the lower left corner
   --  (X0, Y0) and upper right corner (X1, Y1) of a `box', or rectangle.
   --  The path under construction (if any) is ended, and the box is
   --  drawn as a new path.  This path is also ended, and the graphics
   --  cursor is moved to the midpoint of the box.
   --
   procedure Box_Relative (P      : in Plotter;
                           X0, Y0 : in Int;
                           X1, Y1 : in Int);
   --  Box_Relative is similar to Box but uses cursor-relative coordinates.

   procedure Quadratic_Bezier_Curve (P      : in Plotter;
                                     X0, Y0 : in Int;
                                     X1, Y1 : in Int;
                                     X2, Y2 : in Int);
   --  Quadratic_Bezier_Curve takes six arguments specifying the beginning
   --  `p0'=(X0, Y0) and end `p2'=(X2, Y2) of a quadratic Bezier curve,
   --  and its intermediate control point `p1'=(X1, Y1).  If the graphics
   --  cursor is at `p0' and a path is under construction, then the curve
   --  is added to the path.  Otherwise the current path (if any) is
   --  ended, and the curve begins a new path.  In all cases the graphics
   --  cursor is moved to `p2'.
   --  The quadratic Bezier curve is tangent at `p0' to the line segment
   --  joining `p0' to `p1', and is tangent at `p2' to the line segment
   --  joining `p1' to `p2'.  So it fits snugly into a triangle with
   --  vertices `p0', `p1', and `p2'.
   --
   --  When using a PCL Plotter to draw Bezier curves on a LaserJet III,
   --  you should set the parameter `PCL_BEZIERS' to "no".  That is
   --  because the LaserJet III, which was Hewlett-Packard's first PCL 5
   --  printer, does not recognize the Bezier instructions supported by
   --  later PCL 5 printers.

   procedure Quadratic_Bezier_Curve_Relative (P      : in Plotter;
                                              X0, Y0 : in Int;
                                              X1, Y1 : in Int;
                                              X2, Y2 : in Int);
   --  This is similar to Quadratic_Bezier_Curve but uses cursor relative
   --  coordinates.

   procedure Cubic_Bezier_Curve (P      : in Plotter;
                                 X0, Y0 : in Int;
                                 X1, Y1 : in Int;
                                 X2, Y2 : in Int;
                                 X3, Y3 : in Int);
   --  Cubic_Bezier_Curve takes eight arguments specifying the beginning
   --  `p0'=(X0, Y0) and end `p3'=(X3, Y3) of a cubic Bezier curve, and
   --  its intermediate control points `p1'=(X1, Y1) and `p2'=(X2, Y2).
   --  If the graphics cursor is at `p0' and a path is under
   --  construction, then the curve is added to the path.  Otherwise the
   --  current path (if any) is ended, and the curve begins a new path.
   --  In all cases the graphics cursor is moved to `p3'.
   --
   --  The cubic Bezier curve is tangent at `p0' to the line segment
   --  joining `p0' to `p1', and is tangent at `p3' to the line segment
   --  joining `p2' to `p3'.  So it fits snugly into a quadrangle with
   --  vertices `p0', `p1', `p2', and `p3'.
   --
   --  When using a PCL Plotter to draw Bezier curves on a LaserJet III,
   --  you should set the parameter `PCL_BEZIERS' to "no".  That is
   --  because the LaserJet III, which was Hewlett-Packard's first PCL 5
   --  printer, does not recognize the Bezier instructions supported by
   --  later PCL 5 printers.

   procedure Cubic_Bezier_Curve_Relative (P      : in Plotter;
                                          X0, Y0 : in Int;
                                          X1, Y1 : in Int;
                                          X2, Y2 : in Int;
                                          X3, Y3 : in Int);
   --  This is similar to Cubic_Bezier_Curve but uses cursor relative
   --  coordinates.

   procedure Marker (P     : in Plotter;
                     X, Y  : in Int;
                     Shape : in Marker_Type;
                     Size  : in Int'Base);
   procedure Marker (P     : in Plotter;
                     X, Y  : in Int;
                     Ch    : in Character;
                     Size  : in Int'Base);
   --  Marker takes four arguments specifying the location (X,Y) of a marker
   --  symbol, its type, and its size in user coordinates.  The path under
   --  construction (if any) is ended, and the marker symbol is plotted.  The
   --  graphics cursor is moved to (X,Y).
   --
   --  The marker type can either be a member of an enumeration of predefined
   --  marker symbols or a printable character.
   procedure Marker_Relative (P     : in Plotter;
                              X, Y  : in Int;
                              Shape : in Marker_Type;
                              Size  : in Int'Base);
   procedure Marker_Relative (P     : in Plotter;
                              X, Y  : in Int;
                              Ch    : in Character;
                              Size  : in Int'Base);
   --  Marker_Relative is similar to Marker but use cursor-relative
   --  coordinates for the position (X,Y).

   function Text_Angle (P     : in Plotter;
                        Angle : in Int'Base) return Int'Base;
   --  Text_Angle takes one argument, which specifies the angle in degrees
   --  counterclockwise from the x (horizontal) axis in the user frame, for
   --  text strings subsequently drawn on the graphics display.  The default
   --  angle is zero.  (The font for plotting strings is fully specified by
   --  calling fontname, fontsize, and textangle.)  The size of the font for
   --  plotting strings, in user coordinates, is returned.

   function Font_Name (P    : in Plotter;
                       Name : in String) return Int'Base;
   --  Font_Name takes a single case-insensitive string argument Name,
   --  specifying the name of the font to be used for all text strings
   --  subsequently drawn on the graphics display.
   --  (The font for plotting strings is fully specified by calling
   --  fontname, fontsize, and textangle.)  The default font name depends
   --  on the type of Plotter.  It is "Helvetica" for all Plotters except
   --  Tektronix and HP-GL Plotters, for which it is "HersheySerif".
   --  Which fonts are available also depends on the type of Plotter; for a
   --  list of available fonts, see the documentation-
   --  The size of the font in user coordinates is returned.
   function Font_Name (P : in Plotter) return Int'Base;
   --  The size of the default font in user coordinates is returned.

   function Font_Size (P    : in Plotter;
                       Size : in Int'Base) return Int'Base;
   --  Font_Size takes a single argument, interpreted as the
   --  size, in the user frame, of the font to be used for all text
   --  strings subsequently drawn on the graphics display.  (The font for
   --  plotting strings is fully specified by calling fontname, fontsize,
   --  and textangle.)  The size of the font in user coordinates is
   --  returned.
   function Font_Size (P : in Plotter) return Int'Base;
   --  Set the font size to its default value and return the size of the font
   --  in user coordinates.

   function Label_Width (P    : in Plotter;
                         Text : in String) return Int'Base;
   --  Label_Width computes and returns the width of a string in the current
   --  font, in the user frame.  The string is not plotted.
   --
   type Dashes is array (Natural range <>) of Int'Base;

   procedure Line_Dash (P              : in Plotter;
                        Dash_Distances : in Dashes;
                        Offset         : in Int'Base);
   --  Line_Dash sets the line style for all paths, circles,
   --  and ellipses subsequently drawn on the graphics display.  They
   --  provide much finer control of dash patterns than the Line_Mode
   --  provides.  Dash_Distances should be an array of elements, which should
   --  be positive, are interpreted as distances in the user coordinate
   --  system.  Along any path, circle, or ellipse, the elements in
   --  Dash_Distances alternately specify the length of a dash and the length
   --  of a gap between dashes.  When the end of the array is reached, the
   --  reading of the array wraps around to the beginning.  If the array is
   --  empty there is no dashing: the drawn line is solid.
   --
   --  The Offset argument specifies the `phase' of the dash pattern
   --  relative to the start of the path.  It is interpreted as the
   --  distance into the dash pattern at which the dashing should begin.
   --  For example, if Offset equals zero then the path will begin with a
   --  dash, of length of the first element in Dash_Distances in user space.
   --  If Offset equals the first element in Dash_Distances then the path will
   --  begin with a gap of length of the second element in Dash_Distances
   --  and so forth.  Offset is allowed to be negative.
   --
   --  Not all Plotters fully support Line_Dash.  HP-GL and
   --  PCL Plotters cannot dash with a nonzero offset, and in the dash
   --  patterns used by X and X Drawable Plotters, each dash and each gap
   --  has a maximum length of 255 pixels.  linedash and flinedash have
   --  no effect on Tektronix and Fig Plotters, and they have no effect on
   --  HP-GL Plotters for which the parameter `HPGL_VERSION' is less
   --  than "2" (the default)
   --
   --  *Warning*: If the map from the user coordinate system to the
   --  device coordinate system is not uniform, each dash in a dashed path
   --  should ideally be drawn on the graphics display with a length that
   --  depends on its direction.  But currently, only Postscript Plotters
   --  do this.  Other Plotters always draw any specified dash with the
   --  same length, irrespective of its direction.  The length that is
   --  used is the minimum length, in the device coordinate system, that
   --  can correspond to the specified dash length in the user coordinate
   --  system.

   --  -----------------------------------------------------------------------
   --
   pragma Inline (Space);
   pragma Inline (Space_Extended);
   pragma Inline (Move);
   pragma Inline (Move_Relative);
   pragma Inline (Continue);
   pragma Inline (Continue_Relative);
   pragma Inline (Line_Width);
   pragma Inline (Line);
   pragma Inline (Line_Relative);
   pragma Inline (Point);
   pragma Inline (Point_Relative);
   pragma Inline (Arc);
   pragma Inline (Arc_Relative);
   pragma Inline (Elliptical_Arc);
   pragma Inline (Elliptical_Arc_Relative);
   pragma Inline (Box);
   pragma Inline (Box_Relative);
   pragma Inline (Circle);
   pragma Inline (Circle_Relative);
   pragma Inline (Ellipse);
   pragma Inline (Ellipse_Relative);
   pragma Inline (Quadratic_Bezier_Curve);
   pragma Inline (Quadratic_Bezier_Curve_Relative);
   pragma Inline (Cubic_Bezier_Curve);
   pragma Inline (Cubic_Bezier_Curve_Relative);
   pragma Inline (Marker);
   pragma Inline (Marker_Relative);
   pragma Inline (Text_Angle);
   pragma Inline (Font_Name);
   pragma Inline (Font_Size);
   pragma Inline (Label_Width);

end GNU.plotutil.iplot;
