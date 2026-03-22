with Pace;
with Pace.Log;
with Ada.Strings.Unbounded;

package body Ifc.Job_Data is

   package Asu renames Ada.Strings.Unbounded;

   use Str;
   use Item_Vector;

   procedure Set_Zoning (Id : Bstr.Bounded_String;
                         Item_Num : Integer;
                         Zone_Num : Integer) is
      use Vkb.Rules;
      Msg : Vkb.Query;
   begin
      Pace.Log.Put_Line ("set_zoning and id is " & (+Id), 8);
      Pace.Log.Put_Line ("set_zoning and Q(id) is " & Q (+Id, True), 8);
      Msg.Set := Str.S2u(F ("asserta", F ("zoning", Q (+Id, True) & ", " & S (Item_Num) & ", " & S (Zone_Num))));
      Pace.Dispatching.Inout (Msg);
   end Set_Zoning;

   procedure Add_Delivery_Job (Id : Bstr.Bounded_String;
                               Data : Delivery_Job_Data;
                               Description : Bstr.Bounded_String := Bstr.To_Bounded_String("No Description")) is

      function Get_Items_Prolog (Items : Item_Vector.Vector) return String is
         use Asu;
         use Vkb.Rules;
         Result : Unbounded_String := Null_Unbounded_String;
      begin
         for I in Item_Vector.First_Index (Items) .. Item_Vector.Last_Index (Items) loop
            if I /= 1 then
               Append (Result, ", ");
            end if;
            Append (Result, F ("item", "n=" & Q (S (I)) & "," &
                               F ("location", "easting=" & Q (S (Element (Items, I).Customer.Easting)) &
                                  ", northing=" & Q (S (Element (Items, I).Customer.Northing)) &
                                  ", zone_num=" & Q (S (Element (Items, I).Customer.Zone_Num)) &
                                  ", hemisphere=" & Q (Element (Items, I).Customer.Hemisphere'Img)) & ", " &
                               F ("el", S (Element (Items, I).Elevation)) & ", " &
                               F ("az", S (Element (Items, I).Azimuth)) & ", " &
                               F ("on_customer", S (Float (Element (Items, I).On_Customer_Time))) & ", " &
                               F ("box", Q (+Element (Items, I).Box)) & ", " &
                               F ("timer", "type=" & Q (+Element (Items, I).Timer) &
                                  ", setting=" & Q (+Element (Items, I).Timer_Setting))
                                  ));

         end loop;
         return To_String (Result);
      end Get_Items_Prolog;

      use Vkb.Rules;
      Msg : Vkb.Query;
   begin
      Msg.Set := Str.S2u(F ("assert",
                      F ("job", F ("id", Q (+Id)) & ", " &
                         Q (+Description) & ", " &
                         F ("data", F("customer", Q (+Data.Customer_Description)) & ", " &
                            F ("job_type", Q (+Data.Job_Description)) & ", " &
                            F ("control", "type=" & Q (+Data.Control) &
                               ", start_time=" & Q (S (Float (Data.Start_Time)))) & ", " &
                            F ("phase", Q (+Data.Phase)) & ", " &
                            F ("items", S (Natural (Item_Vector.Length (Data.Items)))) & ", " &
                            F ("item_list", Get_Items_Prolog (Data.Items))
                            ))));
      Pace.Dispatching.Inout (Msg);
   end Add_Delivery_Job;

   procedure Remove_Delivery_Job (Id : Bstr.Bounded_String) is
      use Vkb.Rules;
      Msg : Vkb.Query;
   begin
      Msg.Set := Str.S2u(F ("retract",
                      F ("job", F ("id", Q (+Id)) & ", _, _")));
      Pace.Dispatching.Inout (Msg);
   end Remove_Delivery_Job;

   procedure Get_Delivery_Job (Id : in Bstr.Bounded_String;
                               Found_It : out Boolean;
                               Data : out Delivery_Job_Data) is
      use Vkb.Rules;
      use Bstr;
      Num_Items : Integer;
      -- id to query with.. has quotes around it
      Query_Id : Bstr.Bounded_String;
   begin
      -- logic to handle Id coming in with quotes or not with quotes
      if Bstr.Element (Id, 1) = '"'  -- " (Quote Comment is for Xemacs Visualizing)
        or Bstr.Element (Id, 1) = ''' then -- '
         -- has quotes already so..
         Query_Id := Id;
         Data.Id := Bstr.Delete (Id, 1, 1);
         Data.Id := Bstr.Delete (Data.Id, Length (Data.Id), Length (Data.Id));
      else
         -- doesn't have quotes so...
         Data.Id := Id;
         Append (Query_Id, '"'); -- "
         Append (Query_Id, Id);
         Append (Query_Id, '"'); -- "
      end if;

      declare
         V : Variables (1 .. 7);
      begin
         V (1) := Str.S2u(+Query_Id);
         Vkb.Agent.Query ("get_job_static", V);
         Data.Customer_Description := +V (2);
         Data.Job_Description := +V (3);
         Data.Control := +V (4);
         Data.Start_Time := Duration'Value (Asu.To_String (V (5)));
         Data.Phase := +V (6);
         Num_Items := Integer'Value (Asu.To_String (V (7)));
      end;

      for I in 1 .. Num_Items loop
         declare
            V : Variables (1 .. 14);
            R : Item;
         begin
            V (1) := Str.S2u(+Query_Id);
            V (2) := Str.S2u(I'Img);
            Vkb.Agent.Query ("get_item", V);
            R.Box := +V (4);
            R.Timer := +V (5);
            R.Elevation := Float'Value (Asu.To_String (V (7)));
            R.Azimuth := Float'Value (Asu.To_String (V (8)));
            R.Timer_Setting := +V (9);
            R.On_Customer_Time := Duration'Value (Asu.To_String (V (10)));
            R.Customer.Easting := Float'Value (Asu.To_String (V (11)));
            R.Customer.Northing := Float'Value (Asu.To_String (V (12)));
            R.Customer.Zone_Num := Integer'Value (Asu.To_String (V (13)));
            R.Customer.Hemisphere := Gis.Hemisphere_Type'Value (Asu.To_String (V (14)));
            Item_Vector.Append (Data.Items, R);
         end;
      end loop;

      Found_It := True;
   exception
      when E : Vkb.Rules.No_Match =>
         Found_It := False;
      when E : others =>
         Pace.Log.Ex (E);
   end Get_Delivery_Job;

   function Has_Customer (Data : Delivery_Job_Data) return Boolean is
      use Bstr;
   begin
      if Data.Customer_Description = "None" then
         return False;
      else
         return True;
      end if;
   end Has_Customer;

end Ifc.Job_Data;
