with Ada.Unchecked_Deallocation;
with Text_IO; -- For the default callback

package body Gnu.Jif is

   Eof : constant := -1;

   package Mtables is -- Cheap math tables for doing fast trig (Cosine/Sine)
      Costscale : constant := 1024;
      Sintscale : constant := 1024;

      Cost : constant array (1 .. 360) of J_Int :=
        (1024,
         1023,
         1023,
         1022,
         1021,
         1020,
         1018,
         1016,
         1014,
         1011,
         1008,
         1005,
         1001,
         997,
         993,
         989,
         984,
         979,
         973,
         968,
         962,
         955,
         949,
         942,
         935,
         928,
         920,
         912,
         904,
         895,
         886,
         877,
         868,
         858,
         848,
         838,
         828,
         817,
         806,
         795,
         784,
         772,
         760,
         748,
         736,
         724,
         711,
         698,
         685,
         671,
         658,
         644,
         630,
         616,
         601,
         587,
         572,
         557,
         542,
         527,
         512,
         496,
         480,
         464,
         448,
         432,
         416,
         400,
         383,
         366,
         350,
         333,
         316,
         299,
         282,
         265,
         247,
         230,
         212,
         195,
         177,
         160,
         142,
         124,
         107,
         89,
         71,
         53,
         35,
         17,
         0,
         -17,
         -35,
         -53,
         -71,
         -89,
         -107,
         -124,
         -142,
         -160,
         -177,
         -195,
         -212,
         -230,
         -247,
         -265,
         -282,
         -299,
         -316,
         -333,
         -350,
         -366,
         -383,
         -400,
         -416,
         -432,
         -448,
         -464,
         -480,
         -496,
         -512,
         -527,
         -542,
         -557,
         -572,
         -587,
         -601,
         -616,
         -630,
         -644,
         -658,
         -671,
         -685,
         -698,
         -711,
         -724,
         -736,
         -748,
         -760,
         -772,
         -784,
         -795,
         -806,
         -817,
         -828,
         -838,
         -848,
         -858,
         -868,
         -877,
         -886,
         -895,
         -904,
         -912,
         -920,
         -928,
         -935,
         -942,
         -949,
         -955,
         -962,
         -968,
         -973,
         -979,
         -984,
         -989,
         -993,
         -997,
         -1001,
         -1005,
         -1008,
         -1011,
         -1014,
         -1016,
         -1018,
         -1020,
         -1021,
         -1022,
         -1023,
         -1023,
         -1024,
         -1023,
         -1023,
         -1022,
         -1021,
         -1020,
         -1018,
         -1016,
         -1014,
         -1011,
         -1008,
         -1005,
         -1001,
         -997,
         -993,
         -989,
         -984,
         -979,
         -973,
         -968,
         -962,
         -955,
         -949,
         -942,
         -935,
         -928,
         -920,
         -912,
         -904,
         -895,
         -886,
         -877,
         -868,
         -858,
         -848,
         -838,
         -828,
         -817,
         -806,
         -795,
         -784,
         -772,
         -760,
         -748,
         -736,
         -724,
         -711,
         -698,
         -685,
         -671,
         -658,
         -644,
         -630,
         -616,
         -601,
         -587,
         -572,
         -557,
         -542,
         -527,
         -512,
         -496,
         -480,
         -464,
         -448,
         -432,
         -416,
         -400,
         -383,
         -366,
         -350,
         -333,
         -316,
         -299,
         -282,
         -265,
         -247,
         -230,
         -212,
         -195,
         -177,
         -160,
         -142,
         -124,
         -107,
         -89,
         -71,
         -53,
         -35,
         -17,
         0,
         17,
         35,
         53,
         71,
         89,
         107,
         124,
         142,
         160,
         177,
         195,
         212,
         230,
         247,
         265,
         282,
         299,
         316,
         333,
         350,
         366,
         383,
         400,
         416,
         432,
         448,
         464,
         480,
         496,
         512,
         527,
         542,
         557,
         572,
         587,
         601,
         616,
         630,
         644,
         658,
         671,
         685,
         698,
         711,
         724,
         736,
         748,
         760,
         772,
         784,
         795,
         806,
         817,
         828,
         838,
         848,
         858,
         868,
         877,
         886,
         895,
         904,
         912,
         920,
         928,
         935,
         942,
         949,
         955,
         962,
         968,
         973,
         979,
         984,
         989,
         993,
         997,
         1001,
         1005,
         1008,
         1011,
         1014,
         1016,
         1018,
         1020,
         1021,
         1022,
         1023,
         1023);
      Sint : constant array (1 .. 360) of J_Int :=
        (0,
         17,
         35,
         53,
         71,
         89,
         107,
         124,
         142,
         160,
         177,
         195,
         212,
         230,
         247,
         265,
         282,
         299,
         316,
         333,
         350,
         366,
         383,
         400,
         416,
         432,
         448,
         464,
         480,
         496,
         512,
         527,
         542,
         557,
         572,
         587,
         601,
         616,
         630,
         644,
         658,
         671,
         685,
         698,
         711,
         724,
         736,
         748,
         760,
         772,
         784,
         795,
         806,
         817,
         828,
         838,
         848,
         858,
         868,
         877,
         886,
         895,
         904,
         912,
         920,
         928,
         935,
         942,
         949,
         955,
         962,
         968,
         973,
         979,
         984,
         989,
         993,
         997,
         1001,
         1005,
         1008,
         1011,
         1014,
         1016,
         1018,
         1020,
         1021,
         1022,
         1023,
         1023,
         1024,
         1023,
         1023,
         1022,
         1021,
         1020,
         1018,
         1016,
         1014,
         1011,
         1008,
         1005,
         1001,
         997,
         993,
         989,
         984,
         979,
         973,
         968,
         962,
         955,
         949,
         942,
         935,
         928,
         920,
         912,
         904,
         895,
         886,
         877,
         868,
         858,
         848,
         838,
         828,
         817,
         806,
         795,
         784,
         772,
         760,
         748,
         736,
         724,
         711,
         698,
         685,
         671,
         658,
         644,
         630,
         616,
         601,
         587,
         572,
         557,
         542,
         527,
         512,
         496,
         480,
         464,
         448,
         432,
         416,
         400,
         383,
         366,
         350,
         333,
         316,
         299,
         282,
         265,
         247,
         230,
         212,
         195,
         177,
         160,
         142,
         124,
         107,
         89,
         71,
         53,
         35,
         17,
         0,
         -17,
         -35,
         -53,
         -71,
         -89,
         -107,
         -124,
         -142,
         -160,
         -177,
         -195,
         -212,
         -230,
         -247,
         -265,
         -282,
         -299,
         -316,
         -333,
         -350,
         -366,
         -383,
         -400,
         -416,
         -432,
         -448,
         -464,
         -480,
         -496,
         -512,
         -527,
         -542,
         -557,
         -572,
         -587,
         -601,
         -616,
         -630,
         -644,
         -658,
         -671,
         -685,
         -698,
         -711,
         -724,
         -736,
         -748,
         -760,
         -772,
         -784,
         -795,
         -806,
         -817,
         -828,
         -838,
         -848,
         -858,
         -868,
         -877,
         -886,
         -895,
         -904,
         -912,
         -920,
         -928,
         -935,
         -942,
         -949,
         -955,
         -962,
         -968,
         -973,
         -979,
         -984,
         -989,
         -993,
         -997,
         -1001,
         -1005,
         -1008,
         -1011,
         -1014,
         -1016,
         -1018,
         -1020,
         -1021,
         -1022,
         -1023,
         -1023,
         -1024,
         -1023,
         -1023,
         -1022,
         -1021,
         -1020,
         -1018,
         -1016,
         -1014,
         -1011,
         -1008,
         -1005,
         -1001,
         -997,
         -993,
         -989,
         -984,
         -979,
         -973,
         -968,
         -962,
         -955,
         -949,
         -942,
         -935,
         -928,
         -920,
         -912,
         -904,
         -895,
         -886,
         -877,
         -868,
         -858,
         -848,
         -838,
         -828,
         -817,
         -806,
         -795,
         -784,
         -772,
         -760,
         -748,
         -736,
         -724,
         -711,
         -698,
         -685,
         -671,
         -658,
         -644,
         -630,
         -616,
         -601,
         -587,
         -572,
         -557,
         -542,
         -527,
         -512,
         -496,
         -480,
         -464,
         -448,
         -432,
         -416,
         -400,
         -383,
         -366,
         -350,
         -333,
         -316,
         -299,
         -282,
         -265,
         -247,
         -230,
         -212,
         -195,
         -177,
         -160,
         -142,
         -124,
         -107,
         -89,
         -71,
         -53,
         -35,
         -17);
   end Mtables;

   Image_Code_87a : constant String := "GIF87a";
   Image_Code_89a : constant String := "GIF89a";
   Gifbits        : constant := 12;

   procedure Free is new Ada.Unchecked_Deallocation (
      Image_Data,
      Image_Access);
   procedure Free is new Ada.Unchecked_Deallocation (
      Color_Array,
      Color_Style);

   -------------------------------------------------------------------

   --    function Image_Create (Sx : J_Int; Sy : J_Int) return Image is
   --        Img : Image (Sx, Sy);
   --    begin
   --       return Img;
   --    end Image_Create;

   procedure Image_Destroy (Im : in out Image) is
   begin
      Free (Im.This.Style);
      Free (Im.This);
   end Image_Destroy;

   function Image_Get_Pixel (Im : Image; P : Point) return Color is
   begin
      if Image_Bounds_Safe (Im, P) then
         return Color (Im.This.Pixels (P.X, P.Y));
      else
         return 0;
      end if;
   end Image_Get_Pixel;

   function Image_Get_Pixel (Im : Image_Access; P : Point) return Color is
   begin
      if P.Y > 0 and P.Y <= Im.Sy and P.X > 0 and P.X <= Im.Sx then
         --        if Image_Bounds_Safe (Im.all, P) then
         return Color (Im.Pixels (P.X, P.Y));
      else
         return 0;
      end if;
   end Image_Get_Pixel;

   procedure Image_Brush_Apply (Im : Image; P : Point);

   procedure Image_Tile_Apply (Im : Image; P : Point);

   procedure Image_Set_Pixel (Im : Image; P : Point; Col : Color) is
      C : Color;
   begin
      case Col is
         when Styled =>
            if Im.This.Style = null then
               -- Refuse to draw if no style is set.
               return;
            end if;
            C                 := Im.This.Style (Im.This.Style_Pos);
            Im.This.Style_Pos := Im.This.Style_Pos + 1;
            if C /= Transparent then
               Image_Set_Pixel (Im, P, C);
            end if;
            Im.This.Style_Pos := Im.This.Style_Pos rem Im.This.Style_Length;
         when Styled_Brushed =>
            if Im.This.Style = null then
               -- Refuse to draw if no style is set.
               return;
            end if;
            C                 := Im.This.Style (Im.This.Style_Pos);
            Im.This.Style_Pos := Im.This.Style_Pos + 1;
            if C /= Transparent and then C /= 0 then
               Image_Set_Pixel (Im, P, Brushed);
            end if;
            Im.This.Style_Pos := Im.This.Style_Pos rem Im.This.Style_Length;
         when Brushed =>
            Image_Brush_Apply (Im, P);
         when Tiled =>
            Image_Tile_Apply (Im, P);
         when others =>
            if Image_Bounds_Safe (Im, P) then
               Im.This.Pixels (P.X, P.Y) := J_Byte (Col);
            end if;
      end case;
   end Image_Set_Pixel;

   procedure Image_Brush_Apply (Im : Image; P : Point) is
      Hy   : J_Int;
      Hx   : J_Int;
      X1   : J_Int;
      Y1   : J_Int;
      X2   : J_Int;
      Y2   : J_Int;
      Srcx : J_Int;
      Srcy : J_Int;
   begin
      if Im.This.Brush = null then
         return;
      end if;
      Hy   := Im.This.Brush.Sy / 2;
      Y1   := P.Y - Hy;
      Y2   := Y1 + Im.This.Brush.Sy;
      Hx   := Im.This.Brush.Sx / 2;
      X1   := P.X - Hx;
      X2   := X1 + Im.This.Brush.Sx;
      Srcy := 0;
      for Ly in  Y1 .. Y2 - 1 loop
         Srcx := 0;
         for Lx in  X1 .. X2 - 1 loop
            declare
               P_C0 : Color;
            begin
               P_C0 := Image_Get_Pixel (Im.This.Brush, (Srcx, Srcy));
               -- Allow for non-square brushes
               if P_C0 /= Im.This.Brush.Transparent then
                  Image_Set_Pixel
                    (Im,
                     (Lx, Ly),
                     Im.This.Brush_Color_Map (P_C0));
               end if;
               Srcx := Srcx + 1;
            end;
         end loop;
         Srcy := Srcy + 1;
      end loop;
   end Image_Brush_Apply;

   procedure Image_Tile_Apply (Im : Image; P : Point) is
      Srcx_C : J_Int;
      Srcy_C : J_Int;
      P_C    : Color;
   begin
      if Im.This.Tile = null then
         return;
      end if;
      Srcx_C := P.X rem Im.This.Tile.Sx;
      Srcy_C := P.Y rem Im.This.Tile.Sy;
      P_C    := Image_Get_Pixel (Im.This.Tile, (Srcx_C, Srcy_C));
      -- Allow for transparency
      if P_C /= Im.This.Tile.Transparent then
         Image_Set_Pixel (Im, P, Im.This.Tile_Color_Map (P_C));
      end if;
   end Image_Tile_Apply;

   procedure Image_Line
     (Im  : Image;
      P1  : Point;
      P2  : Point;
      Col : Color)
   is
      Dx       : J_Int;
      Dy       : J_Int;
      Incr1    : J_Int;
      Incr2    : J_Int;
      D        : J_Int;
      X        : J_Int;
      Y        : J_Int;
      Xend     : J_Int;
      Yend     : J_Int;
      Xdirflag : J_Int;
      Ydirflag : J_Int;
   begin
      Dx := abs (P2.X - P1.X);
      Dy := abs (P2.Y - P1.Y);
      if Dy <= Dx then
         D     := 2 * Dy - Dx;
         Incr1 := 2 * Dy;
         Incr2 := 2 * (Dy - Dx);
         if P1.X > P2.X then
            X        := P2.X;
            Y        := P2.Y;
            Ydirflag := -1;
            Xend     := P1.X;
         else
            X        := P1.X;
            Y        := P1.Y;
            Ydirflag := 1;
            Xend     := P2.X;
         end if;
         Image_Set_Pixel (Im, (X, Y), Col);
         if (P2.Y - P1.Y) * Ydirflag > 0 then
            while X < Xend loop
               X := X + 1;
               if D < 0 then
                  D := D + Incr1;
               else
                  Y := Y + 1;
                  D := D + Incr2;
               end if;
               Image_Set_Pixel (Im, (X, Y), Col);
            end loop;
         else
            while X < Xend loop
               X := X + 1;
               if D < 0 then
                  D := D + Incr1;
               else
                  Y := Y - 1;
                  D := D + Incr2;
               end if;
               Image_Set_Pixel (Im, (X, Y), Col);
            end loop;
         end if;
      else
         D     := 2 * Dx - Dy;
         Incr1 := 2 * Dx;
         Incr2 := 2 * (Dx - Dy);
         if P1.Y > P2.Y then
            Y        := P2.Y;
            X        := P2.X;
            Yend     := P1.Y;
            Xdirflag := -1;
         else
            Y        := P1.Y;
            X        := P1.X;
            Yend     := P2.Y;
            Xdirflag := 1;
         end if;
         Image_Set_Pixel (Im, (X, Y), Col);
         if (P2.X - P1.X) * Xdirflag > 0 then
            while Y < Yend loop
               Y := Y + 1;
               if D < 0 then
                  D := D + Incr1;
               else
                  X := X + 1;
                  D := D + Incr2;
               end if;
               Image_Set_Pixel (Im, (X, Y), Col);
            end loop;
         else
            while Y < Yend loop
               Y := Y + 1;
               if D < 0 then
                  D := D + Incr1;
               else
                  X := X - 1;
                  D := D + Incr2;
               end if;
               Image_Set_Pixel (Im, (X, Y), Col);
            end loop;
         end if;
      end if;
   end Image_Line;

   procedure Dashedset
     (Im        : Image;
      X, Y      : J_Int;
      Col       : Color;
      Onp       : in out Boolean;
      Dashstepp : in out J_Int)
   is
      Dashstep_C : J_Int;
      On_C       : Boolean;
   begin
      Dashstep_C := Dashstepp;
      On_C       := Onp;
      Dashstep_C := Dashstep_C + 1;
      if Dashstep_C = Dashsize then
         Dashstep_C := 0;
         On_C       := not On_C;
      end if;
      if On_C then
         Image_Set_Pixel (Im, (X, Y), Col);
      end if;
      Dashstepp := Dashstep_C;
      Onp       := On_C;
   end Dashedset;

   procedure Image_Dashed_Line
     (Im  : Image;
      P1  : Point;
      P2  : Point;
      Col : Color)
   is
      Dx_C       : J_Int;
      Dy_C       : J_Int;
      Incr1_C    : J_Int;
      Incr2_C    : J_Int;
      D_C        : J_Int;
      X_C        : J_Int;
      Y_C        : J_Int;
      Xend_C     : J_Int;
      Yend_C     : J_Int;
      Xdirflag_C : J_Int;
      Ydirflag_C : J_Int;
      Dashstep   : J_Int;
      On         : Boolean;
   begin
      Dashstep := 0;
      On       := True;
      Dx_C     := abs (P2.X - P1.X);
      Dy_C     := abs (P2.Y - P1.Y);
      if Dy_C <= Dx_C then
         D_C     := 2 * Dy_C - Dx_C;
         Incr1_C := 2 * Dy_C;
         Incr2_C := 2 * (Dy_C - Dx_C);
         if P1.X > P2.X then
            X_C        := P2.X;
            Y_C        := P2.Y;
            Ydirflag_C := -1;
            Xend_C     := P1.X;
         else
            X_C        := P1.X;
            Y_C        := P1.Y;
            Ydirflag_C := 1;
            Xend_C     := P2.X;
         end if;
         Dashedset (Im, X_C, Y_C, Col, On, Dashstep);

         if (P2.Y - P1.Y) * Ydirflag_C > 0 then
            while X_C < Xend_C loop
               X_C := X_C + 1;
               if D_C < 0 then
                  D_C := D_C + Incr1_C;
               else
                  Y_C := Y_C + 1;
                  D_C := D_C + Incr2_C;
               end if;
               Dashedset (Im, X_C, Y_C, Col, On, Dashstep);
            end loop;
         else
            while X_C < Xend_C loop
               X_C := X_C + 1;
               if D_C < 0 then
                  D_C := D_C + Incr1_C;
               else
                  Y_C := Y_C - 1;
                  D_C := D_C + Incr2_C;
               end if;
               Dashedset (Im, X_C, Y_C, Col, On, Dashstep);
            end loop;
         end if;
      else
         D_C     := 2 * Dx_C - Dy_C;
         Incr1_C := 2 * Dx_C;
         Incr2_C := 2 * (Dx_C - Dy_C);
         if P1.Y > P2.Y then
            Y_C        := P2.Y;
            X_C        := P2.X;
            Yend_C     := P1.Y;
            Xdirflag_C := -1;
         else
            Y_C        := P1.Y;
            X_C        := P1.X;
            Yend_C     := P2.Y;
            Xdirflag_C := 1;
         end if;
         Dashedset (Im, X_C, Y_C, Col, On, Dashstep);

         if (P2.X - P1.X) * Xdirflag_C > 0 then
            while Y_C < Yend_C loop
               Y_C := Y_C + 1;
               if D_C < 0 then
                  D_C := D_C + Incr1_C;
               else
                  X_C := X_C + 1;
                  D_C := D_C + Incr2_C;
               end if;
               Dashedset (Im, X_C, Y_C, Col, On, Dashstep);
            end loop;
         else
            while Y_C < Yend_C loop
               Y_C := Y_C + 1;
               if D_C < 0 then
                  D_C := D_C + Incr1_C;
               else
                  X_C := X_C - 1;
                  D_C := D_C + Incr2_C;
               end if;
               Dashedset (Im, X_C, Y_C, Col, On, Dashstep);
            end loop;
         end if;
      end if;
   end Image_Dashed_Line;

   procedure Image_Rectangle
     (Im  : Image;
      P1  : Point;
      P2  : Point;
      Col : Color)
   is
   begin
      Image_Line (Im, P1, (P2.X, P1.Y), Col);
      Image_Line (Im, (P1.X, P2.Y), P2, Col);
      Image_Line (Im, P1, (P1.X, P2.Y), Col);
      Image_Line (Im, (P2.X, P1.Y), P2, Col);
   end Image_Rectangle;

   procedure Image_Filled_Rectangle
     (Im  : Image;
      P1  : Point;
      P2  : Point;
      Col : Color)
   is
   begin
      for Y in  P1.Y .. P2.Y loop
         for X in  P1.X .. P2.X loop
            Image_Set_Pixel (Im, (X, Y), Col);
         end loop;
      end loop;
   end Image_Filled_Rectangle;

   function Image_Bounds_Safe (Im : Image; P : Point) return Boolean is
   begin
      return P.Y > 0 and P.Y <= Im.This.Sy and P.X > 0 and P.X <= Im.This.Sx;
   end Image_Bounds_Safe;

   procedure Image_Char
     (Im  : Image;
      F   : Font;
      P   : Point;
      Ch  : Character;
      Col : Color)
   is
      Cx    : J_Int;
      Cy    : J_Int;
      Fline : J_Int;
   begin
      Cx := 0;
      Cy := 0;
      if Character'Pos (Ch) < F.Offset
        or else Character'Pos (Ch) >= F.Offset + F.Nchars
      then
         return;
      end if;
      Fline := (Character'Pos (Ch) - F.Offset) * F.Height * F.Width;
      for Py in  P.Y .. P.Y + F.Height - 1 loop
         for Px in  P.X .. P.X + F.Width - 1 loop
            if F.Data (Fline + Cy * F.Width + Cx) /= ASCII.NUL then
               Image_Set_Pixel (Im, (Px, Py), Col);
            end if;
            Cx := Cx + 1;
         end loop;
         Cx := 0;
         Cy := Cy + 1;
      end loop;
   end Image_Char;

   procedure Image_Char_Up
     (Im  : Image;
      F   : Font;
      P   : Point;
      Ch  : Character;
      Col : Color)
   is
      Cx_C    : J_Int;
      Cy_C    : J_Int;
      Fline_C : J_Int;
   begin
      Cx_C := 0;
      Cy_C := 0;
      if Character'Pos (Ch) < F.Offset
        or else Character'Pos (Ch) >= F.Offset + F.Nchars
      then
         return;
      end if;
      Fline_C := (Character'Pos (Ch) - F.Offset) * F.Height * F.Width;
      for Py_C in reverse  P.Y - F.Width + 1 .. P.Y loop
         for Px_C in  P.Y .. P.Y + F.Height - 1 loop
            if F.Data (Fline_C + Cy_C * F.Width + Cx_C) /= ASCII.NUL then
               Image_Set_Pixel (Im, (Px_C, Py_C), Col);
            end if;
            Cy_C := Cy_C + 1;
         end loop;
         Cy_C := 0;
         Cx_C := Cx_C + 1;
      end loop;
   end Image_Char_Up;

   procedure Image_String
     (Im  : Image;
      F   : Font;
      P   : Point;
      S   : String;
      Col : Color)
   is
      Pos : J_Int := P.X;
   begin
      for I in  S'Range loop
         Image_Char (Im, F, (Pos, P.Y), S (I), Col);
         Pos := Pos + F.Width;
      end loop;
   end Image_String;

   procedure Image_String_Up
     (Im  : Image;
      F   : Font;
      P   : Point;
      S   : String;
      Col : Color)
   is
      Pos : J_Int := P.X;
   begin
      for I in  S'Range loop
         Image_Char_Up (Im, F, P, S (I), Col);
         Pos := Pos - F.Width;
      end loop;
   end Image_String_Up;

   procedure Image_Polygon (Im : Image; P : Points; Col : Color) is
      Lx : J_Int;
      Ly : J_Int;
   begin
      if P'Length = 0 then
         return;
      end if;
      Lx := P (P'First).X;
      Ly := P (P'First).Y;
      Image_Line (Im, (Lx, Ly), (P (P'Last).X, P (P'Last).Y), Col);
      for I in  2 .. P'Last loop
         Image_Line (Im, (Lx, Ly), (P (I).X, P (I).Y), Col);
         Lx := P (I).X;
         Ly := P (I).Y;
      end loop;
   end Image_Polygon;

   procedure Image_Filled_Polygon (Im : Image; P : Points; Col : Color) is
      Iterator     : J_Int;
      Y1           : J_Int;
      Y2           : J_Int;
      Ints         : J_Int;
      N            : J_Int := P'Length;
      Im_Poly_Ints : array (1 .. N + 1) of J_Int;

      --   procedure Sort_Poly_Ints is
      --      Switched : Boolean;
      --      Temp : J_Int;
      --   begin
      --      loop
      --              Switched := False;
      --              for J in 1 .. Ints loop
      --            if Im_Poly_Ints(J + 1) < Im_Poly_Ints(J) then
      --               Temp := Im_Poly_Ints(J);
      --               Im_Poly_Ints(J) := Im_Poly_Ints(J+1);
      --               Im_Poly_Ints (J+1) := Temp;
      --               Switched := True;
      --            end if;
      --              end loop;
      --              exit when not Switched;
      --      end loop;
      --   end Sort_Poly_Ints;
   begin
      if N = 0 then
         return;
      end if;
      Y1 := P (P'First).Y;
      Y2 := P (P'First).Y;
      for I in  2 .. N loop
         if P (I).Y < Y1 then
            Y1 := P (I).Y;
         end if;
         if P (I).Y > Y2 then
            Y2 := P (I).Y;
         end if;
      end loop;
      for Y in  Y1 .. Y2 - 1 loop
         declare
            Interlast  : J_Int := 0;
            Dirlast    : J_Int := 0;
            Interfirst : J_Int := 1;
         begin
            Ints := 1;
            for I in  1 .. N + 1 loop
               declare
                  X1       : J_Int;
                  X2       : J_Int;
                  Dir      : J_Int;
                  Ind1     : J_Int;
                  Ind2     : J_Int;
                  Lastind1 : J_Int := 1;
               begin
                  -- Lastind1 := 1;
                  if I = N + 1 or I = 1 then
                     Ind1 := N;
                     Ind2 := 1;
                  else
                     Ind1 := I - 1;
                     Ind2 := I;
                  end if;
                  Y1 := P (Ind1).Y;
                  Y2 := P (Ind2).Y;
                  if Y1 < Y2 then
                     Y1  := P (Ind1).Y;
                     Y2  := P (Ind2).Y;
                     X1  := P (Ind1).X;
                     X2  := P (Ind2).X;
                     Dir := -1;
                  elsif Y1 > Y2 then
                     Y2  := P (Ind1).Y;
                     Y1  := P (Ind2).Y;
                     X2  := P (Ind1).X;
                     X1  := P (Ind2).X;
                     Dir := 1;
                  else
                     -- Horizontal; just draw it
                     Image_Line (Im, (P (Ind1).X, Y1), (P (Ind2).X, Y1), Col);
                     goto Continue_Loop;
                  end if;
                  if Y >= Y1 and Y <= Y2 then

                     declare
                        Inter : J_Int :=
                           (Y - Y1) * (X2 - X1) / (Y2 - Y1) + X1;
                     begin
                        -- Only count intersections once
                        --      except at maxima and minima. Also,
                        --      if two consecutive intersections are
                        --      endpoints of the same horizontal line
                        --      that is not at a maxima or minima,
                        --      discard the leftmost of the two.
                        if Interfirst = 0 then
                           if P (Ind1).Y = P (Lastind1).Y and
                              P (Ind1).X /= P (Lastind1).X
                           then
                              if Dir = Dirlast then
                                 if Inter > Interlast then
                                    -- Replace the old one
                                    Im_Poly_Ints (Ints) := Inter;
                                 else
                                    -- Discard this one
                                    null;
                                 end if;
                                 goto Continue_Loop;
                              end if;
                           end if;
                           if Inter = Interlast then
                              if Dir = Dirlast then
                                 goto Continue_Loop;
                              end if;
                           end if;
                        end if;
                        if I > 1 then
                           Im_Poly_Ints (Ints) := Inter;  -- constraint error
                           Ints                := Ints + 1;
                        end if;
                        Lastind1   := I;
                        Dirlast    := Dir;
                        Interlast  := Inter;
                        Interfirst := 0;
                     end;
                  end if;
               end;
               <<Continue_Loop>>null;
            end loop;
            --********************
            -- Need a sort here to compare intersections?
            --   Sort_Poly_Ints;
            --********************
            --          for I in 1..Ints-1 loop
            --          Text_IO.Put(Integer'Image(Im_Poly_Ints (I)));
            --          end loop;
            --          Text_IO.New_Line;
            Iterator := 1;
            while Iterator < Ints loop
               Image_Line
                 (Im,
                  (Im_Poly_Ints (Iterator), Y),
                  (Im_Poly_Ints (Iterator + 1), Y),
                  Col);
               Iterator := Iterator + 2;
            end loop;
         end;
      end loop;
   end Image_Filled_Polygon;

   function Image_Color_Allocate (Im : Image; Col : RGB) return Color is
      Ct_C : Color;
   begin
      Ct_C := -1;
      for I_C in  0 .. Im.This.Colors_Total - 1 loop
         if Im.This.Open (I_C) /= 0 then
            Ct_C := I_C;
            exit;
         end if;
      end loop;
      if Ct_C = -1 then
         Ct_C := Im.This.Colors_Total;
         if Ct_C = Max_Color_Map_Size then
            return -1;
         end if;
         Im.This.Colors_Total := Im.This.Colors_Total + 1;
      end if;
      Im.This.Red (Ct_C)   := Color (Col.R);
      Im.This.Green (Ct_C) := Color (Col.G);
      Im.This.Blue (Ct_C)  := Color (Col.B);
      Im.This.Open (Ct_C)  := 0;
      return Ct_C;
   end Image_Color_Allocate;

   function Image_Color_Closest (Im : Image; Col : RGB) return Color is
      Rd      : Color;
      Gd      : Color;
      Bd      : Color;
      Ct      : Color;
      Mindist : Color;
   begin
      Ct      := -1;
      Mindist := 0;
      for I_C in  0 .. Im.This.Colors_Total - 1 loop
         declare
            Dist : Color;
         begin
            if Im.This.Open (I_C) = 0 then
               Rd   := Im.This.Red (I_C) - Color (Col.R);
               Gd   := Im.This.Green (I_C) - Color (Col.G);
               Bd   := Im.This.Blue (I_C) - Color (Col.B);
               Dist := Rd * Rd + Gd * Gd + Bd * Bd;
               if I_C = 0 or else Dist < Mindist then
                  Mindist := Dist;
                  Ct      := I_C;
               end if;
            end if;
         end;
      end loop;
      return Ct;
   end Image_Color_Closest;

   function Image_Color_Exact (Im : Image; Col : RGB) return Color is
   begin
      for I_C in  0 .. Im.This.Colors_Total - 1 loop
         if Im.This.Open (I_C) = 0 then
            if Im.This.Red (I_C) = Color (Col.R)
              and then Im.This.Green (I_C) = Color (Col.G)
              and then Im.This.Blue (I_C) = Color (Col.B)
            then
               return I_C;
            end if;
         end if;
      end loop;
      return -1;
   end Image_Color_Exact;

   procedure Image_Color_Deallocate (Im : Image; Col : Color) is
   begin
      Im.This.Open (Col) := 1;
   end Image_Color_Deallocate;

   procedure Image_Color_Transparent (Im : Image; Col : Color) is
   begin
      Im.This.Transparent := Col;
   end Image_Color_Transparent;

   -- s and e are integers modulo 360 (degrees), with 0 degrees
   -- being the rightmost extreme and degrees changing clockwise.
   -- cx and cy are the center in pixels; w and h are the horizontal
   -- and vertical diameter in pixels.
   procedure Image_Arc
     (Im            : Image;
      Center        : Point;
      Width         : J_Int;
      Height        : J_Int;
      Start_Degrees : J_Int;
      End_Degrees   : J_Int;
      Col           : Color)
   is
      Lx_C   : J_Int;
      Ly_C   : J_Int;
      W2     : J_Int;
      H2     : J_Int;
      Temp_E : J_Int;
   begin
      Lx_C   := 0;
      Ly_C   := 0;
      W2     := Width / 2;
      H2     := Height / 2;
      Temp_E := End_Degrees;
      while Temp_E < Start_Degrees loop
         Temp_E := Temp_E + 360;
      end loop;
      for I_C in  Start_Degrees .. Temp_E loop
         declare
            X_C : J_Int;
            Y_C : J_Int;
         begin
            X_C := Mtables.Cost (I_C rem 360 + 1) * W2 / Mtables.Costscale +
                   Center.X;
            Y_C := Mtables.Sint (I_C rem 360 + 1) * H2 / Mtables.Sintscale +
                   Center.Y;
            if I_C /= Start_Degrees then
               Image_Line (Im, (Lx_C, Ly_C), (X_C, Y_C), Col);
            end if;
            Lx_C := X_C;
            Ly_C := Y_C;
         end;
      end loop;
   end Image_Arc;

   procedure Image_Fill_To_Border
     (Im     : Image;
      P      : Point;
      Border : Color;
      Col    : Color)
   is
      Lastborder : J_Int;
      Leftlimit  : J_Int;
      Rightlimit : J_Int;
   begin
      -- Seek left
      Leftlimit := -1;
      if Border < 0 then
         -- Refuse to fill to a non-solid border
         return;
      end if;
      for I_C in reverse  0 .. P.X loop
         exit when Image_Get_Pixel (Im, (I_C, P.Y)) = Border;
         Image_Set_Pixel (Im, (I_C, P.Y), Col);
         Leftlimit := I_C;
      end loop;
      if Leftlimit = -1 then
         return;
      end if;
      -- Seek right
      Rightlimit := P.X;
      for I_C in  P.X + 1 .. Im.This.Sx - 1 loop
         exit when Image_Get_Pixel (Im, (I_C, P.Y)) = Border;
         Image_Set_Pixel (Im, (I_C, P.Y), Col);
         Rightlimit := I_C;
      end loop;
      -- Look at lines above and below and start paints
      -- Above
      if P.Y > 0 then
         Lastborder := 1;
         for I_C in  Leftlimit .. Rightlimit loop
            declare
               C_C : Color;
            begin
               C_C := Image_Get_Pixel (Im, (I_C, P.Y - 1));
               if Lastborder /= 0 then
                  if C_C /= Border and then C_C /= Col then
                     Image_Fill_To_Border (Im, (I_C, P.Y - 1), Border, Col);
                     Lastborder := 0;
                  end if;
               else
                  if C_C = Border or else C_C = Col then
                     Lastborder := 1;
                  end if;
               end if;
            end;
         end loop;
      end if;
      -- Below
      if P.Y < Im.This.Sy - 1 then
         Lastborder := 1;
         for I_C in  Leftlimit .. Rightlimit loop
            declare
               C_C : Color;
            begin
               C_C := Image_Get_Pixel (Im, (I_C, P.Y + 1));
               if Lastborder /= 0 then
                  if C_C /= Border and then C_C /= Col then
                     Image_Fill_To_Border (Im, (I_C, P.Y + 1), Border, Col);
                     Lastborder := 0;
                  end if;
               else
                  if C_C = Border or else C_C = Col then
                     Lastborder := 1;
                  end if;
               end if;
            end;
         end loop;
      end if;
   end Image_Fill_To_Border;

   procedure Image_Fill (Im : Image; P : Point; Col : Color) is
      Lastborder_C : J_Int;
      Old          : Color;
      Leftlimit_C  : J_Int;
      Rightlimit_C : J_Int;
   begin
      Old := Image_Get_Pixel (Im, P);
      if Col = Tiled then
         -- Tile fill
         declare
            P_C       : Color;
            Tilecolor : Color;
            Srcx_C    : J_Int;
            Srcy_C    : J_Int;
         begin
            if Im.This.Tile = null then
               return;
            end if;
            -- Refuse to flood-fill with a transparent pattern --
            -- can't do it without allocating another image
            if Im.This.Tile.Transparent /= -1 then
               return;
            end if;
            Srcx_C    := P.X rem Im.This.Tile.Sx;
            Srcy_C    := P.Y rem Im.This.Tile.Sy;
            P_C       := Image_Get_Pixel (Im.This.Tile, (Srcx_C, Srcy_C));
            Tilecolor := Im.This.Tile_Color_Map (P_C);
            if Old = Tilecolor then
               -- Nothing to be done
               return;
            end if;
         end;
      else
         if Old = Col then
            -- Nothing to be done
            return;
         end if;
      end if;
      -- Seek left
      Leftlimit_C := -1;
      for I_C in reverse  0 .. P.X loop
         exit when Image_Get_Pixel (Im, (I_C, P.Y)) /= Old;
         Image_Set_Pixel (Im, (I_C, P.Y), Col);
         Leftlimit_C := I_C;
      end loop;
      if Leftlimit_C = -1 then
         return;
      end if;
      -- Seek right
      Rightlimit_C := P.X;
      for I_C in  P.X + 1 .. Im.This.Sx - 1 loop   --while I_C10 < Im.This.Sx
                                                   --loop
         exit when Image_Get_Pixel (Im, (I_C, P.Y)) /= Old;
         Image_Set_Pixel (Im, (I_C, P.Y), Col);
         Rightlimit_C := I_C;
      end loop;
      -- Look at lines above and below and start paints
      -- Above
      if P.Y > 0 then
         Lastborder_C := 1;
         for I_C in  Leftlimit_C .. Rightlimit_C loop
            declare
               C_C : Color;
            begin
               C_C := Image_Get_Pixel (Im, (I_C, P.Y - 1));
               if Lastborder_C /= 0 then
                  if C_C = Old then
                     Image_Fill (Im, (I_C, P.Y - 1), Col);
                     Lastborder_C := 0;
                  end if;
               else
                  if C_C /= Old then
                     Lastborder_C := 1;
                  end if;
               end if;
            end;
         end loop;
      end if;
      -- Below
      if P.Y < Im.This.Sy - 1 then
         Lastborder_C := 1;
         for I_C in  Leftlimit_C .. Rightlimit_C loop
            declare
               C_C : Color;
            begin
               C_C := Image_Get_Pixel (Im, (I_C, P.Y + 1));
               if Lastborder_C /= 0 then
                  if C_C = Old then
                     Image_Fill (Im, (I_C, P.Y + 1), Col);
                     Lastborder_C := 0;
                  end if;
               else
                  if C_C /= Old then
                     Lastborder_C := 1;
                  end if;
               end if;
            end;
         end loop;
      end if;
   end Image_Fill;

   procedure Image_Copy
     (Dst    : Image;
      Src    : Image;
      To     : Point;
      From   : Point;
      Width  : J_Int;
      Height : J_Int)
   is
      C_C        : Color;
      Tox        : J_Int;
      Toy        : J_Int;
      Colormap_C : Table;
      Nc         : Color;
   begin
      for I_C in  Color_Range loop
         Colormap_C (I_C) := -1;
      end loop;
      Toy := To.Y;
      for Y_C in  From.Y .. From.Y + Height - 1 loop
         Tox := To.X;
         for X_C in  From.X .. From.X + Width - 1 loop
            C_C := Image_Get_Pixel (Src, (X_C, Y_C));
            if Src.This.Transparent = C_C then
               Tox := Tox + 1;
            else
               -- Have we established a mapping for this color?
               if Colormap_C (C_C) = -1 then
                  -- If it's the same image, mapping is trivial
                  if Dst = Src then
                     Nc := C_C;
                  else
                     -- First look for an exact match
                     Nc :=
                        Image_Color_Exact
                          (Dst,
                           (J_Int (Src.This.Red (C_C)),
                        J_Int (Src.This.Green (C_C)),
                        J_Int (Src.This.Blue (C_C))));
                  end if;
                  -- No, so try to allocate it
                  if Nc = -1 then
                     Nc :=
                        Image_Color_Allocate
                          (Dst,
                           (J_Int (Src.This.Red (C_C)),
                        J_Int (Src.This.Green (C_C)),
                        J_Int (Src.This.Blue (C_C))));
                     -- If we're out of colors, go for the closest color
                     if Nc = -1 then
                        Nc :=
                           Image_Color_Closest
                             (Dst,
                              (J_Int (Src.This.Red (C_C)),
                           J_Int (Src.This.Green (C_C)),
                           J_Int (Src.This.Blue (C_C))));
                     end if;
                  end if;
                  Colormap_C (C_C) := Nc;
               end if;
               Image_Set_Pixel (Dst, (Tox, Toy), Colormap_C (C_C));

               Tox := Tox + 1;
            end if;
         end loop;
         Toy := Toy + 1;
      end loop;
   end Image_Copy;

   procedure Image_Copy_Resized
     (Dst         : Image;
      Src         : Image;
      To          : Point;
      From        : Point;
      To_Width    : J_Int;
      To_Height   : J_Int;
      From_Width  : J_Int;
      From_Height : J_Int)
   is
      C_C        : Color;
      Tox_C      : J_Int;
      Toy_C      : J_Int;
      Ydest      : J_Int;
      Pixel      : J_Int;
      Colormap_C : Table;
      Stx        : array (0 .. From_Width) of J_Int;
      Sty        : array (0 .. From_Height) of J_Int;
      Accum_C    : Long_Float;
      Nc_C       : Color;
   begin
      -- We only need to use floating point to determine the correct
      --      stretch vector for one line's worth.
      Accum_C := 0.0;
      for I in  Stx'Range loop
         declare
            Got : J_Int;
         begin
            Accum_C := Accum_C +
                       Long_Float (To_Width) / Long_Float (From_Width);
            Got     := J_Int (Long_Float'Floor (Accum_C));
            Stx (I) := Got;
            Accum_C := Accum_C - Long_Float (Got);
         end;
      end loop;
      Accum_C := 0.0;
      for I in  Sty'Range loop
         declare
            Got_C : J_Int;
         begin
            Accum_C := Accum_C +
                       Long_Float (To_Height) / Long_Float (From_Height);

            Got_C   := J_Int (Long_Float'Floor (Accum_C));
            Sty (I) := Got_C;
            Accum_C := Accum_C - Long_Float (Got_C);

         end;
      end loop;
      for Colors in  Color_Range loop
         Colormap_C (Colors) := -1;
      end loop;
      Toy_C := To.Y;
      for Y_C in  From.Y .. From.Y + From_Height - 1 loop
         Ydest := 0;
         while Ydest < Sty (Y_C - From.Y) loop
            Tox_C := To.X;
            for X_C in  From.X .. From.X + From_Width - 1 loop
               if Stx (X_C - From.X) = 0 then
                  null; -- goto Continue2354;
               else
                  C_C := Image_Get_Pixel (Src, (X_C, Y_C));

                  if Src.This.Transparent = C_C then
                     Tox_C := Tox_C + Stx (X_C - From.X);
                  else
                     if Colormap_C (C_C) = -1 then
                        if Dst = Src then
                           Nc_C := C_C;
                        else
                           Nc_C :=
                              Image_Color_Exact
                                (Dst,
                                 (J_Int (Src.This.Red (C_C)),
                              J_Int (Src.This.Green (C_C)),
                              J_Int (Src.This.Blue (C_C))));
                        end if;
                        if Nc_C = -1 then
                           Nc_C :=
                              Image_Color_Allocate
                                (Dst,
                                 (J_Int (Src.This.Red (C_C)),
                              J_Int (Src.This.Green (C_C)),
                              J_Int (Src.This.Blue (C_C))));
                           if Nc_C = -1 then
                              Nc_C :=
                                 Image_Color_Closest
                                   (Dst,
                                    (J_Int (Src.This.Red (C_C)),
                                 J_Int (Src.This.Green (C_C)),
                                 J_Int (Src.This.Blue (C_C))));
                           end if;
                        end if;
                        Colormap_C (C_C) := Nc_C;
                     end if;
                     Pixel := 0;
                     while Pixel < Stx (X_C - From.X) loop
                        Image_Set_Pixel
                          (Dst,
                           (Tox_C, Toy_C),
                           Colormap_C (C_C));

                        Tox_C := Tox_C + 1;
                        Pixel := Pixel + 1;
                     end loop;
                  end if;
               end if;
            end loop;
            Toy_C := Toy_C + 1;
            Ydest := Ydest + 1;
         end loop;
      end loop;
   end Image_Copy_Resized;

   procedure Image_Rotate (Dst : Image; Src : Image; Rotation : J_Int) is
      C_C        : Color;
      Tox        : J_Int;
      Toy        : J_Int;
      Colormap_C : Table;
      Nc         : Color;
      AvX        : J_Int;
      AvY        : J_Int;
      RadiusX    : J_Int;
      RadiusY    : J_Int;
      Radius     : J_Int;
   begin
      for I_C in  Color_Range loop
         Colormap_C (I_C) := -1;
      end loop;
      AvX     := Src.This.Sx / 2 - 1;
      RadiusX := J_Int'Min (Src.This.Sx - AvX, AvX);
      AvY     := Src.This.Sy / 2 - 1;
      RadiusY := J_Int'Min (Src.This.Sy - AvY, AvY);
      Radius  := J_Int'Min (RadiusX, RadiusY);
      Radius  := Radius * Radius;
      -- Toy := 0;
      for Y_C in  0 .. Src.This.Sy - 1 loop
         -- Tox := 0;
         for X_C in  0 .. Src.This.Sx - 1 loop
            C_C := Image_Get_Pixel (Src, (X_C, Y_C));
            if Src.This.Transparent = C_C then
               null; --Tox := Tox + 1;
            else
               -- Have we established a mapping for this color?
               if Colormap_C (C_C) = -1 then
                  -- If it's the same image, mapping is trivial
                  if Dst = Src then
                     Nc := C_C;
                  else
                     -- First look for an exact match
                     Nc :=
                        Image_Color_Exact
                          (Dst,
                           (J_Int (Src.This.Red (C_C)),
                        J_Int (Src.This.Green (C_C)),
                        J_Int (Src.This.Blue (C_C))));
                  end if;
                  -- No, so try to allocate it
                  if Nc = -1 then
                     Nc :=
                        Image_Color_Allocate
                          (Dst,
                           (J_Int (Src.This.Red (C_C)),
                        J_Int (Src.This.Green (C_C)),
                        J_Int (Src.This.Blue (C_C))));
                     -- If we're out of colors, go for the closest color
                     if Nc = -1 then
                        Nc :=
                           Image_Color_Closest
                             (Dst,
                              (J_Int (Src.This.Red (C_C)),
                           J_Int (Src.This.Green (C_C)),
                           J_Int (Src.This.Blue (C_C))));
                     end if;
                  end if;
                  Colormap_C (C_C) := Nc;
               end if;
            end if;
            Tox := (X_C - AvX) * (X_C - AvX);
            Toy := (Y_C - AvY) * (X_C - AvY);
            if Tox + Toy < Radius then
               Tox :=
                 (Mtables.Cost (Rotation rem 360 + 1) * (X_C - AvX)) /
                 Mtables.Costscale +
                 (Mtables.Sint (Rotation rem 360 + 1) * (Y_C - AvY)) /
                 Mtables.Sintscale +
                 AvX;
               -- X_C := Mtables.Cost (I_C rem 360 + 1) * W2 /
               --Mtables.Costscale + Center.X;
               Toy :=
                 (-(Mtables.Sint (Rotation rem 360 + 1) * (X_C - AvX))) /
                 Mtables.Sintscale +
                 (Mtables.Cost (Rotation rem 360 + 1) * (Y_C - AvY)) /
                 Mtables.Costscale +
                 AvY;
               -- Y_C := Mtables.Sint (I_C rem 360 + 1) * H2 /
               --Mtables.Sintscale + Center.Y;
               Image_Set_Pixel (Dst, (Tox, Toy), Colormap_C (C_C));
               Image_Set_Pixel (Dst, (Tox + 1, Toy), Colormap_C (C_C));
               --                   Image_Set_Pixel (Dst, (Tox-1, Toy),
               --Colormap_C (C_C));
               --                   Image_Set_Pixel (Dst, (Tox, Toy-1),
               --Colormap_C (C_C));
               Image_Set_Pixel (Dst, (Tox, Toy + 1), Colormap_C (C_C));
            else
               Image_Set_Pixel (Dst, (X_C, Y_C), Colormap_C (C_C));
            end if;
         end loop;
      end loop;

   end Image_Rotate;

   procedure Image_Set_Brush (Im : Image; Brush : Image) is
   begin
      Im.This.Brush := Brush.This;
      for I_C in  0 .. Brush.This.Colors_Total - 1 loop
         declare
            Index : Color;
         begin
            Index :=
               Image_Color_Exact
                 (Im,
                  (J_Int (Brush.This.Red (I_C)),
               J_Int (Brush.This.Green (I_C)),
               J_Int (Brush.This.Blue (I_C))));
            if Index = -1 then
               Index :=
                  Image_Color_Allocate
                    (Im,
                     (J_Int (Brush.This.Red (I_C)),
                  J_Int (Brush.This.Green (I_C)),
                  J_Int (Brush.This.Blue (I_C))));
               if Index = -1 then
                  Index :=
                     Image_Color_Closest
                       (Im,
                        (J_Int (Brush.This.Red (I_C)),
                     J_Int (Brush.This.Green (I_C)),
                     J_Int (Brush.This.Blue (I_C))));
               end if;
            end if;
            Im.This.Brush_Color_Map (I_C) := Index;
         end;
      end loop;
   end Image_Set_Brush;

   procedure Image_Set_Tile (Im : Image; Tile : Image) is
   begin
      Im.This.Tile := Tile.This;
      for I_C in  0 .. Tile.This.Colors_Total - 1 loop
         declare
            Index_C : Color;
         begin
            Index_C :=
               Image_Color_Exact
                 (Im,
                  (J_Int (Tile.This.Red (I_C)),
               J_Int (Tile.This.Green (I_C)),
               J_Int (Tile.This.Blue (I_C))));
            if Index_C = -1 then
               Index_C :=
                  Image_Color_Allocate
                    (Im,
                     (J_Int (Tile.This.Red (I_C)),
                  J_Int (Tile.This.Green (I_C)),
                  J_Int (Tile.This.Blue (I_C))));
               if Index_C = -1 then
                  Index_C :=
                     Image_Color_Closest
                       (Im,
                        (J_Int (Tile.This.Red (I_C)),
                     J_Int (Tile.This.Green (I_C)),
                     J_Int (Tile.This.Blue (I_C))));
               end if;
            end if;
            Im.This.Tile_Color_Map (I_C) := Index_C;
         end;
      end loop;
   end Image_Set_Tile;

   procedure Image_Set_Style (Im : Image; Style : Color_Array) is
   begin
      if Im.This.Style /= null then
         Free (Im.This.Style);
      end if;
      Im.This.Style        := new Color_Array'(Style);
      Im.This.Style_Length := Style'Length;
      Im.This.Style_Pos    := 0;
   end Image_Set_Style;

   procedure Image_Interlace (Im : Image; Interlace_Arg : J_Int) is
   begin
      Im.This.Interlace := Interlace_Arg;
   end Image_Interlace;

   procedure Gifencode
     (Gwidth       : J_Int;
      Gheight      : J_Int;
      Ginterlace   : J_Int;
      Background   : J_Int;
      Transparent  : Color;
      Bitsperpixel : J_Int;
      Red          : Table;
      Green        : Table;
      Blue         : Table;
      Im           : in out Image'Class);

   procedure Image_Gif (Im : in out Image'Class) is
      Interlace    : J_Int;
      Transparent  : Color;
      Bitsperpixel : J_Int;

      function Colorstobpp (Colors : Color) return J_Int is
         Bpp : J_Int;
      begin
         Bpp := 0;
         if Colors <= 2 then
            Bpp := 1;
         elsif Colors <= 4 then
            Bpp := 2;
         elsif Colors <= 8 then
            Bpp := 3;
         elsif Colors <= 16 then
            Bpp := 4;
         elsif Colors <= 32 then
            Bpp := 5;
         elsif Colors <= 64 then
            Bpp := 6;
         elsif Colors <= 128 then
            Bpp := 7;
         elsif Colors <= 256 then
            Bpp := 8;
         end if;
         return Bpp;
      end Colorstobpp;

   begin
      Interlace    := Im.This.Interlace;
      Transparent  := Im.This.Transparent;
      Bitsperpixel := Colorstobpp (Im.This.Colors_Total);
      Gifencode
        (Im.This.Sx,
         Im.This.Sy,
         Interlace,
         0,
         Transparent,
         Bitsperpixel,
         Im.This.Red,
         Im.This.Green,
         Im.This.Blue,
         Im);
   end Image_Gif;

   ---------------------------------------------------------------------------
   ---- Encoding stuff below
   ---------------------------------------------------------------------------

   procedure Gifencode
     (Gwidth       : J_Int;
      Gheight      : J_Int;
      Ginterlace   : J_Int;
      Background   : J_Int;
      Transparent  : Color;
      Bitsperpixel : J_Int;
      Red          : Table;
      Green        : Table;
      Blue         : Table;
      Im           : in out Image'Class)
   is

      procedure Put_Char (Data : J_Byte) is
         Str : String (1 .. 1);
      begin
         Str (1) := Character'Val (Integer (Data));
         Callback (Im, Str);
      end Put_Char;

      procedure Put_String (Str : String) is
      begin
         Callback (Im, Str);
      end Put_String;

      procedure Put_Word (W : J_Int) is
         use type Interfaces.Unsigned_32;
      begin
         Put_Char (J_Byte (Interfaces.Unsigned_32 (W) and 16#FF#));
         Put_Char (J_Byte (Interfaces.Unsigned_32 (W) / 2 ** 8));
      end Put_Word;

      A_Count        : J_Int renames Im.This.Dx.A_Count;
      Code_Clear     : J_Int renames Im.This.Dx.Code_Clear;
      Code_Eof       : J_Int renames Im.This.Dx.Code_Eof;
      Countdown      : Long_Integer renames Im.This.Dx.Countdown;
      Curx           : J_Int renames Im.This.Dx.Curx;
      Cury           : J_Int renames Im.This.Dx.Cury;
      Height         : J_Int renames Im.This.Dx.Height;
      Interlace_C    : J_Int renames Im.This.Dx.Interlace_C;
      Just_Cleared   : J_Int renames Im.This.Dx.Just_Cleared;
      Max_Ocodes     : J_Int renames Im.This.Dx.Max_Ocodes;
      Obits          : J_Int renames Im.This.Dx.Obits;
      Oblen          : J_Int renames Im.This.Dx.Oblen;
      Oblock         : Block renames Im.This.Dx.Oblock;
      Obuf           : Interfaces.Unsigned_32 renames Im.This.Dx.Obuf;
      Out_Bits       : J_Int renames Im.This.Dx.Out_Bits;
      Out_Bits_Init  : J_Int renames Im.This.Dx.Out_Bits_Init;
      Out_Bump       : J_Int renames Im.This.Dx.Out_Bump;
      Out_Bump_Init  : J_Int renames Im.This.Dx.Out_Bump_Init;
      Out_Clear      : J_Int renames Im.This.Dx.Out_Clear;
      Out_Clear_Init : J_Int renames Im.This.Dx.Out_Clear_Init;
      Out_Count      : J_Int renames Im.This.Dx.Out_Count;
      Pass           : J_Int renames Im.This.Dx.Pass;
      Rl_Basecode    : J_Int renames Im.This.Dx.Rl_Basecode;
      Rl_Count       : J_Int renames Im.This.Dx.Rl_Count;
      Rl_Pixel       : J_Int renames Im.This.Dx.Rl_Pixel;
      Rl_Table_Max   : J_Int renames Im.This.Dx.Rl_Table_Max;
      Rl_Table_Pixel : J_Int renames Im.This.Dx.Rl_Table_Pixel;
      Width          : J_Int renames Im.This.Dx.Width;

      -- Return the next pixel from the image
      function Gifnextpixel (Im : Image) return J_Int is
         R : J_Int;
      begin
         if Countdown = 0 then
            return Eof;
         end if;
         Countdown := Countdown - 1;
         if Cury > 0 and
            Cury <= Im.This.Sy and
            Curx > 0 and
            Curx <= Im.This.Sx
         then
            R := J_Int (Im.This.Pixels (Curx, Cury));
         else
            R := 0;
         end if;
         Curx := Curx + 1;
         if Curx = Width then
            Curx := 0;
            if Interlace_C = 0 then
               Cury := Cury + 1;
            else
               case Pass is
                  when 0 =>
                     Cury := Cury + 8;
                     if Cury >= Height then
                        Pass := Pass + 1;
                        Cury := 4;
                     end if;
                  when 1 =>
                     Cury := Cury + 8;
                     if Cury >= Height then
                        Pass := Pass + 1;
                        Cury := 2;
                     end if;
                  when 2 =>
                     Cury := Cury + 4;
                     if Cury >= Height then
                        Pass := Pass + 1;
                        Cury := 1;
                     end if;
                  when 3 =>
                     Cury := Cury + 2;
                  when others =>
                     null;
               end case;
            end if;
         end if;
         return R;
      end Gifnextpixel;

      procedure Write_Block is
         Str : String (1 .. Oblen);
      begin
         Put_Char (J_Byte (Oblen));
         for I in  0 .. Oblen - 1 loop
            Str (I + 1) := Character'Val (Oblock (I));
         end loop;
         Put_String (Str);
         Oblen := 0;
      end Write_Block;

      procedure Block_Out (C_C : J_Byte) is
      begin
         Oblock (Oblen) := C_C;
         Oblen          := Oblen + 1;
         if Oblen >= Block'Last then
            Write_Block;
         end if;
      end Block_Out;

      procedure Block_Flush is
      begin
         if Oblen > 0 then
            Write_Block;
         end if;
      end Block_Flush;

      procedure Output (Val : J_Int) is
         use Interfaces;
      begin
         Obuf := Obuf or (Interfaces.Unsigned_32 (Val) * 2 ** Obits);

         Obits := Obits + Out_Bits;
         while Obits >= 8 loop
            Block_Out (J_Byte (Obuf and 16#FF#));
            Obuf  := Shift_Right (Obuf, 8);
            Obits := Obits - 8;
         end loop;
      end Output;

      procedure Did_Clear is
      begin
         Out_Bits     := Out_Bits_Init;
         Out_Bump     := Out_Bump_Init;
         Out_Clear    := Out_Clear_Init;
         Out_Count    := 0;
         Rl_Table_Max := 0;
         Just_Cleared := 1;
      end Did_Clear;

      procedure Output_Flush is
      begin
         if Obits > 0 then
            Block_Out (J_Byte (Obuf));
         end if;
         Block_Flush;
      end Output_Flush;

      procedure Output_Plain (C_C : J_Int) is
      begin
         Just_Cleared := 0;
         Output (C_C);
         Out_Count := Out_Count + 1;
         if Out_Count >= Out_Bump then
            Out_Bits := Out_Bits + 1;
            Out_Bump := Out_Bump + 2 ** (Out_Bits - 1);

         end if;
         if Out_Count >= Out_Clear then
            Output (Code_Clear);
            Did_Clear;
         end if;
      end Output_Plain;

      function Isqrt (X : J_Int) return J_Int is
         R_C : Interfaces.Unsigned_32;
         V   : Interfaces.Unsigned_32;
         use Interfaces;
      begin
         if X < 2 then
            return X;
         end if;
         V   := Interfaces.Unsigned_32 (X);
         R_C := 1;
         while V /= 0 loop
            V   := Shift_Right (V, 2);
            R_C := Shift_Left (R_C, 1);
         end loop;
         loop
            V := (Interfaces.Unsigned_32 (X) / R_C + R_C) / 2;
            if V = R_C or else V = R_C + 1 then
               return J_Int (R_C);
            end if;
            R_C := V;
         end loop;
      end Isqrt;

      function Compute_Triangle_Count
        (Count     : J_Int;
         Nrepcodes : J_Int)
         return      J_Int
      is
         Perrep     : J_Int;
         Cost       : J_Int;
         Temp_Count : J_Int := Count;
      begin
         Cost   := 0;
         Perrep := Nrepcodes * (Nrepcodes + 1) / 2;

         while Temp_Count >= Perrep loop
            Cost       := Cost + Nrepcodes;
            Temp_Count := Temp_Count - Perrep;
         end loop;
         if Temp_Count > 0 then
            declare
               N : J_Int;
            begin
               N := Isqrt (Temp_Count);
               while N * (N + 1) >= 2 * Temp_Count loop
                  N := N - 1;
               end loop;
               while N * (N + 1) < 2 * Temp_Count loop
                  N := N + 1;
               end loop;
               Cost := Cost + N;
            end;
         end if;
         return Cost;
      end Compute_Triangle_Count;

      procedure Max_Out_Clear is
      begin
         Out_Clear := Max_Ocodes;
      end Max_Out_Clear;

      procedure Reset_Out_Clear is
      begin
         Out_Clear := Out_Clear_Init;
         if Out_Count >= Out_Clear then
            Output (Code_Clear);
            Did_Clear;
         end if;
      end Reset_Out_Clear;

      procedure Rl_Flush_Fromclear (Count : J_Int) is
         N_C        : J_Int;
         Temp_Count : J_Int := Count;
      begin
         Max_Out_Clear;
         Rl_Table_Pixel := Rl_Pixel;
         N_C            := 1;
         while Temp_Count > 0 loop
            if N_C = 1 then
               Rl_Table_Max := 1;
               Output_Plain (Rl_Pixel);
               Temp_Count := Temp_Count - 1;
            else
               if Temp_Count >= N_C then
                  Rl_Table_Max := N_C;
                  Output_Plain (Rl_Basecode + N_C - 2);
                  Temp_Count := Temp_Count - N_C;
               else
                  if Temp_Count = 1 then
                     Rl_Table_Max := Rl_Table_Max + 1;
                     Output_Plain (Rl_Pixel);
                     Temp_Count := 0;
                  else
                     Rl_Table_Max := Rl_Table_Max + 1;
                     Output_Plain (Rl_Basecode + Temp_Count - 2);
                     Temp_Count := 0;
                  end if;
               end if;
            end if;
            if Out_Count = 0 then
               N_C := 1;
            else
               N_C := N_C + 1;
            end if;
         end loop;
         Reset_Out_Clear;
      end Rl_Flush_Fromclear;

      procedure Rl_Flush_Clearorrep (Count : J_Int) is
         Withclr    : J_Int;
         Temp_Count : J_Int := Count;
      begin
         Withclr := 1 + Compute_Triangle_Count (Temp_Count, Max_Ocodes);
         if Withclr < Temp_Count then
            Output (Code_Clear);
            Did_Clear;
            Rl_Flush_Fromclear (Temp_Count);
         else
            while Temp_Count > 0 loop
               Output_Plain (Rl_Pixel);
               Temp_Count := Temp_Count - 1;
            end loop;
         end if;
      end Rl_Flush_Clearorrep;

      procedure Rl_Flush_Withtable (Count : J_Int) is
         Repmax   : J_Int;
         Repleft  : J_Int;
         Leftover : J_Int;
      begin
         Repmax   := Count / Rl_Table_Max;
         Leftover := Count rem Rl_Table_Max;
         if Leftover /= 0 then
            Repleft := 1;
         else
            Repleft := 0;
         end if;
         if Out_Count + Repmax + Repleft > Max_Ocodes then
            Repmax   := Max_Ocodes - Out_Count;
            Leftover := Count - Repmax * Rl_Table_Max;
            Repleft  := 1 + Compute_Triangle_Count (Leftover, Max_Ocodes);
         end if;
         if 1 + Compute_Triangle_Count (Count, Max_Ocodes) <
            Repmax + Repleft
         then
            Output (Code_Clear);
            Did_Clear;
            Rl_Flush_Fromclear (Count);
            return;
         end if;
         Max_Out_Clear;
         while Repmax > 0 loop
            Output_Plain (Rl_Basecode + Rl_Table_Max - 2);
            Repmax := Repmax - 1;
         end loop;
         if Leftover /= 0 then
            if Just_Cleared /= 0 then
               Rl_Flush_Fromclear (Leftover);
            else
               if Leftover = 1 then
                  Output_Plain (Rl_Pixel);
               else
                  Output_Plain (Rl_Basecode + Leftover - 2);
               end if;
            end if;
         end if;
         Reset_Out_Clear;
      end Rl_Flush_Withtable;

      procedure Rl_Flush is
      begin
         if Rl_Count = 1 then
            Output_Plain (Rl_Pixel);
            Rl_Count := 0;
            return;
         end if;
         if Just_Cleared /= 0 then
            Rl_Flush_Fromclear (Rl_Count);
         else
            if Rl_Table_Max < 2 or else Rl_Table_Pixel /= Rl_Pixel then
               Rl_Flush_Clearorrep (Rl_Count);
            else
               Rl_Flush_Withtable (Rl_Count);
            end if;
         end if;
         Rl_Count := 0;
      end Rl_Flush;

      procedure Compress (Init_Bits : J_Int; Background : J_Int) is
         C_C : J_Int;
      begin
         Obuf          := 0;
         Obits         := 0;
         Oblen         := 0;
         Code_Clear    := 2 ** (Init_Bits - 1);
         Code_Eof      := Code_Clear + 1;
         Rl_Basecode   := Code_Eof + 1;
         Out_Bump_Init := 2 ** (Init_Bits - 1) - 1;
         declare
            Tmp_Var : J_Int;
         begin
            if Init_Bits <= 3 then
               Tmp_Var := 9;
            else
               Tmp_Var := Out_Bump_Init - 1;
            end if;
            Out_Clear_Init := Tmp_Var;
         end;
         Out_Bits_Init := Init_Bits;
         Max_Ocodes    := 2 ** (Gifbits) -
                          (2 ** (Out_Bits_Init - 1) + 3);

         Did_Clear;
         Output (Code_Clear);
         Rl_Count := 0;
         for Ypix in  1 .. Im.This.Sy loop
            for Xpix in  1 .. Im.This.Sx loop
               C_C := J_Int (Im.This.Pixels (Xpix, Ypix));
               if Rl_Pixel = C_C then
                  Rl_Count := Rl_Count + 1;
               else
                  if Rl_Count > 0 then
                     Rl_Flush;
                  end if;
                  Rl_Pixel := C_C;
                  Rl_Count := 1;
               end if;
            end loop;
         end loop;
         Rl_Flush;
         Output (Code_Eof);
         Output_Flush;
      end Compress;

      procedure Init_Statics is
      -- Clear any old values in statics strewn through the code
      begin
         Width       := 0;
         Height      := 0;
         Curx        := 0;
         Cury        := 0;
         Countdown   := 0;
         Pass        := 0;
         Interlace_C := 0;
         A_Count     := 0;
      end Init_Statics;

      B            : J_Byte;
      Rwidth       : J_Int;
      Rheight      : J_Int;
      Leftofs      : J_Int;
      Topofs       : J_Int;
      Resolution   : J_Int;
      Colormapsize : Color;
      Initcodesize : J_Int;
      use type Interfaces.Unsigned_8;

   begin
      Init_Statics;
      Interlace_C  := Ginterlace;
      Colormapsize := 2 ** Bitsperpixel;
      Width        := Gwidth;
      Rwidth       := Width;
      Height       := Gheight;
      Rheight      := Height;
      Topofs       := 0;
      Leftofs      := Topofs;
      Resolution   := Bitsperpixel;
      --  Calculate number of bits we are expecting;
      Countdown := Long_Integer (Width) * Long_Integer (Height);
      -- Indicate which pass we are on (if interlace)
      Pass := 0;
      -- The initial code size
      if Bitsperpixel <= 1 then
         Initcodesize := 2;
      else
         Initcodesize := Bitsperpixel;
      end if;
      -- Set up the current x and y position
      Cury := 0;
      Curx := Cury;
      -- Write the Magic header
      if Transparent < 0 then
         Put_String (Image_Code_87a);
      else
         Put_String (Image_Code_89a);
      end if;
      Put_Word (Rwidth);
      Put_Word (Rheight);
      -- Indicate that there is a global colour map
      B := 16#80#;
      -- OR in the resolution
      B := B or (J_Byte (Resolution) - 1) * 2 ** 4;
      -- OR in the Bits per Pixel
      B := B or J_Byte (Bitsperpixel) - 1;
      Put_Char (J_Byte (B));
      -- Write out the Background colour
      Put_Char (J_Byte (Background));
      Put_Char (0);
      -- Write out the Global Colour Map
      for I_C in  0 .. Colormapsize - 1 loop
         Put_Char (J_Byte (Red (I_C)));
         Put_Char (J_Byte (Green (I_C)));
         Put_Char (J_Byte (Blue (I_C)));
      end loop;
      -- Write out extension for transparent colour index, if necessary.
      if Transparent >= 0 then
         Put_Char (Character'Pos ('!'));
         Put_Char (16#F9#);
         Put_Char (4);
         Put_Char (1);
         Put_Char (0);
         Put_Char (0);
         Put_Char (J_Byte (Transparent));
         Put_Char (0);
      end if;
      -- Write an Image separator
      Put_Char (Character'Pos (','));
      Put_Word (Leftofs);
      Put_Word (Topofs);
      Put_Word (Width);
      Put_Word (Height);
      -- Write out whether or not the image is interlaced
      if Interlace_C /= 0 then
         Put_Char (16#40#);
      else
         Put_Char (16#0#);
      end if;
      -- Write out the initial code size
      Put_Char (J_Byte (Initcodesize));
      Compress (Initcodesize + 1, Background);
      -- Write out a Zero-length packet (to end the series)
      Put_Char (0);
      -- Write the GIF file terminator
      Put_Char (Character'Pos (';'));
   end Gifencode;

   ------------------------------------------------------------------
   --  Storage reclamation
   ------------------------------------------------------------------

   protected Refs is
      procedure Adjust (Amt : Integer);
      function Amount return Integer;
   private
      Count : Integer := 0;
   end Refs;

   protected body Refs is
      procedure Adjust (Amt : Integer) is
      begin
         Count := Count + Amt;
      end Adjust;
      function Amount return Integer is
      begin
         return Count;
      end Amount;
   end Refs;

   procedure Finalize (Obj : in out Image) is
   begin
      if Obj.This /= null then
         Refs.Adjust (-1);
      end if;
      Image_Destroy (Obj);
   end Finalize;

   procedure Adjust (Obj : in out Image) is
      Contents : constant Image_Data := Obj.This.all;
   begin
      Obj.This     := new Image_Data (Contents.Sx, Contents.Sy);
      Obj.This.all := Contents;
      Refs.Adjust (+1);
   end Adjust;

   procedure Initialize (Obj : in out Image) is
   begin
      Obj.This := new Image_Data (Obj.Sx, Obj.Sy);
      Refs.Adjust (+1);
   end Initialize;

   function Deallocation_Report return String is
   begin
      return "Image objects left allocated =" & Integer'Image (Refs.Amount);
   end Deallocation_Report;

   procedure Callback (Obj : in out Image; Data : in String) is
   begin
      Text_IO.Put (Data);
   end Callback;

   ----------------------------------------------------------------------------
   ----
   -- $id: gnu-jif.adb,v 1.1 09/16/2002 18:18:13 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Gnu.Jif;
