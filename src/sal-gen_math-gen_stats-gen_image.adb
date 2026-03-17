--  Abstract :
--
--  See spec.
--
--  Copyright (C) 2003 Stephen Leake.  All Rights Reserved.
--
--  SAL is free software; you can redistribute it and/or modify it
--  under terms of the GNU General Public License as published by the
--  Free Software Foundation; either version 2, or (at your option) any
--  later version. SAL is distributed in the hope that it will be
--  useful, but WITHOUT ANY WARRANTY; without even the implied warranty
--  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
--  General Public License for more details. You should have received a
--  copy of the GNU General Public License distributed with SAL; see
--  file COPYING. If not, write to the Free Software Foundation, 59
--  Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--
--  As a special exception, if other files instantiate generics from
--  SAL, or you link SAL object files with other files to produce
--  an executable, that does not by itself cause the resulting
--  executable to be covered by the GNU General Public License. This
--  exception does not however invalidate any other reasons why the
--  executable file might be covered by the GNU Public License.

with Ada.IO_Exceptions;
package body Sal.Gen_Math.Gen_Stats.Gen_Image is

   function Image
     (Item      : in Stats_Type;
      Mean_Fore : in Ada.Text_IO.Field := Default_Mean_Fore;
      Mean_Aft  : in Ada.Text_IO.Field := Default_Mean_Aft;
      Mean_Exp  : in Ada.Text_IO.Field := Default_Mean_Exp;
      Sd_Fore   : in Ada.Text_IO.Field := Default_Sd_Fore;
      Sd_Aft    : in Ada.Text_IO.Field := Default_Sd_Aft;
      Sd_Exp    : in Ada.Text_IO.Field := Default_Sd_Exp)
      return      String
   is
      use Real_Io;
      --  Overhead for `( +- , , )', and for '-.E' in numbers. Except
      --  standard deviation can't be negative.
      Mean_Width : Natural          := 3 + Mean_Fore + Mean_Aft + Mean_Exp;
      Sd_Width   : Natural          := 2 + Sd_Fore + Sd_Aft + Sd_Exp;
      Max_Width  : constant Natural := 10 + 3 * Mean_Width + Sd_Width;
      Result     : String (1 .. Max_Width);
      First      : Natural;
      Last       : Natural          := Result'First;

      procedure Put
        (Item     : in Real_Type;
         Width    : in Natural;
         Aft, Exp : in Ada.Text_IO.Field)
      is
      begin
         First := Last + 1;
         Last  := Last + Width;
         Put (Result (First .. Last), Item, Aft, Exp);
      exception
         when Ada.IO_Exceptions.Layout_Error =>
            Result (First .. Last) := (others => '*');
      end Put;

   begin
      if Mean_Exp = 0 then
         Mean_Width := Mean_Width - 1;
      end if;
      if Sd_Exp = 0 then
         Sd_Width := Sd_Width - 1;
      end if;

      Result (Last) := '(';

      Put (Mean (Item), Mean_Width, Mean_Aft, Mean_Exp);

      First                  := Last + 1;
      Last                   := Last + 4;
      Result (First .. Last) := " +- ";

      Put (Standard_Deviation (Item), Sd_Width, Sd_Aft, Sd_Exp);

      First                  := Last + 1;
      Last                   := Last + 2;
      Result (First .. Last) := ", ";

      Put (Min (Item), Mean_Width, Mean_Aft, Mean_Exp);

      First                  := Last + 1;
      Last                   := Last + 2;
      Result (First .. Last) := ", ";

      Put (Max (Item), Mean_Width, Mean_Aft, Mean_Exp);

      Last          := Last + 1;
      Result (Last) := ')';

      return Result (1 .. Last);
   end Image;

end Sal.Gen_Math.Gen_Stats.Gen_Image;
