with Str;

package Uio.Plotting is

   subtype Seconds is Integer range 0 .. Integer'Last;

   type Data_Set is array (Seconds range <>) of Float;

   use Str;

   type Plot_Config is record
      Font_Name : Str.Bstr.Bounded_String := Str.S2B("HersheySans-Bold");
      Font_Size : Float                   := 2.0;

      -- bg -> Background
      Bg_Color      : Str.Bstr.Bounded_String := Str.S2B("black");
      Bg_Line_Width : Float                   := 0.25;
      Bg_Pen_Color  : Str.Bstr.Bounded_String := Str.S2B("white");

      Border_Line_Width : Float                   := 1.5;
      Border_Pen_Color  : Str.Bstr.Bounded_String := Str.S2B("red");

      Labels_Pen_Color : Str.Bstr.Bounded_String := Str.S2B("gray");
      Grid_Line_Width  : Float                   := 0.01;

      Primary_Pen_Color  : Str.Bstr.Bounded_String := Str.S2B("white");
      Primary_Line_Width : Float                   := 0.25;

      Have_Crosshair       : Boolean                 := True;
      Crosshair_Pen_Color  : Str.Bstr.Bounded_String := Str.S2B("yellow");
      Crosshair_Line_Width : Float                   := 0.5;
   end record;

   Default_Plot_Config : Plot_Config;

   procedure Plot
     (File_Name : in String;
      Time      : in Seconds;
      Value     : in Float;
      Plot_Pts  : in out Data_Set;
      File_Type : in String   := "gif";
      Config    : Plot_Config := Default_Plot_Config);

end Uio.Plotting;
