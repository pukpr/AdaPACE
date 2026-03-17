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
-- Edit:  13   July 2000 to use heap-allocated buffers rather than --
--                       stack arrays, and implement a changed     --
--                       interface to Write_IDAT_Chunk accordingly.--
--         1 November 2000 to add Ancillary parameter and code.    --
--         4     June 2002 to add ability to handle interlacing.   --
--         7     July 2004 to make changes consequent on use of    --
--                         Zlib Ada.                               --
---------------------------------------------------------------------
---------------------------------------------------------------------

separate (PNG_IO)
procedure Write_PNG_Type_0
  (Filename  : in String;
   I         : in Image_Handle;
   X, Y      : in Dimension;
   Bit_Depth : in Depth      := Eight;
   Interlace : in Boolean    := False;
   Ancillary : in Chunk_List := Null_Chunk_List)
is
   F : File_Type;

   Table : constant array (Depth) of Stream_Element_Offset := (1, 1, 1, 1, 2);
   Bpp   : Stream_Element_Offset renames Table (Bit_Depth);
   function Filter is new Adaptive_Filter (Bpp);

   UDB : Buffer_Pointer        :=
      new Buffer (1 .. Image_Size (Zero, Bit_Depth, X, Y, Interlace));
   UDP : Stream_Element_Offset := UDB'First;

begin
   Start_File (Filename, X, Y, Zero, Bit_Depth, Interlace, F);

   -- Write any ancillary chunks supplied that have to be positioned before the
   -- IDAT chunk(s).

   Write_Ancillary_Chunks (F, Ancillary, Before_PLTE);   -- Probably a do
                                                         --nothing.
   Write_Ancillary_Chunks (F, Ancillary, Before_IDAT);

   declare

   -- The following procedure writes the image or a sub-image to the
   --uncompressed
   -- data buffer. The Pass parameter default value is used when writing a
   --whole
   -- (non-interlaced) image. In this case, it is not used in the procedure.
   --The
   -- procedure cannot be called for a zero size sub-image, since its X and Y
   -- parameters are of type Dimension, for which the lower bound is 1.

      procedure Write_Image (X, Y : in Dimension; Pass : Pass_Number := 1) is
         Bps               : constant Stream_Element_Count   :=
            Bytes_per_Scanline (Zero, Bit_Depth, X);
         Scanline          : Stream_Element_Array (1 .. Bps);
         Previous_Scanline : Stream_Element_Array (1 .. Bps) := (others => 0);

         function Map (C : Coordinate) return Coordinate is
         begin
            if Interlace then
               return Image_Col (C, Pass);
            else
               return C;
            end if;
         end Map;
         pragma Inline (Map);

      begin
         pragma Assert (Interlace or Pass = 1);
         for Row in  0 .. Coordinate (Y - 1) loop
            declare
               R : Coordinate := Row;
            begin
               if Interlace then             -- If the image is interlaced we
                                             --must map from
                  R := Image_Row (Row, Pass);   -- sub-image to whole image
                                                --coordinates.
               end if;
               case Bit_Depth is
                  when One | Two | Four =>
                     declare
                        Offset : constant array (Depth_1_2_4) of Coordinate :=
                          (7,
                           3,
                           1);
                        Shift  : constant array (Depth_1_2_4) of Positive   :=
                          (1,
                           2,
                           4);
                        Mask   : constant array (Depth_1_2_4) of Unsigned_8 :=
                          (2#1#,
                           2#11#,
                           2#1111#);
                        Ppb    : constant array (Depth_1_2_4) of Coordinate :=
                          (8,
                           4,
                           2);
                     begin
                        for P in  Scanline'Range loop
                           declare
                              B : Unsigned_8 := 0;
                           begin
                              for O in  0 .. Offset (Bit_Depth) loop
                                 declare
                                 -- We have to be careful about the last few
                                 --bits in the last byte
                                 -- of the scanline where the number of pixels
                                 --does not fill all
                                 -- the bits in the last byte. We handle this
                                 --with the Min attribute
                                 -- and thus replicate the last pixel to fill
                                 --the spare bits. The
                                 -- PNG Specification, Section 2.3 says the
                                 --content of the spare bits
                                 -- is unspecified, so we are OK to replicate.

                                    Col : constant Coordinate :=
                                       Coordinate'Min
                                         (Coordinate (X - 1),
                                          Coordinate (P - 1) *
                                          Ppb (Bit_Depth) +
                                          O);
                                 begin
                                    B := Shift_Left (B, Shift (Bit_Depth)) or
                                         (Unsigned_8 (Grey_Sample
                                                         (I,
                                                          R,
                                                          Map (Col))) and
                                          Mask (Bit_Depth));
                                 end;
                              end loop;
                              Scanline (P) := Stream_Element (B);
                           end;
                        end loop;
                     end;
                  when Eight =>
                     for P in  Scanline'Range loop
                        Scanline (P) :=
                          Stream_Element (Grey_Sample
                                             (I,
                                              R,
                                              Map (Coordinate (P - 1))));
                     end loop;
                  when Sixteen =>
                     for Col in  0 .. Coordinate (X - 1) loop
                        declare
                           P : constant Stream_Element_Offset :=
                              1 + Stream_Element_Offset (Col) * Bpp;
                        begin
                           Scanline (P .. P + 1) :=
                              To_Buffer_2
                                (Unsigned_16 (Grey_Sample (I, R, Map (Col))));
                        end;
                     end loop;
               end case;
            end;

            -- Following the recommendations of Section 9.6 in the PNG
            --Specification,
            -- the scanlines are not filtered for bit depths less than 8. We
            --simply
            -- have to prepend a byte (None) to indicate no filtering and we
            --don't
            -- update Previous_Scanline because we are not using it. (Avoiding
            --its
            -- declaration above is too much trouble!)

            if Bit_Depth in Depth_1_2_4 then
               Append_to_Buffer (UDB, UDP, None & Scanline);
            else
               Append_to_Buffer
                 (UDB,
                  UDP,
                  Filter (Scanline, Previous_Scanline));
               Previous_Scanline := Scanline;
            end if;
         end loop;
      end Write_Image;

   begin

      if Interlace then
         for P in  Pass_Number loop
            declare
               W : constant Natural := Sub_Image_Width (X, P);
               H : constant Natural := Sub_Image_Height (Y, P);
            begin
               if W > 0 and H > 0 then
                  Write_Image (W, H, P);
               end if;
            end;
         end loop;
      else
         Write_Image (X, Y);
      end if;

   end;

   Write_IDAT_Chunk (F, UDB);

   -- Write any ancillary chunks supplied that may be positioned anywhere.
   Write_Ancillary_Chunks (F, Ancillary, Anywhere);

   Finish_File (F);
end Write_PNG_Type_0;
