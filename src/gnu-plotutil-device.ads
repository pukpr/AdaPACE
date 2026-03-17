-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                           GNU.plotutil.Device                             --
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
with System;
with System.Storage_Elements;
with Ada.Finalization;
with Interfaces.C_Streams;

package GNU.plotutil.Device is

   type Plotter_Parameter is private;
   No_Plotter_Parameter : constant Plotter_Parameter;

   Meta_Device_Type  : constant String := "meta";
   PNM_Device_Type   : constant String := "pnm";
   GIF_Device_Type   : constant String := "gif";
   AI_Device_Type    : constant String := "ai";
   FIG_Device_Type   : constant String := "fig";
   HPGL_Device_Type  : constant String := "hpgl";
   PCL_Device_Type   : constant String := "pcl";
   PS_Device_Type    : constant String := "ps";
   TEK_Device_Type   : constant String := "tek";
   CGM_Device_Type   : constant String := "cgm";
   PNG_Device_Type   : constant String := "png";
   SVG_Device_Type   : constant String := "svg";
   ReGIS_Device_Type : constant String := "regis";
   X_Device_Type     : constant String := "X";
   XDRW_Device_Type  : constant String := "Xdrawable";


   function Create return Plotter_Parameter;
   --  Create a new plotter parameter to be used to set device specific
   --  properties. The system automatically handles the memory associated
   --  with the parameter structure.

   function Clone (Param : Plotter_Parameter)
                   return Plotter_Parameter;
   --  Create an exact copy of the parameter using its own storage.

   procedure Set (Parameter     : in Plotter_Parameter;
                  Property_Name : in String;
                  Value         : in String);

   --  Set the value of the given property `Property_Name' to `Value'
   --  Parameters are used for setting low-level device driver
   --  options.
   --  The most important parameters are `DISPLAY', which specifies the
   --  X Window System display that an X Plotter will use, and `PAGESIZE',
   --  which affects Postscript, Fig, and HP-GL Plotters.
   --
   --  For most parameters, the value is a String.

   procedure Set (Parameter     : in Plotter_Parameter;
                  Property_Name : in String;
                  Value         : in System.Address);
   --  This is for the few parameters that don't expect String values
   --  but for example X-Display structures.

   generic
      DriverName : in String;
   function New_Direct_Plotter (Param : Plotter_Parameter
                                  := No_Plotter_Parameter)
     return Plotter;
   --  Create a new plotter for a "direct" device, i.e. an X or Xdrawable
   --  devicetype.

   generic
      DriverName : in String;
   function New_File_Plotter (Filename : String := "";
                              Param    : Plotter_Parameter
                                := No_Plotter_Parameter)
     return Plotter;
   --  Write all plotcommands to the named file. The file will be created
   --  if it doesn't exist. If it exists it will be recreated.
   --  If you pass and empty string or a "-" as Filename parameter, the
   --  output will go to stdout.
   --  This works for all non-direct devicetypes, i.e. anything different
   --  from X of Xdrawable

   procedure Close_File (P : in Plotter_Parameter);

private
   function Create_Plotter (Device_Type, Filename : String;
                            Param : Plotter_Parameter := No_Plotter_Parameter)
     return Plotter;
   --  Create a new plotter of the specified device type.
   --  Write all plotcommands to the named file. The file will be created
   --  if it doesn't exist. If it exists it will be recreated.
   --  If you pass and empty string or a "-" as Filename parameter, the
   --  output will go to stdout

   type C_Level_Param is new System.Storage_Elements.Integer_Address;
   No_Pl_Param : constant C_Level_Param := 0;

   type Plotter_Parameter_Info is new Ada.Finalization.Controlled with
      record
         Param : C_Level_Param := No_Pl_Param;
         File : Interfaces.C_Streams.FILEs;
      end record;

   type Plotter_Parameter is access Plotter_Parameter_Info;
   No_Plotter_Parameter : constant Plotter_Parameter := null;

   procedure Initialize (Object : in out Plotter_Parameter_Info);
   procedure Adjust     (Object : in out Plotter_Parameter_Info);
   procedure Finalize   (Object : in out Plotter_Parameter_Info);

   pragma Inline (Create);
   pragma Inline (Clone);
   pragma Inline (Set);

   pragma Inline (Initialize);
   pragma Inline (Adjust);
   pragma Inline (Finalize);

end GNU.plotutil.Device;
