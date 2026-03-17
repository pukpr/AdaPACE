with Ada.Strings.Unbounded;
with Pace.Server.Dispatch;
with Pace.Server.Html;
with Pace.Server.Xml;
with Pace.Server;
with Uio.Plotting;
with Str;
with Pace.Log;
with Hal.Velocity_Plots;
with Hal.Bounded_Assembly;

package body Uio.Velocity_Plots is

   use Pace.Server.Dispatch;
   use Hal.Bounded_Assembly;

   package Asu renames Ada.Strings.Unbounded;

   Config : Uio.Plotting.Plot_Config;

   type Plot is new Action with null record;
   procedure Inout (Obj : in out Plot);
   procedure Inout (Obj : in out Plot) is

      use Hal.Velocity_Plots;
      use Hal.Velocity_Plots.Velocity_Vector;

      File_Type : constant String := Asu.To_String (Obj.Set);

      function Get_Ext return String is
      begin
         if File_Type = "" then
            return "gif";
         else
            return File_Type;
         end if;
      end;
      Push : constant Boolean := (File_Type = "");

      Assembly : String := Pace.Server.Keys.Value ("key", "");
      FN : constant String := "/tmp/velocity_plot.gif";

      Plot_Data : Velocity_Plot_Data;

   begin

      if Assembly /= "" then
         Plot_Data := Get_Velocity_Vector (Assembly);

         if Push then
            Pace.Server.Push_Content;
         end if;

         declare
            Plot_Pts : Uio.Plotting.Data_Set (First_Index (Plot_Data.Velocities) .. Last_Index (Plot_Data.Velocities));

         begin
            for I in First_Index (Plot_Data.Velocities) .. Last_Index (Plot_Data.Velocities) loop

               Plot_Pts (I) := Element (Plot_Data.Velocities, I);
            end loop;
            for I in Plot_Pts'Range loop
               Pace.Log.Put_Line ("plot_pts " & I'Img & " is " & Plot_Pts (I)'Img);
            end loop;
            Uio.Plotting.Plot (Fn, Plot_Pts'First, Plot_Pts (Plot_Pts'First), Plot_Pts, Get_Ext, Config);
            Pace.Server.Put_Content (Content => "image/" & Get_Ext);
            Pace.Server.Put_Data (Pace.Server.Html.Read_File (FN, Htdocs_Location => False));
         end;
      end if;
   end Inout;

   type List_Assemblies is new Action with null record;
   procedure Inout (Obj : in out List_Assemblies);
   procedure Inout (Obj : in out List_Assemblies) is
      use Pace.Server.Xml;
      use Hal.Velocity_Plots.Assembly_Vector;

      Assemblies : Vector := Hal.Velocity_Plots.Get_Assembly_List;

      Current_Assembly : Bounded_String;
      Default_Stylesheet : String := "/eng/plot_list.xsl";
      Action_Base : constant String := "hal.velocity_plots.plot?key=";
      Result_Xml : Asu.Unbounded_String;
   begin
      for I in First_Index (Assemblies) .. Last_Index (Assemblies) loop

         Current_Assembly := Element (Assemblies, I);
         Asu.Append (Result_Xml, Item ("assembly", Item ("name", To_String (Current_Assembly)) &
                                       Item ("action", Action_Base & To_String (Current_Assembly))));
      end loop;
      Pace.Server.Xml.Put_Content (Default_Stylesheet => Default_Stylesheet);
      Pace.Server.Put_Data (Item ("assembly_list", Asu.To_String (Result_Xml)));
   end Inout;

begin
   Config.Font_Size := 0.5;
   Config.Border_Line_Width := 0.0;
   Config.Border_Pen_Color := Str.Str_To_Bstr ("black");
   Config.Primary_Line_Width := 0.1;
   Config.Have_Crosshair := False;

   Save_Action (Plot'(Pace.Msg with Set => Default));
   Save_Action (List_Assemblies'(Pace.Msg with Set => Default));
end Uio.Velocity_Plots;
