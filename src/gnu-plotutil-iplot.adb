-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                            GNU.plotutil.iplot                             --
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
with Interfaces.C.Strings;
with Interfaces.C.Pointers;
use Interfaces.C;
use Interfaces.C.Strings;

package body GNU.plotutil.iplot is

   subtype C_Int is Interfaces.C.int;

   function Num_Check (R : in C_Int) return Int'Base;

   function Num_Check (R : in C_Int) return Int'Base is
   begin
      if R in C_Int (Int'Base'First) .. C_Int (Int'Base'Last) then
         return Int'Base (R);
      else
         raise Plot_Exception;
      end if;
   end Num_Check;
   pragma Inline (Num_Check);

   procedure Space (P      : in Plotter;
                    X0, Y0 : in Int;
                    X1, Y1 : in Int) is
      function C_space (P   : Plotter;
                        px0 : C_Int; py0 : C_Int; px1 : C_Int; py1 : C_Int)
        return C_Int;
      pragma Import (C, C_space, "pl_space_r");

      Res : constant C_Int := C_space (P,
                                       C_Int (X0),
                                       C_Int (Y0),
                                       C_Int (X1),
                                       C_Int (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Space;

   procedure Space_Extended (P      : in Plotter;
                             X0, Y0 : in Int;
                             X1, Y1 : in Int;
                             X2, Y2 : in Int) is
      function C_space2 (P   : Plotter;
                         px0 : C_Int;
                         py0 : C_Int;
                         px1 : C_Int;
                         py1 : C_Int;
                         px2 : C_Int;
                         py2 : C_Int) return C_Int;
      pragma Import (C, C_space2, "pl_space2_r");

      Res : constant C_Int := C_space2 (P,
                                        C_Int (X0),
                                        C_Int (Y0),
                                        C_Int (X1),
                                        C_Int (Y1),
                                        C_Int (X2),
                                        C_Int (Y2));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Space_Extended;

   procedure Move (P    : in Plotter;
                   X, Y : in Int) is
      function C_move (P      : Plotter;
                       Px, Py : C_Int) return C_Int;
      pragma Import (C, C_move, "pl_move_r");

      Res : constant C_Int := C_move (P, C_Int (X), C_Int (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Move;

   procedure Move_Relative (P    : in Plotter;
                            X, Y : in Int) is
      function moverel (P      : Plotter;
                        Px, Py : C_Int) return C_Int;
      pragma Import (C, moverel, "pl_moverel_r");

      Res : constant C_Int := moverel (P, C_Int (X), C_Int (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Move_Relative;

   procedure Continue (P    : in Plotter;
                       X, Y : in Int) is
      function cont (P      : Plotter;
                     Px, Py : C_Int) return C_Int;
      pragma Import (C, cont, "pl_cont_r");

      Res : constant C_Int := cont (P, C_Int (X), C_Int (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Continue;

   procedure Continue_Relative (P    : in Plotter;
                                X, Y : in Int) is
      function contrel (P      : Plotter;
                        Px, Py : C_Int) return C_Int;
      pragma Import (C, contrel, "pl_contrel_r");

      Res : constant C_Int := contrel (P, C_Int (X), C_Int (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Continue_Relative;

   procedure Line_Width (P    : in Plotter;
                         Size : in Int'Base) is
      function linewidth (P : Plotter;
                          S : C_Int) return C_Int;
      pragma Import (C, linewidth, "pl_linewidth_r");

      Res : constant C_Int := linewidth (P, C_Int (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Line_Width;

   procedure Line_Width (P : in Plotter) is
   begin
      Line_Width (P, -1);
   end Line_Width;

   procedure Line (P      : in Plotter;
                   X0, Y0 : in Int;
                   X1, Y1 : in Int) is
      function C_line (P : Plotter;
                       Px0, Py0, Px1, Py1 : C_Int) return C_Int;
      pragma Import (C, C_line, "pl_line_r");

      Res : constant C_Int := C_line (P,
                                      C_Int (X0),
                                      C_Int (Y0),
                                      C_Int (X1),
                                      C_Int (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Line;

   procedure Line_Relative (P      : in Plotter;
                            X0, Y0 : in Int;
                            X1, Y1 : in Int) is
      function linerel (P : Plotter;
                        px0, py0, px1, py1 : C_Int) return C_Int;
      pragma Import (C, linerel, "pl_linerel_r");

      Res : constant C_Int := linerel (P,
                                       C_Int (X0),
                                       C_Int (Y0),
                                       C_Int (X1),
                                       C_Int (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Line_Relative;

   procedure Point (P    : in Plotter;
                    X, Y : in Int) is
      function point (P      : Plotter;
                      Px, Py : C_Int) return C_Int;
      pragma Import (C, point, "pl_point_r");

      Res : constant C_Int := point (P, C_Int (X), C_Int (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Point;

   procedure Point_Relative (P    : in Plotter;
                             X, Y : in Int) is
      function pointrel (P      : Plotter;
                         Px, Py : C_Int) return C_Int;
      pragma Import (C, pointrel, "pl_pointrel_r");

      Res : constant C_Int := pointrel (P, C_Int (X), C_Int (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Point_Relative;

   procedure Arc (P      : in Plotter;
                  XC, YC : in Int;
                  X0, Y0 : in Int;
                  X1, Y1 : in Int) is
      function C_Arc (P : Plotter;
                      pxc, pyc, px0, py0, px1, py1 : C_Int) return C_Int;
      pragma Import (C, C_Arc, "pl_arc_r");

      Res : constant C_Int := C_Arc (P,
                                     C_Int (XC),
                                     C_Int (YC),
                                     C_Int (X0),
                                     C_Int (Y0),
                                     C_Int (X1),
                                     C_Int (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Arc;

   procedure Arc_Relative (P      : in Plotter;
                           XC, YC : in Int;
                           X0, Y0 : in Int;
                           X1, Y1 : in Int) is
      function C_Arcrel (P : Plotter;
                         pxc, pyc, px0, py0, px1, py1 : C_Int) return C_Int;
      pragma Import (C, C_Arcrel, "pl_arcrel_r");

      Res : constant C_Int := C_Arcrel (P,
                                        C_Int (XC),
                                        C_Int (YC),
                                        C_Int (X0),
                                        C_Int (Y0),
                                        C_Int (X1),
                                        C_Int (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Arc_Relative;

   procedure Elliptical_Arc (P      : in Plotter;
                             XC, YC : in Int;
                             X0, Y0 : in Int;
                             X1, Y1 : in Int) is
      function ellarc (P : Plotter;
                       pxc, pyc, px0, py0, px1, py1 : C_Int) return C_Int;
      pragma Import (C, ellarc, "pl_ellarc_r");

      Res : constant C_Int := ellarc (P,
                                      C_Int (XC),
                                      C_Int (YC),
                                      C_Int (X0),
                                      C_Int (Y0),
                                      C_Int (X1),
                                      C_Int (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Elliptical_Arc;

   procedure Elliptical_Arc_Relative (P      : in Plotter;
                                      XC, YC : in Int;
                                      X0, Y0 : in Int;
                                      X1, Y1 : in Int) is
      function ellarcrel (P : Plotter;
                          pxc, pyc, px0, py0, px1, py1 : C_Int) return C_Int;
      pragma Import (C, ellarcrel, "pl_ellarcrel_r");

      Res : constant C_Int := ellarcrel (P,
                                         C_Int (XC),
                                         C_Int (YC),
                                         C_Int (X0),
                                         C_Int (Y0),
                                         C_Int (X1),
                                         C_Int (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Elliptical_Arc_Relative;

   procedure Box (P      : in Plotter;
                  X0, Y0 : in Int;
                  X1, Y1 : in Int) is
      function C_Box (P : Plotter;
                      px0, py0, px1, py1 : C_Int) return C_Int;
      pragma Import (C, C_Box, "pl_box_r");

      Res : constant C_Int := C_Box (P,
                                     C_Int (X0),
                                     C_Int (Y0),
                                     C_Int (X1),
                                     C_Int (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Box;

   procedure Box_Relative (P      : in Plotter;
                           X0, Y0 : in Int;
                           X1, Y1 : in Int) is
      function C_Boxrel (P : Plotter;
                         px0, py0, px1, py1 : C_Int) return C_Int;
      pragma Import (C, C_Boxrel, "pl_boxrel_r");

      Res : constant C_Int := C_Boxrel (P,
                                        C_Int (X0),
                                        C_Int (Y0),
                                        C_Int (X1),
                                        C_Int (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Box_Relative;

   procedure Circle (P      : in Plotter;
                     XC, YC : in Int;
                     R      : in Int'Base) is
      function C_Circle (P : Plotter;
                         X0, Y0, Rad : C_Int) return C_Int;
      pragma Import (C, C_Circle, "pl_circle_r");

      Res : constant C_Int := C_Circle (P, C_Int (XC), C_Int (YC), C_Int (R));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Circle;

   procedure Circle_Relative (P      : in Plotter;
                              XC, YC : in Int;
                              R      : in Int'Base) is
      function C_Circlerel (P : Plotter;
                            X0, Y0, Rad : C_Int) return C_Int;
      pragma Import (C, C_Circlerel, "pl_circlerel_r");

      Res : constant C_Int := C_Circlerel (P,
                                           C_Int (XC),
                                           C_Int (YC),
                                           C_Int (R));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Circle_Relative;

   procedure Ellipse (P      : in Plotter;
                      XC, YC : in Int;
                      Rx, Ry : in Int'Base;
                      Angle  : in Int'Base) is
      function C_Ellipse (P : Plotter;
                          px, py, prx, pry, pang : C_Int) return C_Int;
      pragma Import (C, C_Ellipse, "pl_ellipse_r");

      Res : constant C_Int := C_Ellipse (P,
                                         C_Int (XC),
                                         C_Int (YC),
                                         C_Int (Rx),
                                         C_Int (Ry),
                                         C_Int (Angle));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Ellipse;

   procedure Ellipse_Relative (P      : in Plotter;
                               XC, YC : in Int;
                               Rx, Ry : in Int'Base;
                               Angle  : in Int'Base) is
      function C_Ellipserel (P : Plotter;
                             px, py, prx, pry, pang : C_Int) return C_Int;
      pragma Import (C, C_Ellipserel, "pl_ellipserel_r");

      Res : constant C_Int := C_Ellipserel (P,
                                            C_Int (XC),
                                            C_Int (YC),
                                            C_Int (Rx),
                                            C_Int (Ry),
                                            C_Int (Angle));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Ellipse_Relative;

   procedure Quadratic_Bezier_Curve (P      : in Plotter;
                                     X0, Y0 : in Int;
                                     X1, Y1 : in Int;
                                     X2, Y2 : in Int) is
      function bezier2 (P : Plotter;
                        X0, Y0, X1, Y1, X2, Y2 : C_Int) return C_Int;
      pragma Import (C, bezier2, "pl_bezier2_r");

      Res : constant C_Int := bezier2 (P,
                                       C_Int (X0), C_Int (Y0),
                                       C_Int (X1), C_Int (Y1),
                                       C_Int (X2), C_Int (Y2));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Quadratic_Bezier_Curve;

   procedure Quadratic_Bezier_Curve_Relative (P      : in Plotter;
                                              X0, Y0 : in Int;
                                              X1, Y1 : in Int;
                                              X2, Y2 : in Int)
   is
      function bezier2rel (P : Plotter;
                           X0, Y0, X1, Y1, X2, Y2 : C_Int) return C_Int;
      pragma Import (C, bezier2rel, "pl_bezier2rel_r");

      Res : constant C_Int := bezier2rel (P,
                                          C_Int (X0), C_Int (Y0),
                                          C_Int (X1), C_Int (Y1),
                                          C_Int (X2), C_Int (Y2));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Quadratic_Bezier_Curve_Relative;

   procedure Cubic_Bezier_Curve (P      : in Plotter;
                                 X0, Y0 : in Int;
                                 X1, Y1 : in Int;
                                 X2, Y2 : in Int;
                                 X3, Y3 : in Int)
   is
      function bezier3 (P : Plotter;
                        X0, Y0, X1, Y1, X2, Y2, X3, Y3 : C_Int) return C_Int;
      pragma Import (C, bezier3, "pl_bezier3_r");

      Res : constant C_Int := bezier3 (P,
                                       C_Int (X0), C_Int (Y0),
                                       C_Int (X1), C_Int (Y1),
                                       C_Int (X2), C_Int (Y2),
                                       C_Int (X3), C_Int (Y3));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Cubic_Bezier_Curve;

   procedure Cubic_Bezier_Curve_Relative (P      : in Plotter;
                                          X0, Y0 : in Int;
                                          X1, Y1 : in Int;
                                          X2, Y2 : in Int;
                                          X3, Y3 : in Int)
   is
      function bezier3rel (P : Plotter;
                           X0, Y0,
                             X1, Y1, X2, Y2, X3, Y3 : C_Int) return C_Int;
      pragma Import (C, bezier3rel, "pl_bezier3rel_r");

      Res : constant C_Int := bezier3rel (P,
                                          C_Int (X0), C_Int (Y0),
                                          C_Int (X1), C_Int (Y1),
                                          C_Int (X2), C_Int (Y2),
                                          C_Int (X3), C_Int (Y3));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Cubic_Bezier_Curve_Relative;

   procedure Marker (P     : in Plotter;
                     X, Y  : in Int;
                     Shape : in Marker_Type;
                     Size  : in Int'Base) is
      function C_Marker (P : Plotter;
                         px, py, T, S : C_Int) return C_Int;
      pragma Import (C, C_Marker, "pl_marker_r");

      Res : constant C_Int := C_Marker (P,
                                        C_Int (X),
                                        C_Int (Y),
                                        C_Int (Marker_Type'Pos (Shape)),
                                        C_Int (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Marker;

   procedure Marker (P    : in Plotter;
                     X, Y : in Int;
                     Ch   : in Character;
                     Size : in Int'Base) is
      function C_Marker (P : Plotter;
                         px, py, T, S : C_Int) return C_Int;
      pragma Import (C, C_Marker, "pl_marker_r");

      Res : constant C_Int := C_Marker (P,
                                        C_Int (X),
                                        C_Int (Y),
                                        C_Int (Character'Pos (Ch)),
                                        C_Int (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Marker;

   procedure Marker_Relative (P     : in Plotter;
                              X, Y  : in Int;
                              Shape : in Marker_Type;
                              Size  : in Int'Base) is
      function C_Markerrel (P : Plotter;
                            px, py, T, S : C_Int) return C_Int;
      pragma Import (C, C_Markerrel, "pl_markerrel_r");

      Res : constant C_Int := C_Markerrel (P,
                                           C_Int (X),
                                           C_Int (Y),
                                           C_Int (Marker_Type'Pos (Shape)),
                                           C_Int (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Marker_Relative;

   procedure Marker_Relative (P    : in Plotter;
                              X, Y : in Int;
                              Ch   : in Character;
                              Size : in Int'Base) is
      function C_Markerrel (P : Plotter;
                            px, py, T, S : C_Int) return C_Int;
      pragma Import (C, C_Markerrel, "pl_markerrel_r");

      Res : constant C_Int := C_Markerrel (P,
                                           C_Int (X),
                                           C_Int (Y),
                                           C_Int (Character'Pos (Ch)),
                                           C_Int (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Marker_Relative;

   function Text_Angle (P     : in Plotter;
                        Angle : in Int'Base) return Int'Base is
      function textangle (P : Plotter;
                          A : C_Int) return C_Int;
      pragma Import (C, textangle, "pl_textangle_r");

      R : constant C_Int := textangle (P, C_Int (Angle));
   begin
      return Num_Check (R);
   end Text_Angle;

   function Font_Name (P    : in Plotter;
                       Name : in String) return Int'Base is
      function fontname (P : Plotter;
                         S : char_array) return C_Int;
      pragma Import (C, fontname, "pl_fontname_r");

      R : constant C_Int := fontname (P, Interfaces.C.To_C (Name));
   begin
      return Num_Check (R);
   end Font_Name;

   function Font_Name (P : in Plotter) return Int'Base is
      function fontname (P : Plotter;
                         S : chars_ptr) return C_Int;
      pragma Import (C, fontname, "pl_fontname_r");

      R : constant C_Int := fontname (P, Null_Ptr);
   begin
      return Num_Check (R);
   end Font_Name;

   function Font_Size (P    : in Plotter;
                       Size : in Int'Base) return Int'Base is
      function fontsize (P : Plotter;
                         S : C_Int) return C_Int;
      pragma Import (C, fontsize, "pl_fontsize_r");

      R : constant C_Int := fontsize (P, C_Int (Size));
   begin
      return Num_Check (R);
   end Font_Size;

   function Font_Size (P : in Plotter) return Int'Base is
   begin
      return Font_Size (P, -1);
   end Font_Size;

   function Label_Width (P    : in Plotter;
                         Text : in String) return Int'Base is
      function labelwidth (P : Plotter;
                           S : in char_array) return C_Int;
      pragma Import (C, labelwidth, "pl_labelwidth_r");

      R : constant C_Int := labelwidth (P, To_C (Text));
   begin
      return Num_Check (R);
   end Label_Width;


   procedure Line_Dash (P              : in Plotter;
                        Dash_Distances : in Dashes;
                        Offset         : in Int'Base) is

      type Int_Array is array (Natural range <>) of aliased C_Int;
      package C_Int_Array is new
        Interfaces.C.Pointers (Natural, C_Int, Int_Array, 0);

      function linedash (P      : Plotter;
                         N      : in C_Int;
                         Dashes : in C_Int_Array.Pointer;
                         Offset : in C_Int) return C_Int;
      pragma Import (C, linedash, "pl_linedash_r");

      Res : C_Int;
   begin
      if Dash_Distances'Length = 0 then
         Res := linedash (P, 0, null, C_Int (Offset));
      else
         declare
            N : constant Integer := Dash_Distances'Length;
            D : Int_Array (0 .. (N - 1));
         begin
            for I in Dash_Distances'Range loop
               D (I - Dash_Distances'First) := C_Int (Dash_Distances (I));
            end loop;
            Res := linedash (P,
                             C_Int (N),
                             D (0)'Unrestricted_Access,
                             C_Int (Offset));
         end;
      end if;
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Line_Dash;

end GNU.plotutil.iplot;
