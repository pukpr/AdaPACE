-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                           GNU.plotutil.Device                             --
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
with Interfaces.C_Streams;
with Interfaces.C;

package body GNU.plotutil.Device is

   use type Interfaces.C.int;

   package CIO renames Interfaces.C_Streams;
   subtype C_Int    is Interfaces.C.int;
   subtype C_String is Interfaces.C.char_array;

   function New_Plotter_Parameter (P : in Plotter_Parameter)
                                   return Plotter_Parameter;

   function newpl (Name    : C_String;
                   F_In    : CIO.FILEs;
                   F_Out   : CIO.FILEs;
                   F_Err   : CIO.FILEs;
                   P_Param : C_Level_Param) return Plotter;
   pragma Import (C, newpl, "pl_newpl_r");

   function New_Plotter_Parameter (P : in Plotter_Parameter)
                                   return Plotter_Parameter is
      function newplparams return Plotter_Parameter;
      pragma Warnings (off, newplparams);
      pragma Import (C, newplparams, "pl_newplparams");
   begin
      if P = No_Plotter_Parameter then
         return Create;
      else
         return P;
      end if;
   end New_Plotter_Parameter;
   pragma Inline (New_Plotter_Parameter);

   function Create_Plotter (Device_Type, Filename : String;
                            Param : Plotter_Parameter := No_Plotter_Parameter)
     return Plotter is
      Plt : Plotter;
      F   : CIO.FILEs;
      M   : constant C_String := Interfaces.C.To_C ("w");
   begin
      if Filename = "" or Filename = "-" then
         F := CIO.stdout;
      else
         F := CIO.fopen (Interfaces.C.To_C (Filename)'Address,
                         M'Address);
      end if;
--PP
      declare
         PP : Plotter_Parameter;
      begin
         PP := New_Plotter_Parameter (Param);
         Plt := newpl (Interfaces.C.To_C (Device_Type),
                       CIO.NULL_Stream,
                       F,
                       CIO.stderr,
                       PP.all.Param);
         PP.File := F;
      end;
--PP
      if Plt = No_Plotter then
         raise Plot_Exception;
      else
         return Plt;
      end if;
   end Create_Plotter;

   function Create return Plotter_Parameter is
      Res : constant Plotter_Parameter := new Plotter_Parameter_Info;
   begin
      if Res = No_Plotter_Parameter then
         raise Plot_Exception;
      end if;
      return Res;
   end Create;

   function Clone (Param : Plotter_Parameter)
                   return Plotter_Parameter is
      Res : Plotter_Parameter;
   begin
      if Param = No_Plotter_Parameter then
         raise Plot_Exception;
      else
         Res := Create;
         Res.all := Param.all;
         return Res;
      end if;
   end Clone;

   procedure Set (Parameter     : in Plotter_Parameter;
                  Property_Name : in String;
                  Value         : in String) is
      function parampl (Param : C_Level_Param;
                        P, V  : C_String) return C_Int;
      pragma Import (C, parampl, "pl_setplparam");
      Res : constant C_Int := parampl (Parameter.all.Param,
                                       Interfaces.C.To_C (Property_Name),
                                       Interfaces.C.To_C (Value));
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Set;

   procedure Set (Parameter     : in Plotter_Parameter;
                  Property_Name : in String;
                  Value         : in System.Address) is
      function parampl (Param : C_Level_Param;
                        P     : C_String;
                        V     : System.Address) return C_Int;
      pragma Import (C, parampl, "pl_setplparam");
      Res : constant C_Int := parampl (Parameter.all.Param,
                                       Interfaces.C.To_C (Property_Name),
                                       Value);
   begin
      if Res < 0 then
         raise Plot_Exception;
      end if;
   end Set;

   procedure Initialize (Object : in out Plotter_Parameter_Info) is
      function newplparams return C_Level_Param;
      pragma Import (C, newplparams, "pl_newplparams");
   begin
      Object.Param := newplparams;
      if Object.Param = No_Pl_Param then
         raise Plot_Exception;
      end if;
   end Initialize;

   procedure Adjust     (Object : in out Plotter_Parameter_Info) is
      function copyplparams (P : C_Level_Param) return C_Level_Param;
      pragma Import (C, copyplparams, "pl_copyplparams");
   begin
      if Object.Param /= No_Pl_Param then
         Object.Param := copyplparams (Object.Param);
         if Object.Param = No_Pl_Param then
            raise Plot_Exception;
         end if;
      end if;
   end Adjust;

   procedure Close_File (P : in Plotter_Parameter) is
      Ret : Integer;
   begin
      Ret := CIO.fclose (P.File);
   end;

   procedure Finalize   (Object : in out Plotter_Parameter_Info) is
      function deleteplparams (P : C_Level_Param) return C_Int;
      pragma Import (C, deleteplparams, "pl_deleteplparams");

      Res : C_Int;
      Ret : Integer;
   begin
      if Object.Param /= No_Pl_Param then
--PP
         Ret := CIO.fclose (Object.File);
--PP
         Res := deleteplparams (Object.Param);
         Object.Param := No_Pl_Param;
         if Res < 0 then
            raise Plot_Exception;
         end if;
      end if;
   end Finalize;

   function New_Direct_Plotter (Param : Plotter_Parameter
                                  := No_Plotter_Parameter)
     return Plotter is
   begin
      return Create_Plotter (DriverName, "", Param);
   end New_Direct_Plotter;

   function New_File_Plotter (Filename : String := "";
                              Param    : Plotter_Parameter
                                := No_Plotter_Parameter)
     return Plotter is
   begin
      return Create_Plotter (DriverName, Filename, Param);
   end New_File_Plotter;

end GNU.plotutil.Device;
