-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                            GNU.plotutil.fplot                             --
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
use  Interfaces.C;
use  Interfaces.C.Strings;

package body GNU.plotutil.fplot is

   subtype C_Int is Interfaces.C.int;

   procedure Space (P      : in Plotter;
                    X0, Y0 : in Real;
                    X1, Y1 : in Real) is
      function C_space (P   : Plotter;
                        px0 : double;
                        py0 : double;
                        px1 : double;
                        py1 : double)
                        return C_Int;
      pragma Import (C, C_space, "pl_fspace_r");

      Res : constant C_Int := C_space (P,
                                       double (X0),
                                       double (Y0),
                                       double (X1),
                                       double (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Space;

   procedure Space_Extended (P      : in Plotter;
                             X0, Y0 : in Real;
                             X1, Y1 : in Real;
                             X2, Y2 : in Real) is
      function C_space2 (P   : Plotter;
                         px0 : double;
                         py0 : double;
                         px1 : double;
                         py1 : double;
                         px2 : double;
                         py2 : double) return C_Int;
      pragma Import (C, C_space2, "pl_fspace2_r");

      Res : constant C_Int := C_space2 (P,
                                        double (X0),
                                        double (Y0),
                                        double (X1),
                                        double (Y1),
                                        double (X2),
                                        double (Y2));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Space_Extended;

   procedure Set_Matrix (P              : in Plotter;
                         M0, M1, M2, M3 : in Real;
                         TX, TY         : in Real)
   is
      function fsetmatrix (P   : Plotter;
                           pm0 : double;
                           pm1 : double;
                           pm2 : double;
                           pm3 : double;
                           ptx : double;
                           pty : double) return C_Int;
      pragma Import (C, fsetmatrix, "pl_fsetmatrix_r");

      Res : constant C_Int := fsetmatrix (P,
                                          double (M0),
                                          double (M1),
                                          double (M2),
                                          double (M3),
                                          double (TX),
                                          double (TY));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Set_Matrix;

   procedure Move (P    : in Plotter;
                   X, Y : in Real) is
      function fmove (P      : Plotter;
                      Px, Py : double) return C_Int;
      pragma Import (C, fmove, "pl_fmove_r");

      Res : constant C_Int := fmove (P, double (X), double (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Move;

   procedure Move_Relative (P    : in Plotter;
                            X, Y : in Real) is
      function fmoverel (P      : Plotter;
                         Px, Py : double) return C_Int;
      pragma Import (C, fmoverel, "pl_fmoverel_r");

      Res : constant C_Int := fmoverel (P, double (X), double (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Move_Relative;

   procedure Continue (P    : in Plotter;
                       X, Y : in Real) is
      function fcont (P      : Plotter;
                      Px, Py : double) return C_Int;
      pragma Import (C, fcont, "pl_fcont_r");

      Res : constant C_Int := fcont (P, double (X), double (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Continue;

   procedure Continue_Relative (P    : in Plotter;
                                X, Y : in Real) is
      function fcontrel (P      : Plotter;
                         Px, Py : double) return C_Int;
      pragma Import (C, fcontrel, "pl_fcontrel_r");

      Res : constant C_Int := fcontrel (P, double (X), double (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Continue_Relative;

   procedure Line_Width (P    : in Plotter;
                         Size : in Real'Base) is
      function flinewidth (P : Plotter;
                           S : double) return C_Int;
      pragma Import (C, flinewidth, "pl_flinewidth_r");

      Res : constant C_Int := flinewidth (P, double (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Line_Width;

   procedure Line_Width (P : in Plotter) is
   begin
      Line_Width (P, Real'Base (-1.0));
   end Line_Width;

   procedure Line (P      : in Plotter;
                   X0, Y0 : in Real;
                   X1, Y1 : in Real) is
      function fline (P : Plotter;
                      Px0, Py0, Px1, Py1 : double) return C_Int;
      pragma Import (C, fline, "pl_fline_r");

      Res : constant C_Int := fline (P,
                                     double (X0),
                                     double (Y0),
                                     double (X1),
                                     double (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Line;

   procedure Line_Relative (P      : in Plotter;
                            X0, Y0 : in Real;
                            X1, Y1 : in Real) is
      function flinerel (P : Plotter;
                         px0, py0, px1, py1 : double) return C_Int;
      pragma Import (C, flinerel, "pl_flinerel_r");

      Res : constant C_Int := flinerel (P,
                                        double (X0),
                                        double (Y0),
                                        double (X1),
                                        double (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Line_Relative;

   procedure Point (P    : in Plotter;
                    X, Y : in Real) is
      function fpoint (P      : Plotter;
                       Px, Py : double) return C_Int;
      pragma Import (C, fpoint, "pl_fpoint_r");

      Res : constant C_Int := fpoint (P, double (X), double (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Point;

   procedure Point_Relative (P    : in Plotter;
                             X, Y : in Real) is
      function fpointrel (P      : Plotter;
                          Px, Py : double) return C_Int;
      pragma Import (C, fpointrel, "pl_fpointrel_r");

      Res : constant C_Int := fpointrel (P, double (X), double (Y));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Point_Relative;

   procedure Arc (P      : in Plotter;
                  XC, YC : in Real;
                  X0, Y0 : in Real;
                  X1, Y1 : in Real) is
      function C_Arc (P : Plotter;
                      pxc, pyc, px0, py0, px1, py1 : double) return C_Int;
      pragma Import (C, C_Arc, "pl_farc_r");

      Res : constant C_Int := C_Arc (P,
                                     double (XC),
                                     double (YC),
                                     double (X0),
                                     double (Y0),
                                     double (X1),
                                     double (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Arc;

   procedure Arc_Relative (P      : in Plotter;
                           XC, YC : in Real;
                           X0, Y0 : in Real;
                           X1, Y1 : in Real) is
      function C_Arcrel (P : Plotter;
                         pxc, pyc, px0, py0, px1, py1 : double) return C_Int;
      pragma Import (C, C_Arcrel, "pl_farcrel_r");

      Res : constant C_Int := C_Arcrel (P,
                                        double (XC),
                                        double (YC),
                                        double (X0),
                                        double (Y0),
                                        double (X1),
                                        double (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Arc_Relative;

   procedure Elliptical_Arc (P      : in Plotter;
                             XC, YC : in Real;
                             X0, Y0 : in Real;
                             X1, Y1 : in Real) is
      function fellarc (P : Plotter;
                        pxc, pyc, px0, py0, px1, py1 : double) return C_Int;
      pragma Import (C, fellarc, "pl_fellarc_r");

      Res : constant C_Int := fellarc (P,
                                       double (XC),
                                       double (YC),
                                       double (X0),
                                       double (Y0),
                                       double (X1),
                                       double (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Elliptical_Arc;

   procedure Elliptical_Arc_Relative (P      : in Plotter;
                                      XC, YC : in Real;
                                      X0, Y0 : in Real;
                                      X1, Y1 : in Real) is
      function fellarcrel (P : Plotter;
                           pxc, pyc, px0, py0, px1, py1 : double) return C_Int;
      pragma Import (C, fellarcrel, "pl_fellarcrel_r");

      Res : constant C_Int := fellarcrel (P,
                                          double (XC),
                                          double (YC),
                                          double (X0),
                                          double (Y0),
                                          double (X1),
                                          double (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Elliptical_Arc_Relative;

   procedure Box (P      : in Plotter;
                  X0, Y0 : in Real;
                  X1, Y1 : in Real) is
      function C_Box (P : Plotter;
                      px0, py0, px1, py1 : double) return C_Int;
      pragma Import (C, C_Box, "pl_fbox_r");

      Res : constant C_Int := C_Box (P,
                                     double (X0),
                                     double (Y0),
                                     double (X1),
                                     double (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Box;

   procedure Box_Relative (P      : in Plotter;
                           X0, Y0 : in Real;
                           X1, Y1 : in Real) is
      function C_Boxrel (P : Plotter;
                         px0, py0, px1, py1 : double) return C_Int;
      pragma Import (C, C_Boxrel, "pl_fboxrel_r");

      Res : constant C_Int := C_Boxrel (P,
                                        double (X0),
                                        double (Y0),
                                        double (X1),
                                        double (Y1));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Box_Relative;

   procedure Circle (P      : in Plotter;
                     XC, YC : in Real;
                     R      : in Real'Base) is
      function C_Circle (P : Plotter;
                         X0, Y0, Rad : double) return C_Int;
      pragma Import (C, C_Circle, "pl_fcircle_r");

      Res : constant C_Int := C_Circle (P,
                                        double (XC), double (YC),
                                        double (R));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Circle;

   procedure Circle_Relative (P      : in Plotter;
                              XC, YC : in Real;
                              R      : in Real'Base) is
      function C_Circlerel (P : Plotter;
                            X0, Y0, Rad : double) return C_Int;
      pragma Import (C, C_Circlerel, "pl_fcirclerel_r");

      Res : constant C_Int := C_Circlerel (P,
                                           double (XC),
                                           double (YC),
                                           double (R));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Circle_Relative;

   procedure Ellipse (P      : in Plotter;
                      XC, YC : in Real;
                      Rx, Ry : in Real'Base;
                      Angle  : in Real'Base) is
      function fellipse (P : Plotter;
                         px, py, prx, pry, pang : double) return C_Int;
      pragma Import (C, fellipse, "pl_fellipse_r");

      Res : constant C_Int := fellipse (P,
                                        double (XC),
                                        double (YC),
                                        double (Rx),
                                        double (Ry),
                                        double (Angle));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Ellipse;

   procedure Ellipse_Relative (P      : in Plotter;
                               XC, YC : in Real;
                               Rx, Ry : in Real'Base;
                               Angle  : in Real'Base)
   is
      function fellipserel (P : Plotter;
                            px, py, prx, pry, pang : double) return C_Int;
      pragma Import (C, fellipserel, "pl_fellipserel_r");

      Res : constant C_Int := fellipserel (P,
                                           double (XC),
                                           double (YC),
                                           double (Rx),
                                           double (Ry),
                                           double (Angle));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Ellipse_Relative;

   procedure Quadratic_Bezier_Curve (P      : in Plotter;
                                     X0, Y0 : in Real;
                                     X1, Y1 : in Real;
                                     X2, Y2 : in Real) is
      function bezier2 (P : Plotter;
                        X0, Y0, X1, Y1, X2, Y2 : double) return C_Int;
      pragma Import (C, bezier2, "pl_fbezier2_r");

      Res : constant C_Int := bezier2 (P,
                                       double (X0), double (Y0),
                                       double (X1), double (Y1),
                                       double (X2), double (Y2));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Quadratic_Bezier_Curve;

   procedure Quadratic_Bezier_Curve_Relative (P      : in Plotter;
                                              X0, Y0 : in Real;
                                              X1, Y1 : in Real;
                                              X2, Y2 : in Real)
   is
      function bezier2rel (P : Plotter;
                           X0, Y0, X1, Y1, X2, Y2 : double) return C_Int;
      pragma Import (C, bezier2rel, "pl_fbezier2rel_r");

      Res : constant C_Int := bezier2rel (P,
                                          double (X0), double (Y0),
                                          double (X1), double (Y1),
                                          double (X2), double (Y2));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Quadratic_Bezier_Curve_Relative;

   procedure Cubic_Bezier_Curve (P      : in Plotter;
                                 X0, Y0 : in Real;
                                 X1, Y1 : in Real;
                                 X2, Y2 : in Real;
                                 X3, Y3 : in Real)
   is
      function bezier3 (P : Plotter;
                        X0, Y0, X1, Y1, X2, Y2, X3, Y3 : double) return C_Int;
      pragma Import (C, bezier3, "pl_fbezier3_r");

      Res : constant C_Int := bezier3 (P,
                                       double (X0), double (Y0),
                                       double (X1), double (Y1),
                                       double (X2), double (Y2),
                                       double (X3), double (Y3));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Cubic_Bezier_Curve;

   procedure Cubic_Bezier_Curve_Relative (P      : in Plotter;
                                          X0, Y0 : in Real;
                                          X1, Y1 : in Real;
                                          X2, Y2 : in Real;
                                          X3, Y3 : in Real)
   is
      function bezier3rel (P : Plotter;
                           X0, Y0,
                             X1, Y1, X2, Y2, X3, Y3 : double) return C_Int;
      pragma Import (C, bezier3rel, "pl_fbezier3rel_r");

      Res : constant C_Int := bezier3rel (P,
                                          double (X0), double (Y0),
                                          double (X1), double (Y1),
                                          double (X2), double (Y2),
                                          double (X3), double (Y3));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Cubic_Bezier_Curve_Relative;

   procedure Marker (P     : in Plotter;
                     X, Y  : in Real;
                     Shape : in Marker_Type;
                     Size  : in Real'Base) is
      function C_Marker (P : Plotter;
                         px, py : double;
                         T : C_Int; S : double) return C_Int;
      pragma Import (C, C_Marker, "pl_fmarker_r");

      Res : constant C_Int := C_Marker (P,
                                        double (X),
                                        double (Y),
                                        C_Int (Marker_Type'Pos (Shape)),
                                        double (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Marker;

   procedure Marker (P    : in Plotter;
                     X, Y : in Real;
                     Ch   : in Character;
                     Size : in Real'Base) is
      function C_Marker (P : Plotter;
                         px, py : double;
                         T : C_Int; S : double) return C_Int;
      pragma Import (C, C_Marker, "pl_fmarker_r");

      Res : constant C_Int := C_Marker (P,
                                        double (X),
                                        double (Y),
                                        C_Int (Character'Pos (Ch)),
                                        double (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Marker;

   procedure Marker_Relative (P     : in Plotter;
                              X, Y  : in Real;
                              Shape : in Marker_Type;
                              Size  : in Real'Base) is
      function C_Markerrel (P : Plotter;
                            px, py : double;
                            T : C_Int; S : double) return C_Int;
      pragma Import (C, C_Markerrel, "pl_fmarkerrel_r");

      Res : constant C_Int := C_Markerrel (P,
                                           double (X),
                                           double (Y),
                                           C_Int (Marker_Type'Pos (Shape)),
                                           double (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Marker_Relative;

   procedure Marker_Relative (P    : in Plotter;
                              X, Y : in Real;
                              Ch   : in Character;
                              Size : in Real'Base) is
      function C_Markerrel (P : Plotter;
                            px, py : double;
                            T : C_Int; S : double) return C_Int;
      pragma Import (C, C_Markerrel, "pl_fmarkerrel_r");

      Res : constant C_Int := C_Markerrel (P,
                                           double (X),
                                           double (Y),
                                           C_Int (Character'Pos (Ch)),
                                           double (Size));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Marker_Relative;

   function Text_Angle (P     : in Plotter;
                        Angle : in Real'Base) return Real'Base is
      function ftextangle (P : Plotter;
                           A : double) return double;
      pragma Import (C, ftextangle, "pl_ftextangle_r");

      R : constant Real'Base := Real'Base (ftextangle (P, double (Angle)));
   begin
      return R;
   end Text_Angle;

   function Font_Name (P    : in Plotter;
                       Name : in String) return Real'Base is
      function ffontname (P : Plotter;
                          S : char_array) return double;
      pragma Import (C, ffontname, "pl_ffontname_r");

      R : constant Real'Base :=
        Real'Base (ffontname (P, Interfaces.C.To_C (Name)));
   begin
      return R;
   end Font_Name;

   function Font_Name (P : in Plotter) return Real'Base is
      function ffontname (P : in Plotter;
                          S : chars_ptr) return double;
      pragma Import (C, ffontname, "pl_ffontname_r");

      R : constant Real'Base := Real'Base (ffontname (P, Null_Ptr));
   begin
      return R;
   end Font_Name;

   function Font_Size (P    : in Plotter;
                       Size : in Real'Base) return Real'Base is
      function ffontsize (P : Plotter;
                          S : double) return double;
      pragma Import (C, ffontsize, "pl_ffontsize_r");

      R : constant Real'Base := Real'Base (ffontsize (P, double (Size)));
   begin
      return R;
   end Font_Size;

   function Font_Size (P : in Plotter) return Real'Base is
   begin
      return Font_Size (P, Real'Base (-1.0));
   end Font_Size;

   function Label_Width (P    : in Plotter;
                         Text : in String) return Real'Base is
      function flabelwidth (P : Plotter;
                            S : char_array) return double;
      pragma Import (C, flabelwidth, "pl_flabelwidth_r");

      R : constant Real'Base := Real'Base (flabelwidth (P, To_C (Text)));
   begin
      return R;
   end Label_Width;

   procedure Concatenate_Transformation (M0, M1,
                                           M2, M3,
                                           TX, TY : in Real'Base) is
      function fconcat (pm0, pm1, pm2, pm3, px, py : double) return C_Int;
      pragma Import (C, fconcat, "pl_fconcat");

      Res : constant C_Int := fconcat (double (M0),
                                       double (M1),
                                       double (M2),
                                       double (M3),
                                       double (TX),
                                       double (TY));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Concatenate_Transformation;

   procedure Rotate (P     : in Plotter;
                     Theta : in Real'Base) is
      function frotate (P : Plotter;
                        A : double) return C_Int;
      pragma Import (C, frotate, "pl_frotate_r");

      Res : constant C_Int := frotate (P, double (Theta));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Rotate;

   procedure Scale (P              : in Plotter;
                    ScaleX, ScaleY : in Real'Base) is
      function fscale (P : Plotter;
                       sx, sy : double) return C_Int;
      pragma Import (C, fscale, "pl_fscale_r");

      Res : constant C_Int := fscale (P, double (ScaleX), double (ScaleY));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Scale;

   procedure Translate (P      : in Plotter;
                        TX, TY : in Real'Base) is
      function ftranslate (P : Plotter;
                           sx, sy : double) return C_Int;
      pragma Import (C, ftranslate, "pl_ftranslate_r");

      Res : constant C_Int := ftranslate (P, double (TX), double (TY));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Translate;

   procedure Line_Dash (P              : in Plotter;
                        Dash_Distances : in Dashes;
                        Offset         : in Real'Base) is

      type Double_Array is array (Natural range <>) of aliased double;
      package C_Double_Array is new
        Interfaces.C.Pointers (Natural, double, Double_Array, 0.0);

      function linedash (P      : Plotter;
                         N      : C_Int;
                         Dashes : C_Double_Array.Pointer;
                         Offset : double) return C_Int;
      pragma Import (C, linedash, "pl_flinedash_r");

      Res : C_Int;
   begin
      if Dash_Distances'Length = 0 then
         Res := linedash (P, 0, null, double (Offset));
      else
         declare
            N : constant Integer := Dash_Distances'Length;
            D : Double_Array (0 .. (N - 1));
         begin
            for I in Dash_Distances'Range loop
               D (I - Dash_Distances'First) := double (Dash_Distances (I));
            end loop;
            Res := linedash (P, C_Int (N),
                             D (0)'Unrestricted_Access,
                             double (Offset));
         end;
      end if;
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Line_Dash;

end GNU.plotutil.fplot;
