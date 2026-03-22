with Nav.Location;
with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Pace.Log;
with Pace.Config;
with Uio.Kbase;
with Gnu.Jif;
with Ada.Numerics.Elementary_Functions;
with Ada.Strings.Unbounded;
with Ual.Utilities;
with Sim.Unit_Tracker;
with Pace.Strings; use Pace.Strings;

package body Uio.Map is

   use Pace.Server.Dispatch;

   package Asu renames Ada.Strings.Unbounded;

--   Scale_Factor : constant := 100.0;

   --Entity_List_Xml : Asu.Unbounded_String;

   type Get_Easting is new Action with null record;
   procedure Inout (Obj : in out Get_Easting);
   procedure Inout (Obj : in out Get_Easting) is
      Msg : Nav.Location.Get_Data;
   begin
      Pace.Dispatching.Output (Msg);
      Obj.Set := +Integer'Image (Integer (Msg.Coordinate.Easting));
      Pace.Log.Trace (Obj);
   end Inout;

   type Get_Northing is new Action with null record;
   procedure Inout (Obj : in out Get_Northing);
   procedure Inout (Obj : in out Get_Northing) is
      Msg : Nav.Location.Get_Data;
   begin
      Pace.Dispatching.Output (Msg);
      Obj.Set := +Integer'Image (Integer (Msg.Coordinate.Northing));
      Pace.Log.Trace (Obj);
   end Inout;

   procedure Draw_Vehicle_Icon (Heading : in Float; Finish : in Boolean) is
      use Uio.Kbase;
      Green : constant Img.Rgb := (0, 255, 0);
      Yellow : constant Img.Rgb := (255, 255, 0);
      Red : constant Img.Rgb := (255, 0, 100);
      Radius : constant := 8;
      Pic : Stored_Image (Radius * 2, Radius * 2);
      Trans : Img.Color := Image_Color_Allocate (Pic, Green);
      Drone_Color : Img.Color := Image_Color_Allocate (Pic, Red);
      Vehicle_Color : Img.Color := Image_Color_Allocate (Pic, Yellow);
      use Ada.Numerics.Elementary_Functions;
      X, Y : Float;
   begin
      Image_Color_Transparent (Pic, Trans);
      X := Float (Radius) * (1.0 + Sin (Heading));
      Y := Float (Radius) * (1.0 - Cos (Heading));
      Image_Arc (Pic, (Radius, Radius), Radius + 1,
                 Radius + 1, 0, 360, Vehicle_Color);
      Image_Line (Pic, (Radius, Radius),
                  (Integer (X), Integer (Y)), Drone_Color);
      Uio.Kbase.Serve_Image (Pic, Finish);
   end Draw_Vehicle_Icon;

   type Vehicle_Icon is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Vehicle_Icon);

   procedure Inout (Obj : in out Vehicle_Icon) is
      Heading : Float;
   begin
      declare
         Msg : Nav.Location.Get_Data;
      begin
         Pace.Dispatching.Output (Msg);
         Heading := Msg.Heading;
      end;
      Draw_Vehicle_Icon (Heading => Heading, Finish => True);
      Pace.Log.Trace (Obj);
   end Inout;


--    procedure Update_Entity_List is
--    begin
--       -- remove this line when the entity list gets hooked up and remove the line below
--       -- that calls this method in the elaboration block
--       Entity_List_Xml := +Ual.Utilities.File_To_String (Pace.Config.Find_File ("kbase/entity_placeholder.xml"));
--    end Update_Entity_List;

   -- returns the known list of entities in xml
   type Get_Entity_List is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Entity_List);
   procedure Inout (Obj : in out Get_Entity_List) is
   begin
      Obj.Set := Sim.Unit_Tracker.Get_Entity_List_Xml;
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

begin
   Save_Action (Get_Easting'(Pace.Msg with Set => +"(template output)"));
   Save_Action (Get_Northing'(Pace.Msg with Set => +"(template output)"));
   Save_Action (Vehicle_Icon'(Pace.Msg with Set => Default));
   Save_Action (Get_Entity_List'(Pace.Msg with Set => Xml_Set));

--   Update_Entity_List;

end Uio.Map;
