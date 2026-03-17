--with GNU.plotutil.Linkage;
with Gnu.plotutil.Device;
with Gnu.plotutil.fplot;
with Pace.Log;
with Str;

package body Uio.Plotting is

   use Str;

   procedure Plot
     (File_Name : in String;
      Time      : in Seconds;
      Value     : in Float;
      Plot_Pts  : in out Data_Set;
      File_Type : in String   := "gif";
      Config    : Plot_Config := Default_Plot_Config)
   is

      Scroll_Size : constant Integer := Plot_Pts'Last;

      function Create_Image is new Gnu.plotutil.Device.New_File_Plotter (
         DriverName => File_Type);

      package FP is new Gnu.plotutil.fplot (Float);

      use FP, Gnu.plotutil;
      P_File : Plotter;
      Sz     : Float;
      PP     : Gnu.plotutil.Device.Plotter_Parameter;

      procedure Setup is

      begin
         PP     := Gnu.plotutil.Device.Create;
         P_File := Create_Image (File_Name, PP);
         Open (P_File);
         Space (P_File, 0.0, 0.0, Float (Scroll_Size), Float (Scroll_Size));
         Sz := Font_Name (P_File, Str.B2S(Config.Font_Name));
         Sz := Font_Size (P_File, Config.Font_Size);
         --
         -- Background
         --
         Background_ColorName (P_File, Str.B2S(Config.Bg_Color));
         Line_Width (P_File, Config.Bg_Line_Width);
         Pen_ColorName (P_File, Str.B2S(Config.Bg_Pen_Color));
         Erase (P_File);
         --
         -- Border
         --
         Line_Width (P_File, Config.Border_Line_Width);
         Pen_ColorName (P_File, Str.B2S(Config.Border_Pen_Color));
         Box (P_File, 0.0, 1.0, Float (Scroll_Size), Float (Scroll_Size));
      end Setup;

      procedure Send is
      begin
         Close (P_File);
         Delete (P_File);
         Gnu.plotutil.Device.Close_File (PP);
      end Send;

      Index : Integer;
      Last  : Integer;
   begin
      Setup;
      --
      -- Labels
      --
      Pen_ColorName (P_File, Str.B2S(Config.Labels_Pen_Color));
      Last := Scroll_Size * (1 + Time / Scroll_Size);
      for I in  1 .. (Scroll_Size / 5 - 1) loop
         Move (P_File, Float (Scroll_Size) - Float (I) * 5.0 - 2.0, 5.0);
         Label (P_File, Text => Integer'Image (Last - 5 * I));
      end loop;
      --
      -- X-Ticks
      --
      Line_Width (P_File, Config.Grid_Line_Width);
      for I in  0 .. Scroll_Size loop
         Move (P_File, Float (I), 0.0);
         if I mod 10 = 0 then
            Continue (P_File, Float (I), 5.0);
         elsif I mod 5 = 0 then
            Continue (P_File, Float (I), 4.0);
         else
            Continue (P_File, Float (I), 3.0);
         end if;
      end loop;
      --
      -- Y-Ticks
      --
      Move (P_File, 0.0, Float (Scroll_Size / 2));
      Label (P_File, Text => "50%");
      for I in  0 .. Scroll_Size loop
         Move (P_File, 0.0, Float (I));
         if I mod 10 = 0 then
            Continue (P_File, 2.0, Float (I));
         else
            Continue (P_File, 1.0, Float (I));
         end if;
      end loop;
      --
      -- Primary Plot Color
      --
      Pen_ColorName (P_File, Str.B2S(Config.Primary_Pen_Color));
      Line_Width (P_File, Config.Primary_Line_Width);
      --
      -- Plot Line
      --
      Index            := Time mod Scroll_Size;
      Plot_Pts (Index) := Value;
      Move (P_File, 0.0, Plot_Pts (Plot_Pts'First));
      for I in  Plot_Pts'Range loop
         if I = Index + 1 then
            Move (P_File, Float (I), Plot_Pts (I));
         else
            Continue (P_File, Float (I), Plot_Pts (I));
         end if;
      end loop;
      --
      -- Crosshair position + Current Data
      --
      if Config.Have_Crosshair then
         Pen_ColorName (P_File, Str.B2S(Config.Crosshair_Pen_Color));
         Line_Width (P_File, Config.Crosshair_Line_Width);
         Move (P_File, Float (Index), 0.0);
         Continue (P_File, Float (Index), Float (Scroll_Size / 2));
         Label
           (P_File,
            Text => "(" &
                    Integer'Image (Time) &
                    "," &
                    Integer'Image (Integer (Plot_Pts (Index))) &
                    ")");
         Move (P_File, Float (Index), Float (Scroll_Size / 2));
         Continue (P_File, Float (Index), Float (Scroll_Size));
         Move (P_File, 0.0, 0.0);
      end if;

      -- Files don't close very well in libplot, hmmm
      Flush (P_File);
      Send;

   end Plot;

end Uio.Plotting;
