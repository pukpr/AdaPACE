-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                            GNU.plotutil.cplot                             --
--                                                                           --
--                                 B O D Y                                   --
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
with GNU.plotutil.fplot;

package body GNU.plotutil.cplot is

   package RP is new GNU.plotutil.fplot (Real); use RP;

   procedure Space (P      : in Plotter;
                    C0, C1 : in Complex) is
   begin
      Space (P, Re (C0), Im (C0), Re (C1), Im (C1));
   end Space;

   procedure Space_Extended (P          : in Plotter;
                             C0, C1, C2 : in Complex) is
   begin
      Space_Extended (P,
                      Re (C0), Im (C0),
                      Re (C1), Im (C1),
                      Re (C2), Im (C2));
   end Space_Extended;

   procedure Move (P : in Plotter;
                   C : in Complex) is
   begin
      Move (P, Re (C), Im (C));
   end Move;

   procedure Move_Relative (P : in Plotter;
                            C : in Complex) is
   begin
      Move_Relative (P, Re (C), Im (C));
   end Move_Relative;

   procedure Continue (P : in Plotter;
                       C : in Complex) is
   begin
      Continue (P, Re (C), Im (C));
   end Continue;

   procedure Continue_Relative (P : in Plotter;
                                C : in Complex) is
   begin
      Continue_Relative (P, Re (C), Im (C));
   end Continue_Relative;

   procedure Line_Width (P    : in Plotter;
                         Size : in Real'Base) is
   begin
      RP.Line_Width (P, Size);
   end Line_Width;

   procedure Line_Width (P : in Plotter) is
   begin
      RP.Line_Width (P);
   end Line_Width;

   procedure Line (P      : in Plotter;
                   C0, C1 : in Complex) is
   begin
      Line (P, Re (C0), Im (C0), Re (C1), Im (C1));
   end Line;

   procedure Line_Relative (P      : in Plotter;
                            C0, C1 : in Complex) is
   begin
      Line_Relative (P, Re (C0), Im (C0), Re (C1), Im (C1));
   end Line_Relative;

   procedure Point (P : in Plotter;
                    C : in Complex) is
   begin
      Point (P, Re (C), Im (C));
   end Point;

   procedure Point_Relative (P : in Plotter;
                             C : in Complex) is
   begin
      Point_Relative (P, Re (C), Im (C));
   end Point_Relative;

   procedure Arc (P         : in Plotter;
                  C, C0, C1 : in Complex) is
   begin
      Arc (P, Re (C), Im (C), Re (C0), Im (C0), Re (C1), Im (C1));
   end Arc;

   procedure Arc_Relative (P         : in Plotter;
                           C, C0, C1 : in Complex) is
   begin
      Arc_Relative (P, Re (C), Im (C), Re (C0), Im (C0), Re (C1), Im (C1));
   end Arc_Relative;

   procedure Elliptical_Arc (P         : in Plotter;
                             C, C0, C1 : in Complex) is
   begin
      Elliptical_Arc (P, Re (C), Im (C), Re (C0), Im (C0), Re (C1), Im (C1));
   end Elliptical_Arc;

   procedure Elliptical_Arc_Relative (P         : in Plotter;
                                      C, C0, C1 : in Complex) is
   begin
      Elliptical_Arc_Relative (P,
                               Re (C), Im (C),
                               Re (C0), Im (C0),
                               Re (C1), Im (C1));
   end Elliptical_Arc_Relative;

   procedure Box (P      : in Plotter;
                  C0, C1 : in Complex) is
   begin
      Box (P, Re (C0), Im (C0), Re (C1), Im (C1));
   end Box;

   procedure Box_Relative (P      : in Plotter;
                           C0, C1 : in Complex) is
   begin
      Box_Relative (P, Re (C0), Im (C0), Re (C1), Im (C1));
   end Box_Relative;

   procedure Circle (P : in Plotter;
                     C : in Complex;
                     R : in Real'Base) is
   begin
      Circle (P, Re (C), Im (C), R);
   end Circle;

   procedure Circle_Relative (P : in Plotter;
                              C : in Complex;
                              R : in Real'Base) is
   begin
      Circle_Relative (P, Re (C), Im (C), R);
   end Circle_Relative;

   procedure Ellipse (P      : in Plotter;
                      C      : in Complex;
                      Rx, Ry : in Real'Base;
                      Angle  : in Real'Base) is
   begin
      Ellipse (P, Re (C), Im (C), Rx, Ry, Angle);
   end Ellipse;

   procedure Ellipse_Relative (P      : in Plotter;
                               C      : in Complex;
                               Rx, Ry : in Real'Base;
                               Angle  : in Real'Base) is
   begin
      Ellipse_Relative (P, Re (C), Im (C), Rx, Ry, Angle);
   end Ellipse_Relative;

   procedure Quadratic_Bezier_Curve (P          : in Plotter;
                                     C0, C1, C2 : in Complex) is
   begin
      Quadratic_Bezier_Curve (P,
                              Re (C0), Im (C0),
                              Re (C1), Im (C1),
                              Re (C2), Im (C2));
   end Quadratic_Bezier_Curve;

   procedure Quadratic_Bezier_Curve_Relative (P          : in Plotter;
                                              C0, C1, C2 : in Complex) is
   begin
      Quadratic_Bezier_Curve_Relative (P,
                                       Re (C0), Im (C0),
                                       Re (C1), Im (C1),
                                       Re (C2), Im (C2));
   end Quadratic_Bezier_Curve_Relative;

   procedure Cubic_Bezier_Curve (P              : in Plotter;
                                 C0, C1, C2, C3 : in Complex) is
   begin
      Cubic_Bezier_Curve (P,
                          Re (C0), Im (C0),
                          Re (C1), Im (C1),
                          Re (C2), Im (C2),
                          Re (C3), Im (C3));
   end Cubic_Bezier_Curve;

   procedure Cubic_Bezier_Curve_Relative (P              : in Plotter;
                                          C0, C1, C2, C3 : in Complex) is
   begin
      Cubic_Bezier_Curve_Relative (P,
                                   Re (C0), Im (C0),
                                   Re (C1), Im (C1),
                                   Re (C2), Im (C2),
                                   Re (C3), Im (C3));
   end Cubic_Bezier_Curve_Relative;

   procedure Marker (P     : in Plotter;
                     C     : in Complex;
                     Shape : in Marker_Type;
                     Size  : in Real'Base) is
   begin
      Marker (P, Re (C), Im (C), Shape, Size);
   end Marker;

   procedure Marker (P    : in Plotter;
                     C    : in Complex;
                     Ch   : in Character;
                     Size : in Real'Base) is
   begin
      Marker (P, Re (C), Im (C), Ch, Size);
   end Marker;

   procedure Marker_Relative (P     : in Plotter;
                              C     : in Complex;
                              Shape : in Marker_Type;
                              Size  : in Real'Base) is
   begin
      Marker_Relative (P, Re (C), Im (C), Shape, Size);
   end Marker_Relative;

   procedure Marker_Relative (P    : in Plotter;
                              C    : in Complex;
                              Ch   : in Character;
                              Size : in Real'Base) is
   begin
      Marker_Relative (P, Re (C), Im (C), Ch, Size);
   end Marker_Relative;

   function Text_Angle (P     : in Plotter;
                        Angle : in Real'Base) return Real'Base is
   begin
      return RP.Text_Angle (P, Angle);
   end Text_Angle;

   function Font_Name (P    : in Plotter;
                       Name : in String) return Real'Base is
   begin
      return RP.Font_Name (P, Name);
   end Font_Name;

   function Font_Name (P : in Plotter) return Real'Base is
   begin
      return RP.Font_Name (P);
   end Font_Name;

   function Font_Size (P    : in Plotter;
                       Size : in Real'Base) return Real'Base is
   begin
      return RP.Font_Size (P, Size);
   end Font_Size;

   function Font_Size (P : in Plotter) return Real'Base is
   begin
      return RP.Font_Size (P);
   end Font_Size;

   function Label_Width (P    : in Plotter;
                         Text : in String) return Real'Base is
   begin
      return RP.Label_Width (P, Text);
   end Label_Width;

   procedure Concatenate_Transformation (M0, M1, M2, M3 : in Real'Base;
                                         T : in Complex) is
   begin
      Concatenate_Transformation (M0, M1, M2, M3, Re (T), Im (T));
   end Concatenate_Transformation;

   procedure Rotate (P     : in Plotter;
                     Theta : in Real'Base) is
   begin
      RP.Rotate (P, Theta);
   end Rotate;

   procedure Scale (P     : in Plotter;
                    Scale : in Complex) is
   begin
      RP.Scale (P, Re (Scale), Im (Scale));
   end Scale;

   procedure Translate (P : in Plotter;
                        T : in Complex) is
   begin
      Translate (P, Re (T), Im (T));
   end Translate;

   procedure Line_Dash (P              : in Plotter;
                        Dash_Distances : in Dashes;
                        Offset         : in Real'Base) is
   begin
      RP.Line_Dash (P, RP.Dashes (Dash_Distances), Offset);
   end Line_Dash;

end GNU.plotutil.cplot;
