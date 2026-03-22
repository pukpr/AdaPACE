with Vkb;
with Ada.Containers.Hashed_Maps;
with Pace.Strings; use Pace.Strings;
with Pace.Log;
with Pace.Server.Xml;

package body Sim.Inventory is

   use Str.Bstr;

   function Local_Hash (Key : Bounded_String) return Ada.Containers.Hash_Type is
   begin
      return Pace.Strings.Hash (Key);
   end Local_Hash;

   Total_Box_Count : Natural := 0;

   package Box_Count_Pkg is
     new Ada.Containers.Hashed_Maps (Key_Type => Bounded_String,
                                     Element_Type => Natural,
                                     Hash => Local_Hash,
                                     Equivalent_Keys => "=");
   use Box_Count_Pkg;
   Box_Map : Box_Count_Pkg.Map;

   -- since there are only 2 bottle types no need for a map.. just use Naturals (0 and up)
   Half_Count : Natural := 0; --!!!
   Full_Count : Natural := 0;

   procedure Add_Boxs (Box_Kind : Bstr.Bounded_String;
                              Num : Positive;
                              Success : out Boolean) is
      Current_Num : Natural;
   begin
      if Total_Box_Count + Num > Max_Boxs then
         Success := False;
      else
         if Contains (Box_Map, Box_Kind) then
            Current_Num := Element (Box_Map, Box_Kind);
         else
            Current_Num := 0;
         end if;
         Include (Box_Map, Box_Kind, Current_Num + Num);
         Success := True;
         Total_Box_Count := Total_Box_Count + Num;

         declare
            Msg : Update_Inventory;
         begin
            Msg.Inventory_Xml := Asu.To_Unbounded_String (Get_Inventory_Xml);
            Msg.Ack := False;
            Pace.Dispatching.Input (Msg);
         end;

      end if;
   end Add_Boxs;

   function Is_Onboard (Box_Kind : Bstr.Bounded_String; Num : Positive) return Boolean is
      Current_Num : Natural;
      Result : Boolean := False;
   begin
      if Contains (Box_Map, Box_Kind) then
         Current_Num := Element (Box_Map, Box_Kind);
         if Num <= Current_Num then
            Result := True;
         end if;
      end if;
      return Result;
   end Is_Onboard;

   function Get_Num (Box_Kind : Bstr.Bounded_String) return Natural is
      Result : Natural;
   begin
      if Contains (Box_Map, Box_Kind) then
         Result := Element (Box_Map, Box_Kind);
      else
         Result := 0;
      end if;
      return Result;
   end Get_Num;

   procedure Remove_Box (Box_Kind : Bstr.Bounded_String; Num_To_Remove : Positive := 1) is
      Current_Num : Natural;
   begin
      if Contains (Box_Map, Box_Kind) then
         Current_Num := Element (Box_Map, Box_Kind);
         if Current_Num - Num_To_Remove < 0 then
            -- remove all that remains of box_kind
            Include (Box_Map, Box_Kind, 0);
            Total_Box_Count := Total_Box_Count - Current_Num;
         else
            -- remove num_to_remove of box_kind
            Include (Box_Map, Box_Kind, Current_Num - Num_To_Remove);
            Total_Box_Count := Total_Box_Count - Num_To_Remove;
         end if;
         declare
            Msg : Update_Inventory;
         begin
            Msg.Inventory_Xml := Asu.To_Unbounded_String (Get_Inventory_Xml);
            Msg.Ack := False;
            Pace.Dispatching.Input (Msg);
         end;
      end if;
   end Remove_Box;


   procedure Add_Bottle (Bottle_Kind : Bottle_Type;
                             Num : Positive;
                             Success : out Boolean) is
   begin
      if Half_Count + Full_Count + Num > Max_Charges then
         Success := False;
      else
         if Bottle_Kind = Half then
            Half_Count := Half_Count + Num;
         else
            Full_Count := Full_Count + Num;
         end if;
         Success := True;
         declare
            Msg : Update_Inventory;
         begin
            Msg.Inventory_Xml := Asu.To_Unbounded_String (Get_Inventory_Xml);
            Msg.Ack := False;
            Pace.Dispatching.Input (Msg);
         end;
      end if;
   end Add_Bottle;

   function Is_Onboard (Bottle_Kind : Bottle_Type; Num : Positive) return Boolean is
   begin
      if Bottle_Kind = Half then
         if Num <= Half_Count then
            return True;
         else
            return False;
         end if;
      else
         if Num <= Full_Count then
            return True;
         else
            return False;
         end if;
      end if;
   end Is_Onboard;

   function Get_Num_Half return Natural is
   begin
      return Half_Count;
   end Get_Num_Half;

   function Get_Num_Full return Natural is
   begin
      return Full_Count;
   end Get_Num_Full;

   procedure Remove_Bottle (Bottle_Kind : Bottle_Type; Num : Positive) is
   begin
      if Bottle_Kind = Half then
         Half_Count := Half_Count - Num;
      else
         Full_Count := Full_Count - Num;
      end if;
      declare
         Msg : Update_Inventory;
      begin
         Msg.Inventory_Xml := Asu.To_Unbounded_String (Get_Inventory_Xml);
         Msg.Ack := False;
         Pace.Dispatching.Input (Msg);
      end;
   end Remove_Bottle;

   procedure Clear_Inventory is
   begin
      Half_Count := 0;
      Full_Count := 0;
      Total_Box_Count := 0;
      Clear (Box_Map);
   end Clear_Inventory;

   function Get_Launchpad_Velocity (Box_Type : String; Power_Level : Plant.Charge_Range) return Float is
      use Vkb.Rules;
      V : Variables (1 .. 3);
      Result : Float;
   begin
      V (1) := S2u (Q (Box_Type));
      V (2) := S2u (S (Power_Level));
      Vkb.Agent.Query ("box_bottle_velocity", V);
      Result := Float'Value (U2s (V (3)));
      return Result;
   end Get_Launchpad_Velocity;

   function Get_Inventory_Xml return String is
      use Asu;
      use Pace.Server.Xml;
      Result : Asu.Unbounded_String;
      Box_list : Asu.Unbounded_String;
      Iter : Cursor := First (Box_Map);
   begin
      while Has_Element (Iter) loop
         Append (Box_List, Item ("box",
                               Item ("type", +(Key (Iter))) &
                               Item ("num", Trim (Element (Iter)))));
         Iter := Next (Iter);
      end loop;
      Result := Item (Asu.To_Unbounded_String ("box_list"), Box_List);
      Append (Result, Item ("bottle_list", Item ("bottle",
                                               Item ("type", "Half") &
                                               Item ("num", Trim (Half_Count))) &
                                               Item ("bottle",
                                               Item ("type", "Full") &
                                               Item ("num", Trim (Full_Count)))
                            ));


      return Item ("inventory", Asu.To_String (Result));
   end Get_Inventory_Xml;

   Success : Boolean;
   procedure Check_Success (Success : Boolean) is
   begin
      if not Success then
         Pace.Log.Put_Line ("!!!!!!!!Inventory Initialization failed!!!!!!!!!!!!!!!!!");
      end if;
   end Check_Success;
begin
   -- initialize the inventory.. eventually should be a method call
   declare
      use Sim.Inventory;
   begin
      Sim.Inventory.Add_Bottle (Half, 32, Success);
      Sim.Inventory.Add_Bottle (Full, 64, Success);
      Sim.Inventory.Add_Boxs (+"ABCD", 16, Success);
      Sim.Inventory.Add_Boxs (+"A1", 8, Success);
   end;
end Sim.Inventory;

