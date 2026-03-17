-------------------------------------------------------------------------------
--                                                                           --
--                           GNAT libplot binding                            --
--                                                                           --
--                           GNU.plotutil_Motif                              --
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
package GNU.plotutil.Motif is
   --
   pragma Linker_Options ("-L/usr/X11R6/lib");
   pragma Linker_Options ("-lXm");
   pragma Linker_Options ("-lXp");
   pragma Linker_Options ("-lXt");
   pragma Linker_Options ("-lXext");
   pragma Linker_Options ("-lX11");
   pragma Linker_Options ("-lm");
   --  The required Linker_Options may be different on your system(s).
   --  Please adapt it to your needs.
   --  This is for a typical Linux with XFree86 and Motif
   --
end GNU.plotutil.Motif;
