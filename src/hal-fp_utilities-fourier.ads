with Ada.Numerics.Complex_Types;

generic
   N : Integer;
package Hal.Fp_Utilities.Fourier is

   type FFT_Type is
     array (Integer range 0 .. N - 1) of Ada.Numerics.Complex_Types.Complex;
   FFT_Error : exception;

   procedure magnitude_plot (X : in FFT_Type);  -- Quick spectrum ascii plot

   procedure list_values (X : in FFT_Type);  -- "Index" "(Re, Im)" "Magnitude"

   procedure FFT (X : in out FFT_Type; inverse : in Boolean := False);

   
end Hal.Fp_Utilities.Fourier;
