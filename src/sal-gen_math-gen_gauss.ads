--  Abstract:
--
--  Generic Math Gaussian Random Number Generator Package.
--  The gauss function generates a normally distributed random
--  number with zero mean and unit variance.
--
--  Reference : http://www.mathworks.com/moler/random.pdf
--
--  Copyright (C) 2001, 2002, 2003 Steve Messiora.  All Rights Reserved.
--
--  This library is free software; you can redistribute it and/or
--  modify it under terms of the GNU General Public License as
--  published by the Free Software Foundation; either version 2, or
--  (at your option) any later version. This library is distributed in
--  the hope that it will be useful, but WITHOUT ANY WARRANTY; without
--  even the implied warranty of MERCHANTABILITY or FITNESS FOR A
--  PARTICULAR PURPOSE. See the GNU General Public License for more
--  details. You should have received a copy of the GNU General Public
--  License distributed with this program; see file COPYING. If not,
--  write to the Free Software Foundation, 59 Temple Place - Suite
--  330, Boston, MA 02111-1307, USA.
--
--  As a special exception, if other files instantiate generics from
--  this unit, or you link this unit with other files to produce an
--  executable, this unit does not by itself cause the resulting
--  executable to be covered by the GNU General Public License. This
--  exception does not however invalidate any other reasons why the
--  executable file might be covered by the GNU Public License.
--
with Ada.Numerics.Float_Random;
with Ada.Numerics.Generic_Elementary_Functions;
generic
   with package Elementary is new Ada.Numerics.Generic_Elementary_Functions (
      Real_Type);
package Sal.Gen_Math.Gen_Gauss is

   subtype Generator is Ada.Numerics.Float_Random.Generator;

   function Gauss
     (Gen     : in Generator;
      Std_Dev : in Real_Type;
      Enabled : in Boolean)
      return    Real_Type;
   -- Add description

   procedure Initialize (Gen : in out Generator; Seed : in Integer);

end Sal.Gen_Math.Gen_Gauss;
