with Ada.Numerics.Elementary_Functions;
with Ada.Integer_Text_IO;
with Ada.Float_Text_IO;
with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with System;

package body Hal.Fp_Utilities.Fourier is
   use Ada.Numerics.Complex_Types;

   pi : constant Float   := Ada.Numerics.Pi;
   L  : constant Integer :=
      Integer (Ada.Numerics.Elementary_Functions.Log (Float (N)) /
               Ada.Numerics.Elementary_Functions.Log (2.0));

   min_angle_incr : constant Float := 2.0 * pi / Float (N);

   C : array (0 .. N - 1) of Float;   -- Cosine table

   function bit_reverse
     (x      : in Integer;
      Length : in Integer)
      return   Integer is

     
      type Bit_Array is array (1 .. Integer'Size) of Boolean;
      pragma Pack (Bit_Array);

      I : Integer := X;
      A : Bit_Array;
      for A'Address use I'Address;
      
      B : Bit_Array;
      J : Integer;
      for J'Address use B'Address;
      use System;
   begin
      if System.Default_Bit_Order = Low_Order_First then
         -- LINUX, INTEL, ETC
         for Index in 1..Length loop
            B(Index) := A(Length-Index+1);
         end loop;
      else
         -- SPARC, MIPS. ETC
         for Index in 1..Length loop
            B(Index+(Integer'Size-Length)) := A(Integer'Size-Index+1);
         end loop;
      end if;
      return J;
   end bit_reverse; 

   function bit_reverse0  -- Original (not used)
     (x      : in Integer;
      Length : in Integer)
      return   Integer
   is
      -- Length is number of bits to reverse
      -- Performs bit reversal. Better coded in assembly
      N  : Integer := 2 ** (Length - 1); -- Value of high bit
      XX : Integer := x;                 -- Number to convert
      y  : Integer := 1;  -- Bit position value
      YY : Integer := 0;  -- Result

   begin
      for W in  1 .. Length loop
         if XX >= N then
            YY := YY + y;
            XX := XX - N;
         end if;
         N := N / 2;
         y := y + y;
      end loop;
      return (YY);
   end bit_reverse0;

   function max_magnitude (X : in FFT_Type) return Float is
      max_mag : Float := 0.0; -- Result
      mag     : Float;
   begin
      for t in  X'Range loop  -- Do table
         mag := abs (X (t));
         if mag > max_mag then
            max_mag := mag;
         end if;
      end loop;
      return max_mag;
   end max_magnitude;

   -- Get magnitude

   procedure magnitude_plot (X : in FFT_Type) is
      scale      : Float;
      plot_value : Integer;
      use Ada.Integer_Text_IO;
      use Ada.Text_IO;
   begin
      scale := max_magnitude (X); -- Figure scale
      for t in  X'Range loop
         if scale > 0.01 then
            plot_value := Integer (56.0 * abs (X (t)) / scale);
         else
            plot_value := 0;
         end if;
         New_Line;
         Put (t, 3);
         Put (" ");
         Put ("|");
         for i in  1 .. plot_value loop
            Put ("=");
         end loop;
      end loop;
   end magnitude_plot;

   procedure list_values (X : in FFT_Type) is
      use Ada.Integer_Text_IO;
      use Ada.Float_Text_IO;
      use Ada.Text_IO;
   begin
      Put ("Harmonic ");
      Put ("Real ");
      Put ("Imaginary Magnitude");
      for harmonic in  X'Range loop
         New_Line;
         Put (harmonic, 3);
         Put (" (");
         Put (X (harmonic).Re, 3, 3, 0);
         Put (",");
         Put (X (harmonic).Im, 3, 3, 0);
         Put (")");
         Put (abs (X (harmonic)), 4, 3, 0);
      end loop;

   end list_values;

   procedure FFT (X : in out FFT_Type; inverse : in Boolean := False) is
      Q : constant Integer := N / 4; -- Ninety degrees

      B_fly_dis    : Integer; -- Butterfly distance
      num_cells    : Integer; -- Number of cells
      upper, lower : Integer; -- Pointer to B-flys
      r            : Integer; -- Target' temp for
      ang          : Integer; -- Angle 2 pi / N
      W, T         : Complex; -- Complex
      scale_factor : Float;   -- Scaling factor

   -- FFT in place

   begin
      if inverse then -- Scale inverse transform by 1 / N
         scale_factor := 1.0 / Float (N);
         for t in  X'Range loop
            X (t) := X (t) * scale_factor;
         end loop;
      end if;

      B_fly_dis := (N) / 2;     -- Distance between B-fly e~tries
      num_cells := 1;           -- Number of cells
      for pass in  1 .. L loop  -- Stage 1.. L
         upper := 0;            -- Pointer to top of cell
         lower := B_fly_dis;    -- Pointer to center of cell

         for j in  1 .. num_cells loop -- Number of cells
            ang := bit_reverse (upper / B_fly_dis, L);
            if inverse -- Construct W from cosine table
            then
               W := C (ang) + i * C ((ang - Q) mod N);
            else
               W := C (ang) - i * C ((ang - Q) mod N);
            end if;

            for m in  upper .. lower - 1 loop -- For each entry in cell
               T                 := W * X (m + B_fly_dis);
               X (m + B_fly_dis) := X (m) - T;
               X (m)             := X (m) + T;
            end loop;

            upper := upper + (B_fly_dis + B_fly_dis); -- next cell
            lower := lower + (B_fly_dis + B_fly_dis);
         end loop;

         B_fly_dis := B_fly_dis / 2; -- Halve distance between cells
         num_cells := 2 * num_cells; -- Double number of cells
      end loop;

      for i in  X'Range loop      -- Permute output
         r := bit_reverse (i, L); -- Get target coordinates
         if r < i then
            T     := X (i);       -- And swap
            X (i) := X (r);
            X (r) := T;
         end if;

      end loop;

   end FFT;

begin
   if N /= 2 ** L then -- Must be power of 2
      raise FFT_Error; -- entries
   end if;
   for i in  C'Range loop  -- Construct Cosine table on startup
      C (i) :=
         Ada.Numerics.Elementary_Functions.Cos (min_angle_incr * Float (i));
   end loop;

   
end Hal.Fp_Utilities.Fourier;
