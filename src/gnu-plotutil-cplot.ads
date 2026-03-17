-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                            GNU.plotutil.cplot                             --
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
with Ada.Numerics.Generic_Complex_Types;

generic
   with package Complex_Numbers is
    new Ada.Numerics.Generic_Complex_Types (<>);

package GNU.plotutil.cplot is
   use Complex_Numbers;

   procedure Space (P      : in Plotter;
                    C0, C1 : in Complex);
   --  Space take two complex arguments, specifying the positions of the
   --  lower left corner and upper right corner of the graphics display, in
   --  user coordinates.  In other words, calling Space sets the affine
   --  transformation from user coordinates to device coordinates.
   --  This operation must be performed at the beginning of each
   --  page of graphics, i.e., immediately after Open is invoked.

   procedure Space_Extended (P          : in Plotter;
                             C0, C1, C2 : in Complex);
   --  The Arguments are the three defining vertices of an `affine
   --  window' (a drawing parallelogram), in complex user coordinates.  The
   --  specified vertices are the lower left, the lower right, and the
   --  upper left.  This window will be mapped affinely onto the graphics
   --  display.

   procedure Move (P : in Plotter;
                   C : in Complex);
   --  Move takes a complex argument C specifying the coordinates of a point
   --  to which the graphics cursor should be moved.  The path under
   --  construction (if any) is ended, and the graphics cursor is moved to
   --  C.  This is equivalent to lifting the pen on a plotter and moving
   --  it to a new position, without drawing any line.
   procedure Move_Relative (P : in Plotter;
                            C : in Complex);
   --  Move_Relative is similar to Move, but uses cursor-relative coordinates.

   procedure Continue (P : in Plotter;
                       C : in Complex);
   --  Continue takes a complex argument specifying the coordinates of a
   --  point.  If a path is under construction, the line segment from the
   --  current graphics cursor position to the point C is added to it.
   --  Otherwise the line segment begins a new path.  In all cases the
   --  graphics cursor is moved to C.
   procedure Continue_Relative (P : in Plotter;
                                C : in Complex);
   --  Continue_Relative is similar to Continue, but uses cursor-relative
   --  coordinates.

   procedure Line_Width (P    : in Plotter;
                         Size : in Real'Base);
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
                   C0, C1 : in Complex);
   --  Line takes two complex arguments specifying the start point C0 and end
   --  point C1 of a line segment.  If the graphics cursor is at C0 and a path
   --  is under construction, the line segment is added to it.  Otherwise the
   --  path under construction (if any) is ended, and the line segment begins
   --  a new path.  In all cases the graphics cursor is moved to C1.
   procedure Line_Relative (P      : in Plotter;
                            C0, C1 : in Complex);
   --  Line_Relative is similar to Line, but uses cursor-relative coordinates.

   procedure Point (P : in Plotter;
                    C : in Complex);
   --  Point takes a complex argument specifying the coordinates of a point.
   --  The path under construction (if any) is ended, and the point is plotted.
   --  (A `point' is usually a small solid circle, perhaps the smallest that
   --  can be plotted.)  The graphics cursor is moved to C.
   procedure Point_Relative (P : in Plotter;
                             C : in Complex);
   --  Point_Relative is similar to Point but uses cursor-relative coordinates.

   procedure Arc (P         : in Plotter;
                  C, C0, C1 : in Complex);
   --  Arc takes three complex arguments specifying the beginning C0, end C1,
   --  and center C of a circular arc.  If the graphics cursor is at C0 and a
   --  path is under construction, then the arc is added to the path.
   --  Otherwise the current path (if any) is ended, and the arc begins a new
   --  path.  In all cases the graphics cursor is moved to C1.
   --
   --  The direction of the arc (clockwise or counterclockwise) is
   --  determined by the convention that the arc, centered at C,
   --  sweep through an angle of at most 180 degrees.  If the three
   --  points appear to be collinear, the direction is taken to be
   --  counterclockwise.  If C is not equidistant from C0 and
   --  C1 as it should be, it is corrected by being moved to the
   --  closest point on the perpendicular bisector of the line segment
   --  joining C0 and C1.
   procedure Arc_Relative (P         : in Plotter;
                           C, C0, C1 : in Complex);
   --  Arc_Relative is similar to Arc but uses cursor-relative coordinates.

   procedure Elliptical_Arc (P         : in Plotter;
                             C, C0, C1 : in Complex);
   --  Elliptical_Arc takes six arguments specifying the three points
   --  C, C0, C1 that define a so-called quarter ellipse.  This is an
   --  elliptic arc from C0 to C1 with center C.  If the graphics cursor is at
   --  point C0 and a path is under construction, the quarter-ellipse is added
   --  to it.  Otherwise the path under construction (if any) is ended, and
   --  the quarter-ellipse begins a new path.  In all cases the graphics
   --  cursor is moved to C1.
   --
   --  The quarter-ellipse is an affinely transformed version of a quarter
   --  circle.  It is drawn so as to have control points C0, C1, and C0+C1-C.
   --  This means that it is tangent at C0 to the line segment joining C0 to
   --  C0+C1-C, and is tangent at C1 to the line segment joining C1 to
   --  C0+C1-C.  So it fits snugly into a triangle with these three control
   --  points as vertices.  Notice that the third control point is the
   --  reflection of C through the line joining C0 and C1.
   procedure Elliptical_Arc_Relative (P         : in Plotter;
                                      C, C0, C1 : in Complex);
   --  Elliptical_Arc_Relative is similar to Elliptical_Arc, but uses
   --  cursor-relative coordinates.

   procedure Circle (P : in Plotter;
                     C : in Complex;
                     R : in Real'Base);
   --  Circle takes three arguments specifying the center C and radius (R) of
   --  a circle.  The path under construction (if any) is ended, and the
   --  circle is drawn.  The graphics cursor is moved to C.
   procedure Circle_Relative (P : in Plotter;
                              C : in Complex;
                              R : in Real'Base);
   --  Circle_Relative is similar to Circle, but uses cursor-relative
   --  coordinates for C.

   procedure Ellipse (P      : in Plotter;
                      C      : in Complex;
                      Rx, Ry : in Real'Base;
                      Angle  : in Real'Base);
   --  Ellipse takes four arguments specifying the center C of an
   --  ellipse, the lengths of its semiaxes (Rx and Ry), and the inclination
   --  of the first semiaxis in the counterclockwise direction from the x axis
   --  in the user frame.  The path under construction (if any) is ended, and
   --  the ellipse is drawn.  The graphics cursor is moved to C.
   procedure Ellipse_Relative (P      : in Plotter;
                               C      : in Complex;
                               Rx, Ry : in Real'Base;
                               Angle  : in Real'Base);
   --  Ellipse_Relative is similar to Ellipse, but uses cursor-relative
   --  coordinates.

   procedure Box (P      : in Plotter;
                  C0, C1 : in Complex);
   --  Box takes two complex arguments specifying the lower left corner
   --  C0 and upper right corner C1 of a `box', or rectangle.
   --  The path under construction (if any) is ended, and the box is
   --  drawn as a new path.  This path is also ended, and the graphics
   --  cursor is moved to the midpoint of the box.
   procedure Box_Relative (P      : in Plotter;
                           C0, C1 : in Complex);
   --  Box_Relative is similar to Box but uses cursor-relative coordinates.

   procedure Quadratic_Bezier_Curve (P          : in Plotter;
                                     C0, C1, C2 : in Complex);
   --  Quadratic_Bezier_Curve takes three arguments specifying the beginning
   --  C0 and end C2 of a quadratic Bezier curve, and its intermediate control
   --  point C1.  If the graphics cursor is at `C0' and a path is under
   --  construction, then the curve is added to the path.  Otherwise the
   --  current path (if any) is ended, and the curve begins a new path.  In
   --  all cases the graphics cursor is moved to `C2'.
   --  The quadratic Bezier curve is tangent at `C0' to the line segment
   --  joining `C0' to `C1', and is tangent at `C2' to the line segment
   --  joining `C1' to `C2'.  So it fits snugly into a triangle with
   --  vertices `C0', `C1', and `C2'.
   --
   --  When using a PCL Plotter to draw Bezier curves on a LaserJet III,
   --  you should set the parameter `PCL_BEZIERS' to "no".  That is
   --  because the LaserJet III, which was Hewlett-Packard's first PCL 5
   --  printer, does not recognize the Bezier instructions supported by
   --  later PCL 5 printers.

   procedure Quadratic_Bezier_Curve_Relative (P          : in Plotter;
                                              C0, C1, C2 : in Complex);
   --  This is similar to Quadratic_Bezier_Curve but uses cursor relative
   --  coordinates.

   procedure Cubic_Bezier_Curve (P              : in Plotter;
                                 C0, C1, C2, C3 : in Complex);
   --  Cubic_Bezier_Curve takes four arguments specifying the beginning
   --  `C0' and end `C3' of a cubic Bezier curve, and its intermediate control
   --  points `C1' and `C2'. If the graphics cursor is at `C0' and a path is
   --  under construction, then the curve is added to the path.  Otherwise the
   --  current path (if any) is ended, and the curve begins a new path.
   --  In all cases the graphics cursor is moved to `C3'.
   --
   --  The cubic Bezier curve is tangent at `C0' to the line segment
   --  joining `C0' to `C1', and is tangent at `C3' to the line segment
   --  joining `C2' to `C3'.  So it fits snugly into a quadrangle with
   --  vertices `C0', `C1', `C2', and `C3'.
   --
   --  When using a PCL Plotter to draw Bezier curves on a LaserJet III,
   --  you should set the parameter `PCL_BEZIERS' to "no".  That is
   --  because the LaserJet III, which was Hewlett-Packard's first PCL 5
   --  printer, does not recognize the Bezier instructions supported by
   --  later PCL 5 printers.

   procedure Cubic_Bezier_Curve_Relative (P              : in Plotter;
                                          C0, C1, C2, C3 : in Complex);
   --  This is similar to Cubic_Bezier_Curve but uses cursor relative
   --  coordinates.

   procedure Marker (P     : in Plotter;
                     C     : in Complex;
                     Shape : in Marker_Type;
                     Size  : in Real'Base);
   procedure Marker (P     : in Plotter;
                     C     : in Complex;
                     Ch    : in Character;
                     Size  : in Real'Base);
   --  Marker takes three arguments specifying the location C of a marker
   --  symbol, its type, and its size in user coordinates.  The path under
   --  construction (if any) is ended, and the marker symbol is plotted.  The
   --  graphics cursor is moved to C.
   --
   --  The marker type can either be a member of an enumeration of predefined
   --  marker symbols or a printable character.
   procedure Marker_Relative (P     : in Plotter;
                              C     : in Complex;
                              Shape : in Marker_Type;
                              Size  : in Real'Base);
   procedure Marker_Relative (P     : in Plotter;
                              C     : in Complex;
                              Ch    : in Character;
                              Size  : in Real'Base);
   --  Marker_Relative is similar to Marker but use cursor-relative
   --  coordinates for the position C.

   function Text_Angle (P     : in Plotter;
                        Angle : in Real'Base) return Real'Base;
   --  Text_Angle takes one argument, which specifies the angle in degrees
   --  counterclockwise from the real (horizontal) axis in the user frame, for
   --  text strings subsequently drawn on the graphics display.  The default
   --  angle is zero.  (The font for plotting strings is fully specified by
   --  calling fontname, fontsize, and textangle.)  The size of the font for
   --  plotting strings, in user coordinates, is returned.

   function Font_Name (P    : in Plotter;
                       Name : in String) return Real'Base;
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
   function Font_Name (P : in Plotter) return Real'Base;
   --  The size of the default font in user coordinates is returned.

   function Font_Size (P    : in Plotter;
                       Size : in Real'Base) return Real'Base;
   --  Font_Size takes a single argument, interpreted as the
   --  size, in the user frame, of the font to be used for all text
   --  strings subsequently drawn on the graphics display.  (The font for
   --  plotting strings is fully specified by calling fontname, fontsize,
   --  and textangle.)  The size of the font in user coordinates is
   --  returned.
   function Font_Size (P : in Plotter) return Real'Base;
   --  Set the font size to its default value and return the size of the font
   --  in user coordinates.

   function Label_Width (P    : in Plotter;
                         Text : in String) return Real'Base;
   --  Label_Width computes and returns the width of a string in the current
   --  font, in the user frame.  The string is not plotted.
   --

   procedure Concatenate_Transformation
     (M0, M1, M2, M3 : in Real'Base; T : in Complex);
   --  Apply a Postscript-style transformation matrix, i.e., affine map,
   --  to the user coordinate system.  That is, apply the linear
   --  transformation defined by the two-by-two matrix [M0 M1 M2 M3] to
   --  the user coordinate system, and also translate by Re(T) units in the
   --  real direction and Im(Y) units in the imaginary direction, relative to
   --  the former user coordinate system.  The following three functions
   --  (Rotate, Scale, Translate) are convenience functions that are
   --  special cases of Concatenate_Transformation.

   procedure Rotate (P     : in Plotter;
                     Theta : in Real'Base);
   --  Rotate the user coordinate system axes about their origin by Theta
   --  degrees, with respect to their former orientation.  The position
   --  of the user coordinate origin and the size of the real and imaginary
   --  units remain unchanged.

   procedure Scale (P     : in Plotter;
                    Scale : in Complex);
   --  Make the real and imaginary units in the user coordinate system be the
   --  size of Re(Scale) and Im(Scale) units in the former user coordinate
   --  system. The position of the user coordinate origin and the orientation
   --  of the coordinate axes are unchanged.

   procedure Translate (P : in Plotter;
                        T : in Complex);
   --  Move the origin of the user coordinate system by Re(T) units in the
   --  real direction and Im(T) units in the imaginary direction, relative to
   --  the former user coordinate system.  The size of the real and imaginary
   --  units and the orientation of the coordinate axes are unchanged.

   type Dashes is array (Natural range <>) of Real'Base;

   procedure Line_Dash (P              : in Plotter;
                        Dash_Distances : in Dashes;
                        Offset         : in Real'Base);
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

   pragma Inline (Space);
   pragma Inline (Space_Extended);
   pragma Inline (Move);
   pragma Inline (Move_Relative);
   pragma Inline (Continue);
   pragma Inline (Continue_Relative);
   pragma Inline (Line_Width);
   pragma Inline (Line);
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
   pragma Inline (Concatenate_Transformation);
   pragma Inline (Rotate);
   pragma Inline (Scale);
   pragma Inline (Translate);

end GNU.plotutil.cplot;
