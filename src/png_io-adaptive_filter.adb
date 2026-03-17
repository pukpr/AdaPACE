---------------------------------------------------------------------
---------------------------------------------------------------------
-- PNG_IO -- Ada95 Portable Network Graphics Input/Output Package  --
--                                                                 --
-- Copyright (©) 1999 Dr Stephen J. Sangwine (S.Sangwine@IEEE.org) --
--                                                                 --
-- This software was created by Stephen J. Sangwine. He hereby     --
-- asserts his Moral Right to be identified as author of this      --
-- software.                                                       --
---------------------------------------------------------------------
---------------------------------------------------------------------
-- PNG_IO is free software; you can redistribute it and/or modify  --
-- it under the terms of the GNU General Public License as         --
-- published by the Free Software Foundation; either version 2 of  --
-- the License, or (at your option) any later version.             --
--                                                                 --
-- PNG_IO is distributed in the hope that it will be useful, but   --
-- WITHOUT ANY WARRANTY; without even the implied warranty of      --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the    --
-- GNU General Public License for more details.                    --
--                                                                 --
-- You should have received a copy of the GNU General Public       --
-- License along with this software (in the file gpl.txt); if not, --
-- write to the Free Software Foundation, Inc., 59 Temple Place,   --
-- Suite 330, Boston, MA 02111-1307 USA                            --
--                                                                 --
-- PNG_IO was written by Steve Sangwine at The University of       --
-- Reading, United Kingdom.                                        --
--                                                                 --
-- The University of Reading has agreed to the public release of   --
-- this software under the GNU General Public Licence. Enquiries   --
-- concerning commercial licensing of the software should be       --
-- directed to Research and Enterprise Services, The University    --
-- of Reading, Whiteknights, PO Box 217, Reading RG6 6AH, United   --
-- Kingdom.                                                        --
-- WWW: http://www.rdg.ac.uk/RES/    Email: RES@Reading.ac.uk      --
-- Tel: +44 118 931 8628             Fax: +44 118 931 8979.        --
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Date:  26 August 1999                                           --
-- Edited: 7   July 2004 to use Stream_Element_Array.              --
---------------------------------------------------------------------
---------------------------------------------------------------------
-- A function to perform adaptive filtering of the scanlines in an --
-- image. The two scanlines supplied must be the same length and   --
-- contain the raw byte sequence of an image scanline and the      --
-- previous scanline. (For the first scanline in an image or pass  --
-- of an interlaced image, Previous MUST be supplied as an array   --
-- of zero bytes.) The returned result is one byte longer and      --
-- consists of the filter type byte followed by the filtered       --
-- scanline ready for input to Zlib compression.                   --
---------------------------------------------------------------------
---------------------------------------------------------------------

separate (PNG_IO)
function Adaptive_Filter
  (Raw, Prior : Stream_Element_Array)
   return       Stream_Element_Array
is
   S, U, A, P : Stream_Element_Array (1 .. Raw'Last); -- Sub, Up, Average,
                                                      --Paeth.
begin
   pragma Assert (Raw'Length = Prior'Length);
   for I in  Raw'Range loop -- Compute the four non-trivial filters.
      if I <= Bpp then
         S (I) := Raw (I);
         A (I) := Raw (I) - Mean (0, Prior (I));
         P (I) := Raw (I) - PaethPredictor (0, Prior (I), 0);
      else
         S (I) := Raw (I) - Raw (I - Bpp);
         A (I) := Raw (I) - Mean (Raw (I - Bpp), Prior (I));
         P (I) := Raw (I) -
                  PaethPredictor (Raw (I - Bpp), Prior (I), Prior (I - Bpp));
      end if;
      U (I) := Raw (I) - Prior (I);
   end loop;
   -- Now decide which filter is best for the scanline Raw. The method
   -- employed here is the heuristic suggested in Section 9.6 of the
   -- PNG Specification: compute the sum of absolute values taking the
   -- values as signed differences.
   declare
      function Sigma (X : Stream_Element_Array) return Natural is
         R : Natural := 0;
      begin
         for I in  X'First .. X'Last - 1 loop
            if (X (I) and 2#1000_0000#) /= 0 then
               -- Value is 'negative'
               R := R + (256 - Natural (X (I)));
            else
               R := R + Natural (X (I));
            end if;
         end loop;
         return R;
      end Sigma;
      SN : constant Natural := Sigma (Raw);
      SS : constant Natural := Sigma (S);
      SU : constant Natural := Sigma (U);
      SA : constant Natural := Sigma (A);
      SP : constant Natural := Sigma (P);
   begin
      if SN <= SS and then SN <= SU and then SN <= SA and then SN <= SP then
         return None & Raw;
      elsif SS <= SU and then SS <= SA and then SS <= SP then
         return Sub & S;
      elsif SU <= SA and then SU <= SP then
         return Up & U;
      elsif SA <= SP then
         return Average & A;
      else
         return Paeth & P;
      end if;
   end;
end Adaptive_Filter;
