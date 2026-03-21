with Ada.Strings.Unbounded;
with Pace.Server.Xml;
with Pace.Server.Kbase_Utilities;
with Pace.Log;
with Ahd.Delivery_Order_Status;
with Ahd.Delivery_Mission;
with Vkb;
with Ifc.Delivery_Mission;
with Str;
with Plant;

-- Is currently grabbing data straight from the kbase
-- as opposed to from some ada delivery mission controller class.  Should
-- be okay.. only accessing kbase once for each delivery mission.

package body Uio.Delivery_Order_Status is
   use Ahd.Delivery_Order_Status;
   use Pace.Server.Dispatch;
   use Str;

   function Id is new Pace.Log.Unit_Id;

   package Asu renames Ada.Strings.Unbounded;

   Num_Items : Integer;
   Boxs : array (1 .. Plant.Max_Boxs) of Box_Status;
   Mission_In_Progress : Boolean := False;

   Current_Item : Integer := 0;
   Mission_Static_Xml : Asu.Unbounded_String;
   Items_Xml : array (0 .. Plant.Max_Boxs) of Asu.Unbounded_String;

   Last_Delivery_Time : Duration;

--    function Get_Current_Item return Integer is
--    begin
--       return Current_Item;
--    end Get_Current_Item;

   function Item_Element
              (Index : Integer; Status : Box_Status) return String is
      use Pace.Server.Xml;
   begin
      return Item ("item", Item ("status", Box_Status'Image (Status)),
                   Pair ("index", Index));
   end Item_Element;

   function Get_Item_Status_Xml return Asu.Unbounded_String is
      use Asu;
      use Pace.Server.Xml;
      Item_Status : Unbounded_String;
   begin
      for I in 1 .. Plant.Max_Boxs loop
         exit when Boxs (I) = Nil;
         Append (Item_Status, Item_Element (I, Boxs (I)));
      end loop;
      Item_Status := (+Item (Element => "item_status",
                              Value => +Item_Status));
      return Item_Status;
   end Get_Item_Status_Xml;

   procedure Set_Mission_Static_Xml is
      use Asu;
      use Ifc.Delivery_Mission;
      Mission_Static_Query : String :=
        "get_fm_static(" & Vkb.Rules.Q (+Get_Delivery_Mission_Id) &
          ", Target, Mission_Type, Control, Start_Time, Phase, Num_Items)";
   begin
      Mission_Static_Xml := +Pace.Server.Kbase_Utilities.Kbase_To_Xml
                               (Agent => Vkb.Agent,
                                Query => +Mission_Static_Query,
                                Is_Xml_Tree => False,
                                Remove_Quotes => True);
   end Set_Mission_Static_Xml;

   procedure Set_Items_Xml is
      use Asu;
      use Pace.Server.Xml;
      use Ifc.Delivery_Mission;
      Current_Item_Xml : Unbounded_String := Asu.Null_Unbounded_String;
      Item_Query : Unbounded_String;
   begin
      Append (Current_Item_Xml, Item ("item_num", "0"));
      --Items_Xml (0) := +Item ("current_item", +Current_Item_Xml);
      Items_Xml (0) := Asu.Null_Unbounded_String;

      for I in 1 .. Num_Items loop
         Current_Item_Xml := Asu.Null_Unbounded_String;
         Item_Query := +("get_item(" & Vkb.Rules.Q (+Get_Delivery_Mission_Id) &
                          "," & Integer'Image (I) &
                          ",Zone,Box_type,Timer_type,Bottle_Type,Elev,Azim,Timer_Setting,On_Target,Easting,Northing,Zone_Num,Hemisphere)");

         Append (Current_Item_Xml, Item ("item_num", Trim (I)));
         Append (Current_Item_Xml, Pace.Server.Kbase_Utilities.Kbase_To_Xml
                                      (Agent => Vkb.Agent,
                                       Query => Item_Query,
                                       Is_Xml_Tree => False,
                                       Remove_Quotes => True));
         Items_Xml (I) := +Item ("current_item", +Current_Item_Xml);
      end loop;
   end Set_Items_Xml;


   function Get_Time_To_Delivery return String is
      Time_To_Delivery : Integer;
   begin
      if Current_Item = 0 or not Mission_In_Progress then
         return " ";
      end if;

      declare
         Delivery_Time : Duration := Ahd.Delivery_Mission.Get_Delivery_Time (Current_Item);
      begin
         if Ahd.Delivery_Mission.Is_Time_On_Target then
            -- then have specific time to deliver
            Time_To_Delivery := Integer (Delivery_Time - Pace.Now);
         else
            if Current_Item = 1 then
               if Boxs (1) = Placed then
                  Time_To_Delivery := 5 - Integer (Pace.Now - Last_Delivery_Time);
               else
                  return " ";
               end if;
            else
               Time_To_Delivery := 10 - Integer (Pace.Now - Last_Delivery_Time);
            end if;
            if Time_To_Delivery < 1 then
               Time_To_Delivery := 0;
            end if;
         end if;
      end;
      return Trim (Time_To_Delivery);
   end Get_Time_To_Delivery;


   function Create_Delivery_Order_Xml return String is
      use Asu;
   begin
      return Pace.Server.Xml.Item
        ("delivery_mission", +(Mission_Static_Xml &
                           Items_Xml (Current_Item) &
                           Get_Item_Status_Xml &
                           Pace.Server.Xml.Item
                           ("time_to_delivery", Get_Time_To_Delivery)));
   end Create_Delivery_Order_Xml;

   procedure Inout (Obj : in out Update_Delivery_Mission) is
      -- can be overriden using the style cgi parameter.  if no stylesheet
      -- is wanted then set style parameter to empty string
      Default_Stylesheet : String := "/eng/deliver/item_status.xsl";
   begin
      Pace.Server.Xml.Put_Content (Default_Stylesheet);
      Obj.Set := +Create_Delivery_Order_Xml;
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

   procedure Inout (Obj : in out Get_Current_Item) is
      Default_Stylesheet : String := "/eng/deliver/current_item_index.xsl";
   begin
      Pace.Server.Xml.Put_Content (Default_Stylesheet);
      Obj.Set := +Pace.Server.Xml.Item ("current_item_index",
                                        Trim (Current_Item));
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;


   procedure Initialize_Boxs;
   procedure Initialize_Boxs is
   begin
      for I in 1 .. Plant.Max_Boxs loop
         if I <= Num_Items then
            Boxs (I) := Ready;
         else
            Boxs (I) := Nil;
         end if;
      end loop;
   end Initialize_Boxs;


   task Agent is
      entry Input (Obj : Clear_Delivery_Mission);
   end Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);

      loop -- forever
         declare
            Setup : Box_Setup;
         begin
            -- Wait for start signal and how many boxs are ready
            Mission_In_Progress := False;
            Inout (Setup);
            Num_Items := Setup.Num_Boxs;
            Initialize_Boxs;
            Set_Items_Xml;
            Current_Item := 1;
            Set_Mission_Static_Xml;
            Mission_In_Progress := True;

            while Current_Item <= Num_Items loop
               -- Wait to be notified
               declare
                  Box_Change : Modify_Box;
               begin
                  Inout (Box_Change);
                  Boxs (Box_Change.Index) := Box_Change.Status;
                  if Box_Change.Status = Delivered or
                     (Box_Change.Status = Placed and Current_Item = 1) then
                     Last_Delivery_Time := Pace.Now;
                  end if;
                  if Box_Change.Status = Delivered then
                     Current_Item := Current_Item + 1;
                  end if;
               end;
            end loop;
            Current_Item := 0;

            accept Input (Obj : Clear_Delivery_Mission) do
               Mission_Static_Xml := +"";
               Num_Items := 0;
               for I in Items_Xml'Range loop
                  Items_Xml (I) := Asu.Null_Unbounded_String;
               end loop;
               Initialize_Boxs;
            end Input;

         end;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Clear_Delivery_Mission) is
   begin
      Agent.Input (Obj);
   end Input;


begin
   Save_Action (Update_Delivery_Mission'(Pace.Msg with Set => Xml_Set));
   Save_Action (Get_Current_Item'(Pace.Msg with Set => Xml_Set));
--   Save_Action (Order_Completed'(Pace.Msg with Set => Xml_Set));
end Uio.Delivery_Order_Status;
