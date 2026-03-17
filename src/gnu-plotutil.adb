-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                              GNU.plotutil                                 --
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
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Exceptions;
with Interfaces.C.Strings;

package body GNU.plotutil is

   subtype C_Int    is Interfaces.C.int;
   subtype C_String is Interfaces.C.char_array;
   subtype P_String is Interfaces.C.Strings.chars_ptr;
   use type C_Int;

   procedure Delete (P : in Plotter) is
      function deletepl (H : in Plotter) return C_Int;
      pragma Import (C, deletepl, "pl_deletepl_r");

      Res : C_Int;
   begin
      Res := deletepl (P);
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Delete;

   procedure Open (P : Plotter) is
      function openpl (P : Plotter) return C_Int;
      pragma Import (C, openpl, "pl_openpl_r");

      Res : constant C_Int := openpl (P);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Open;

   procedure Close (P : in Plotter) is
      function closepl (P : in Plotter) return C_Int;
      pragma Import (C, closepl, "pl_closepl_r");

      Res : constant C_Int := closepl (P);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Close;

   procedure Erase (P : in Plotter) is
      function c_erase (P : in Plotter) return C_Int;
      pragma Import (C, c_erase, "pl_erase_r");

      Res : constant C_Int := c_erase (P);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Erase;

   procedure Flush (P : in Plotter) is
      function flushpl (P : in Plotter) return C_Int;
      pragma Import (C, flushpl, "pl_flushpl_r");

      Res : constant C_Int := flushpl (P);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Flush;
   --
   --  ######################################################################
   --
   procedure ColorName (P    : in Plotter;
                        Name : in String) is
      function colorname (P : in Plotter;
                          S : C_String) return C_Int;
      pragma Import (C, colorname, "pl_colorname_r");

      Res : constant C_Int := colorname (P, Interfaces.C.To_C (Name));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end ColorName;

   procedure Color (P                : in Plotter;
                    Red, Green, Blue : in RGB_Value) is
      function color (P       : in Plotter;
                      R, G, B : C_Int) return C_Int;
      pragma Import (C, color, "pl_color_r");

      Res : constant C_Int := color (P,
                                     C_Int (Red),
                                     C_Int (Green),
                                     C_Int (Blue));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Color;
   --
   --  ######################################################################
   --
   procedure Fill_ColorName (P    : in Plotter;
                             Name : in String) is
      function fillcolorname (P : in Plotter;
                              S : C_String) return C_Int;
      pragma Import (C, fillcolorname, "pl_fillcolorname_r");

      Res : constant C_Int := fillcolorname (P, Interfaces.C.To_C (Name));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Fill_ColorName;

   procedure Fill_Color (P                : in Plotter;
                         Red, Green, Blue : in RGB_Value) is
      function fillcolor (P       : in Plotter;
                          R, G, B : C_Int) return C_Int;
      pragma Import (C, fillcolor, "pl_fillcolor_r");

      Res : constant C_Int := fillcolor (P,
                                         C_Int (Red),
                                         C_Int (Green),
                                         C_Int (Blue));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Fill_Color;
   --
   --  ######################################################################
   --
   procedure Pen_ColorName (P    : in Plotter;
                            Name : in String) is
      function pencolorname (P : in Plotter;
                             S : C_String) return C_Int;
      pragma Import (C, pencolorname, "pl_pencolorname_r");

      Res : constant C_Int := pencolorname (P, Interfaces.C.To_C (Name));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Pen_ColorName;

   procedure Pen_Color (P                : in Plotter;
                        Red, Green, Blue : in RGB_Value) is
      function pencolor (P       : in Plotter;
                         R, G, B : C_Int) return C_Int;
      pragma Import (C, pencolor, "pl_pencolor_r");

      Res : constant C_Int := pencolor (P,
                                        C_Int (Red),
                                        C_Int (Green),
                                        C_Int (Blue));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Pen_Color;

   procedure Pen_Type (P     : in Plotter;
                       Level : in Pen_Type_Level := Outline) is
      function pentype (P : in Plotter;
                        L : in C_Int) return C_Int;
      pragma Import (C, pentype, "pl_pentype_r");

      Res : constant C_Int := pentype (P,
                                       C_Int (Pen_Type_Level'Pos (Level)));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Pen_Type;

   procedure Background_ColorName (P    : in Plotter;
                                   Name : in String) is
      function bgcolorname (P : in Plotter;
                            S : C_String) return C_Int;
      pragma Import (C, bgcolorname, "pl_bgcolorname_r");

      Res : constant C_Int := bgcolorname (P, Interfaces.C.To_C (Name));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Background_ColorName;

   procedure Background_Color (P                : in Plotter;
                               Red, Green, Blue : in RGB_Value) is
      function bgcolor (P       : in Plotter;
                        R, G, B : C_Int) return C_Int;
      pragma Import (C, bgcolor, "pl_bgcolor_r");

      Res : constant C_Int := bgcolor (P,
                                       C_Int (Red),
                                       C_Int (Green),
                                       C_Int (Blue));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Background_Color;
   --
   --  ######################################################################
   --
   type H_Char is array (Horizontal_Justification) of Character;
   type V_Char is array (Vertical_Justification)   of Character;

   H_Map : constant H_Char := (Left   => 'l',
                               Center => 'c',
                               Right  => 'r');
   V_Map : constant V_Char := (Bottom   => 'b',
                               Baseline => 'x',
                               Center   => 'c',
                               Top      => 't',
                               Cap_Line => 'C');

   procedure Label (P         : in Plotter;
                    H_Justify : in Horizontal_Justification := Left;
                    V_Justify : in Vertical_Justification   := Baseline;
                    Text      : in String) is
      function alabel (P    : in Plotter;
                       H, V : C_Int;
                       L    : C_String) return C_Int;
      pragma Import (C, alabel, "pl_alabel_r");

      H    : constant C_Int := Character'Pos (H_Map (H_Justify));
      V    : constant C_Int := Character'Pos (V_Map (V_Justify));
      Res  : constant C_Int := alabel (P, H, V, Interfaces.C.To_C (Text));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Label;
   --
   --  ######################################################################
   --
   procedure Line_Mode (P    : in Plotter;
                        Mode : in Line_Type) is
      function linemod (P : in Plotter;
                        S : C_String) return C_Int;
      pragma Import (C, linemod, "pl_linemod_r");

      Res : constant C_Int :=
        linemod (P, Interfaces.C.To_C (To_Lower (Line_Type'Image (Mode))));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Line_Mode;
   --
   --  ######################################################################
   --
   procedure Cap_Mode (P     : in Plotter;
                       Style : in Cap_Style := Butt) is
      function capmod (P : in Plotter;
                       S : C_String) return C_Int;
      pragma Import (C, capmod, "pl_capmod_r");

      Res : constant C_Int :=
        capmod (P, Interfaces.C.To_C (To_Lower (Cap_Style'Image (Style))));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Cap_Mode;
   --
   --  ######################################################################
   --
   procedure Filltype (P     : in Plotter;
                       Level : in Filltype_Level := 0) is
      function C_Filltype (P : in Plotter;
                           L : C_Int) return C_Int;
      pragma Import (C, C_Filltype, "pl_filltype_r");

      Res : constant C_Int := C_Filltype (P, C_Int (Level));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Filltype;
   --
   --  ######################################################################
   --
   procedure End_Path (P : in Plotter) is
      function endpath (P : in Plotter) return C_Int;
      pragma Import (C, endpath, "pl_endpath_r");

      Res : constant C_Int := endpath (P);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end End_Path;
   --
   --  ######################################################################
   --
   procedure End_Subpath (P : in Plotter)
   is
      function endsubpath (P : in Plotter) return C_Int;
      pragma Import (C, endsubpath, "pl_endsubpath_r");

      Res : constant C_Int := endsubpath (P);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end End_Subpath;
   --
   --  ######################################################################
   --
   procedure Orientation (P   : in Plotter;
                          Dir : in Direction := Counterclockwise)
   is
      function C_Orientation (P : in Plotter;
                              D : in C_Int) return C_Int;
      pragma Import (C, C_Orientation, "pl_orientation_r");

      Res  : C_Int;
      Cdir : C_Int;
   begin
      if Dir = Clockwise then
         Cdir := -1;
      else
         Cdir := 1;
      end if;
      Res := C_Orientation (P, Cdir);
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Orientation;
   --
   --  ######################################################################
   --
   function Has_Capability (P          : in Plotter;
                            Capability : String) return Capability_Existence is
      function havecap (P : in Plotter;
                        S : C_String) return C_Int;
      pragma Import (C, havecap, "pl_havecap_r");

      R : constant C_Int := havecap (P, Interfaces.C.To_C (Capability));
   begin
      case R is
         when 0 => return No;
         when 1 => return Yes;
         when 2 => return Maybe;
         when others => raise Plot_Exception;
      end case;
   end Has_Capability;
   --
   --  ######################################################################
   --
   procedure Join_Mode (P     : in Plotter;
                        Style : in Join_Style := Miter) is
      function joinmod (P : in Plotter;
                        S : C_String) return C_Int;
      pragma Import (C, joinmod, "pl_joinmod_r");

      Res : constant C_Int :=
        joinmod (P, Interfaces.C.To_C (To_Lower (Join_Style'Image (Style))));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Join_Mode;
   --
   procedure Miter_Limit (P     : in Plotter;
                          Limit : in Interfaces.C.double) is
      function fmiterlimit (P     : in Plotter;
                            Limit : in Interfaces.C.double) return C_Int;
      pragma Import (C, fmiterlimit, "pl_fmiterlimit_r");

      Res : constant C_Int := fmiterlimit (P, Limit);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Miter_Limit;

   --  ######################################################################
   --
   procedure Pop_State (P : in Plotter) is
      function restorestate (P : in Plotter) return C_Int;
      pragma Import (C, restorestate, "pl_restorestate_r");

      Res : constant C_Int := restorestate (P);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Pop_State;

   procedure Push_State (P : in Plotter) is
      function savestate (P : in Plotter) return C_Int;
      pragma Import (C, savestate, "pl_savestate_r");

      Res : constant C_Int := savestate (P);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Push_State;

   type Error_Handler is access procedure (Err : in P_String);
   pragma Convention (C, Error_Handler);

   Error_Hook : Error_Handler;
   pragma Import (C, Error_Hook, "libplot_error_handler");

   procedure Ada_Error_Handler (Err : in P_String);
   pragma Convention (C, Ada_Error_Handler);

   procedure Ada_Error_Handler (Err : in P_String) is
      Message : constant String := Interfaces.C.Strings.Value (Err);
   begin
      Ada.Exceptions.Raise_Exception (Plot_Exception'Identity, Message);
   end Ada_Error_Handler;

begin
   Error_Hook := Ada_Error_Handler'Access;
end GNU.plotutil;
