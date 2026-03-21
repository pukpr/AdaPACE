with Ada.Characters.Handling;
with Pace.Strings;
with Gnu.Xml_Tree;
with Pace.Log;
with Pace.Semaphore;
with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Vkb;

package body Plant.Inventory is

   use Pace.Server;

   Mutex : aliased Pace.Semaphore.Mutex;

   function Is_Tube_Filled (Depth : in Integer; Max_Depth : in N_Tube_Depth)
                           return Boolean is
   begin
      return Depth >= Max_Depth;
   end Is_Tube_Filled;

   function Get_Kb (Q : in String; Id : in Integer) return String is
      use Vkb.Rules;
      V : Variables (1 .. 2);
   begin
      V (1) := +S (Id);
      Vkb.Agent.Query (Q, V);
      return +V (2);
   end Get_Kb;

   Xml_Timer : constant String := "timer";
   Xml_Name : constant String := "name";
   Xml_Bottle_Lot : constant String := "bottle_lot";
   Xml_Bottle_Short_Lot : constant String := "bottle_short_lot";
   Xml_Box_Lot : constant String := "box_lot";
   Xml_Box_Short_Lot : constant String := "box_short_lot";
   Xml_Timer_Lot : constant String := "timer_lot";
   Xml_Timer_Short_Lot : constant String := "timer_short_lot";

   Item : Integer := 0;

   function To_Ustr (S : in String) return Ustring renames To_Unbounded_String;

   function Get_Box_Assembly (I : in Box_Inventory_Type;
                                Mags : in Integer;
                                Slots : in Integer) return Ustring is
   begin
      return I.Mag (Mags).Slot (Slots).Box.Assembly_Name;
   end Get_Box_Assembly;

   function Get_Box_Count (I : in Box_Inventory_Type) return Integer is
   begin
      return I.Box_Count;
   end Get_Box_Count;

   function Get_Bottle_Count (I : in Bottle_Inventory_Type) return Integer is
   begin
      return I.Bottle_Count;
   end Get_Bottle_Count;

   function Get_Box_Assembly
              (I : in Box_Inventory_Type; Number : in Integer)
              return Ustring is
      Mags : Integer;
      Slot : Integer;
   begin
      Mags := (Number - 1) mod N_Box_Mags'Last + 1;
      Slot := (Number - 1) / N_Box_Mags'Last + 1;
      return I.Mag (Mags).Slot (Slot).Box.Assembly_Name;
   end Get_Box_Assembly;

   function Slide_Slot
              (New_Slot : in Integer; Max : in Integer) return Integer is
   begin
      if New_Slot > Max then
         return New_Slot - Max;
      else
         return New_Slot;
      end if;
   end Slide_Slot;

   procedure Copy_Slots (From : in Box_Inventory_Type;
                         To : in out Box_Inventory_Type) is
   begin
      for Mags in From.Mag'Range loop
         for Slots in From.Mag (Mags).Slot'Range loop
            To.Mag (Mags).Slot (Slots) := From.Mag (Mags).Slot (Slots);
         end loop;
      end loop;
   end Copy_Slots;


   --------------------
   -- Add_Box --
   --------------------

   procedure Add_Box (I : in out Box_Inventory_Type;
                             I_Temp : in out Box_Inventory_Type;
                             Amt : in Integer := 1) is
      L : Pace.Semaphore.Lock (Mutex'Access);
      Number_Added : Integer := 0;
      The_Slot : Integer;
      Max : Integer;
   begin
      Copy_Slots (I, I_Temp);
      for Mags in I.Mag'Range loop
         Max := I.Mag (Mags).Slot'Last;
         for Slots in I.Mag (Mags).Slot'Range loop
            if I.Mag (Mags).Slot (Slots).Empty then
               declare
                  P : Box_Type
                    renames I.Mag (Mags).Slot (Slots).Box;
               begin
                  P.Name := Default_Box;
                  P.Timer := Default_Timer;
                  P.Box_Lot := Default_Box_Lot;
                  P.Box_Short_Lot := Default_Box_Short_Lot;
                  P.Timer_Lot := Default_Timer_Lot;
                  P.Timer_Short_Lot := Default_Timer_Short_Lot;
               end;
               I.Mag (Mags).Slot (Slots).Empty := False;
               Number_Added := Number_Added + 1;
               I.Box_Count := I.Box_Count + 1;
               Pace.Log.Put_Line ("Added box to " & N_Id'Image (I.Id) &
                                  Integer'Image (Mags) & Integer'Image (Slots));
               if Number_Added = Amt then
                  -- update the slot positions for each cell
                  The_Slot := Slots;
                  for S in I.Mag (Mags).Slot'Range loop
                     I_Temp.Mag (Mags).Slot (S) :=
                       I.Mag (Mags).Slot (Slide_Slot (S + The_Slot - 1, Max));
                     I_Temp.Mag (Mags).Slot (S).Box.At_Gate := False;
                  end loop;
                  Copy_Slots (I_Temp, I);
                  I.Mag (Mags).Slot (1).Box.At_Gate := True;
                  return;
               end if;
            end if;
         end loop;
      end loop;
      if Number_Added < Amt then
         Pace.Log.Put_Line ("Cannot add any more boxs to " &
                            N_Id'Image (I.Id));
      end if;
--      end;
   exception
      when E: others =>
         Pace.Log.Ex (E, "Add Box to plant");
   end Add_Box;

   --------------------
   -- Add_Bottle --
   --------------------

   procedure Add_Bottle (I : in out Bottle_Inventory_Type;
                             Amt : in Integer := 1) is
      L : Pace.Semaphore.Lock (Mutex'Access);
      Number_Added : Integer := 0;
   begin
      for Mags in I.Mag'Range loop
         for Tubes in I.Mag (Mags).Tube'Range loop
            declare
               P : Bottle_Type;
               T : Tube_Stack.Vector
                 renames I.Inv.Self.Mag (Mags).Tube (Tubes).Stack;
               use Tube_Stack;
            begin
               while not Is_Tube_Filled (Integer (T.Length), I.Depth) loop
                  P.Name := Default_Bottle;
                  P.Bottle_Lot := Default_Bottle_Lot;
                  P.Bottle_Short_Lot := Default_Bottle_Short_Lot;
                  T.Prepend (P);
                  Number_Added := Number_Added + 1;
                  I.Bottle_Count := I.Bottle_Count + 1;
                  Pace.Log.Put_Line ("Added charge to " & N_Id'Image (I.Id) &
                                     Integer'Image (Mags) &
                                     Integer'Image (Tubes));
                  if Number_Added = Amt then
                     return;
                  end if;
               end loop;
            end;
         end loop;
      end loop;
      if Number_Added < Amt then
         Pace.Log.Put_Line ("Cannot add any more charges to " &
                            N_Id'Image (I.Id));
      end if;
   end Add_Bottle;


   function Get_Cell_Xml (P : Box_Type) return String is
      Str : String := Xml.Item (Element => Xml_Name,
                                Value => To_String (P.Name)) &
                      Xml.Item (Element => Xml_Timer,
                                Value => To_String (P.Timer)) &
                      Xml.Item (Element => "location",
                                Value => Location'Image (P.At_Location)) &
                      Xml.Item (Element => "state",
                                Value => State'Image (P.At_State)) &
                      Xml.Item (Element => "gate",
                                Value => Boolean'Image (P.At_Gate)) &
                      Xml.Item (Element => "temperature",
                                Value => P.Temperature) &
                      Xml.Item (Element => Xml_Box_Lot,
                                Value => To_String (P.Box_Lot)) &
                      Xml.Item (Element => Xml_Box_Short_Lot,
                                Value => To_String (P.Box_Short_Lot)) &
                      Xml.Item (Element => Xml_Timer_Lot,
                                Value => To_String (P.Timer_Lot)) &
                      Xml.Item (Element => Xml_Timer_Short_Lot,
                                Value => To_String (P.Timer_Short_Lot)) &
                      Xml.Item (Element => "load_number",
                                Value => P.Load_Number) &
                      Xml.Item (Element => "load_index", Value => P.Load_Index);
   begin
      return Str;
   end Get_Cell_Xml;

   function Get_Slot_Xml (P : Box_Type) return String is
   begin
      -- return an empty string when the slot doesn't have a cell in it
      if P.Name = "" then
         return "";
      else
         return (Xml.Item (Element => "cell",
                           Value => Get_Cell_Xml (P),
                           Attribute => Xml.Pair ("index", P.Cell)));
      end if;
   end Get_Slot_Xml;

   function Get_Mag_Xml (Mag_Num : Integer; I : Box_Inventory_Type)
                        return String is
      Str : Ustring;
   begin
      for Slot_Num in I.Mag (Mag_Num).Slot'Range loop
         Append (Str, Xml.Item (Element => "slot",
                                Value => Get_Slot_Xml
                                           (I.Mag (Mag_Num).Slot (Slot_Num).
                                            Box),
                                Attribute => Xml.Pair ("index", Slot_Num)));

      end loop;
      return Ada.Strings.Unbounded.To_String (Str);
   end Get_Mag_Xml;

   function Get_All_Mags_Xml (I : Box_Inventory_Type) return String is
      Str : Ustring;
   begin
      for Mag_Num in I.Mag'Range loop
         Append (Str, Xml.Item (Element => "mag",
                                Value => Get_Mag_Xml (Mag_Num, I),
                                Attribute => Xml.Pair ("index", Mag_Num)));
      end loop;
      return Ada.Strings.Unbounded.To_String (Str);
   end Get_All_Mags_Xml;

   ----------------------------------
   -- Current_Box_Inventory --
   ----------------------------------

   function Current_Box_Inventory
              (I : in Box_Inventory_Type) return String is
      L : Pace.Semaphore.Lock (Mutex'Access);
      Str : Unbounded_String;
   begin
      Str := To_Ustr (Xml.Item
                        (Element => "box_inventory",
                         Value => Get_All_Mags_Xml (I),
                         Attribute => Xml.Pair ("vehicle", N_Id'Image (I.Id))));

      Str := Xml.Begin_Doc & Str & Xml.End_Doc;
      return Ada.Strings.Unbounded.To_String (Str);
   end Current_Box_Inventory;


   -- returns XML for a single cell
   function Get_Slot_Xml (I : in Box_Inventory_Type;
                          Mag_Num : Integer;
                          Slot_Num : Integer) return String is
      Str : String := Get_Slot_Xml (I.Mag (Mag_Num).Slot (Slot_Num).Box);
   begin
      return Xml.Begin_Doc & Str & Xml.End_Doc;
   end Get_Slot_Xml;


   procedure Initialize (I : in out Box_Inventory_Type) is
      L : Pace.Semaphore.Lock (Mutex'Access);
      Vehicle : constant String :=
        Ada.Characters.Handling.To_Lower (N_Id'Image (I.Id));
      Id : Integer := 0;
   begin
      case I.Id is
         when Fore =>
            null;
         when Aft | Transfer =>
            I.Mag (1).Slot (1).Box.Assembly_Name := To_Ustr ("Box1");
         when others =>
            Pace.Log.Put_Line ("unknown vehicle");
            return;
      end case;
      for Mags in I.Mag'Range loop
         for Slots in I.Mag (Mags).Slot'Range loop
            Id := Id + 1; -- assuming starting at 1
            declare
               P : Box_Type renames I.Mag (Mags).Slot (Slots).Box;
            begin
               if I.Id = Fore then
                  P.At_Location := On_Fore;
               else
                  P.At_Location := On_Aft;
               end if;
               P.At_State := Stored;
               P.Compartment := Mags;
               P.Slot := Slots;
               P.Cell := Slots;
               P.At_Gate := Slots = 1;
               declare
                  use Pace.Strings;
                  Data : constant String := Get_Kb ("initial_box", Id);
               begin
                  P.Name := To_Ustr (Select_Field (Data, 1));
                  P.Box_Lot := To_Ustr (Select_Field (Data, 2));
                  P.Box_Short_Lot := To_Ustr (Select_Field (Data, 3));
                  P.Timer := To_Ustr (Select_Field (Data, 4));
                  P.Timer_Lot := To_Ustr (Select_Field (Data, 5));
                  P.Timer_Short_Lot := To_Ustr (Select_Field (Data, 6));
               end;
               I.Mag (Mags).Slot (Slots).Empty := False;
               I.Box_Count := I.Box_Count + 1;
               P.Temperature := 21.0;
               P.Load_Number := 1;
               P.Load_Index := Integer (Slots);
            exception
               when Vkb.Rules.No_Match =>
                  Pace.Log.Put_Line (Vehicle & " slot empty #" &
                                     Integer'Image (Id));
            end;
         end loop;
      end loop;
   end Initialize;


   function Get_Charge_Xml (Charge : Bottle_Type) return String is
      Str : String := Xml.Item (Element => Xml_Name,
                                Value => To_String (Charge.Name)) &
                      Xml.Item (Element => "location",
                                Value => Location'Image (Charge.At_Location)) &
                      Xml.Item (Element => "state",
                                Value => State'Image (Charge.At_State)) &
                      Xml.Item (Element => "temperature",
                                Value => Charge.Temperature) &
                      Xml.Item (Element => Xml_Bottle_Lot,
                                Value => To_String (Charge.Bottle_Lot)) &
                      Xml.Item (Element => Xml_Bottle_Short_Lot,
                                Value => To_String (Charge.Bottle_Short_Lot)) &
                      Xml.Item (Element => "load_number",
                                Value => Charge.Load_Number) &
                      Xml.Item (Element => "load_index",
                                Value => Charge.Load_Index);
   begin
      return Str;
   end Get_Charge_Xml;


   function Get_Tube_Xml (T : Tube_Stack.Vector) return String is
      Str : Ustring;
   begin
      Append (Str, Xml.Item (Element => "tube_depth",
                             Value => Integer (T.Length)));
      for Charge_Num in 1 .. Integer (T.Length) loop
         -- the name will be an empty string when there is no charge
         if To_Str (Tube_Stack.Element (T, Charge_Num).Name) /= "" then
            Append (Str, Xml.Item
                           (Element => "charge",
                            Value => Get_Charge_Xml
                                       (Tube_Stack.Element (T, Charge_Num)),
                            Attribute => Xml.Pair ("index", Charge_Num)));
         end if;
      end loop;
      return Ada.Strings.Unbounded.To_String (Str);
   end Get_Tube_Xml;

   function Get_Mag_Bottle_Xml (Mag_Num : Integer; I : Bottle_Inventory_Type)
                             return String is
      Str : Ustring;
   begin
      for Tube_Num in I.Mag (Mag_Num).Tube'Range loop
         declare
            T : Tube_Stack.Vector
              renames I.Inv.Self.Mag (Mag_Num).Tube (Tube_Num).Stack;
            use Tube_Stack;
         begin
            Append (Str, Xml.Item (Element => "tube",
                                   Value => Get_Tube_Xml (T),
                                   Attribute => Xml.Pair ("index", Tube_Num)));
         end;
      end loop;
      return Ada.Strings.Unbounded.To_String (Str);
   end Get_Mag_Bottle_Xml;


   function Get_All_Mags_Bottle_Xml
              (I : in Bottle_Inventory_Type) return String is
      Str : Ustring;
   begin
      for Mag_Num in I.Mag'Range loop
         Append (Str, Xml.Item (Element => "mag",
                                Value => Get_Mag_Bottle_Xml (Mag_Num, I),
                                Attribute => Xml.Pair ("index", Mag_Num)));
      end loop;
      return Ada.Strings.Unbounded.To_String (Str);
   end Get_All_Mags_Bottle_Xml;

   ----------------------------------
   -- Current_Bottle_Inventory --
   ----------------------------------

   function Current_Bottle_Inventory
              (I : in Bottle_Inventory_Type) return String is
      L : Pace.Semaphore.Lock (Mutex'Access);
      Str : Unbounded_String;
   begin
      Str := To_Ustr (Xml.Item
                        (Element => "bottle_inventory",
                         Value => Get_All_Mags_Bottle_Xml (I),
                         Attribute => Xml.Pair ("vehicle", N_Id'Image (I.Id))));
      Str := Xml.Begin_Doc & Str & Xml.End_Doc;
      return Ada.Strings.Unbounded.To_String (Str);
   end Current_Bottle_Inventory;

   function Get_One_Charge_Xml (I : in Bottle_Inventory_Type;
                                Mag_Num : Integer;
                                Tube_Num : Integer;
                                Charge_Num : Integer) return String is
      Str : String :=
        Xml.Item (Element => "charge",
                  Value => Get_Charge_Xml
                             (Tube_Stack.Element
                                (I.Inv.Self.Mag (Mag_Num).Tube (Tube_Num).Stack,
                                 Charge_Num)),
                  Attribute => Xml.Pair ("index", Charge_Num));
   begin
      return Str;
   end Get_One_Charge_Xml;

   -- returns XML for a single charge
   function Get_Charge_Xml (I : in Bottle_Inventory_Type;
                            Mag_Num : Integer;
                            Tube_Num : Integer;
                            Charge_Num : Integer) return String is
      Str : String := Xml.Item (Element => "tube",
                                Value => Get_One_Charge_Xml
                                           (I, Mag_Num, Tube_Num, Charge_Num),
                                Attribute => Xml.Pair ("index", Tube_Num));
   begin
      return Xml.Begin_Doc & Str & Xml.End_Doc;
   end Get_Charge_Xml;


   -----------------------
   -- Remove_Box --
   -----------------------

   procedure Remove_Box (I : in out Box_Inventory_Type;
                                I_Temp : in out Box_Inventory_Type;
                                Amt : in Integer := 1) is
      L : Pace.Semaphore.Lock (Mutex'Access);
      Number_Removed : Integer := 0;
      The_Slot : Integer;
      Max : Integer;
   begin
--      declare
--          I_Temp : Box_Inventory_Type (I.Id, I.Mags, I.Slots);
--      begin
      Copy_Slots (I, I_Temp);
      for Mags in I.Mag'Range loop
         Max := I.Mag (Mags).Slot'Last;
         for Slots in I.Mag (Mags).Slot'Range loop
            if not I.Mag (Mags).Slot (Slots).Empty then
               I.Mag (Mags).Slot (Slots).Empty := True;
               Number_Removed := Number_Removed + 1;
               I.Box_Count := I.Box_Count - 1;
               Pace.Log.Put_Line ("Removed box from " & N_Id'Image (I.Id) &
                                  Integer'Image (Mags) & Integer'Image (Slots));
               if Number_Removed = Amt then
                  The_Slot := Slots;
                  for S in I.Mag (Mags).Slot'Range loop
                     I_Temp.Mag (Mags).Slot (S) :=
                       I.Mag (Mags).Slot (Slide_Slot (S + The_Slot - 1, Max));
                     I_Temp.Mag (Mags).Slot (S).Box.At_Gate := False;
                  end loop;
                  Copy_Slots (I_Temp, I);
                  I.Mag (Mags).Slot (1).Box.At_Gate := True;
                  return;
               end if;
            end if;
         end loop;
      end loop;
      if Number_Removed < Amt then
         Pace.Log.Put_Line ("Cannot remove any more boxs from " &
                            N_Id'Image (I.Id));
      end if;
--      end;
   exception
      when E: others =>
         Pace.Log.Ex (E, "Remove Box from plant");
   end Remove_Box;

   -----------------------
   -- Remove_Bottle --
   -----------------------

   procedure Remove_Bottle
               (I : in out Bottle_Inventory_Type; Amt : in Integer := 1) is
      L : Pace.Semaphore.Lock (Mutex'Access);
      Number_Removed : Integer := 0;
   begin
      for Mags in I.Mag'Range loop
         for Tubes in I.Mag (Mags).Tube'Range loop
            declare
               T : Tube_Stack.Vector
                 renames I.Inv.Self.Mag (Mags).Tube (Tubes).Stack;
               use Tube_Stack;
            begin
               while not T.Is_Empty loop
                  T.Delete_First;
                  Number_Removed := Number_Removed + 1;
                  I.Bottle_Count := I.Bottle_Count - 1;
                  Pace.Log.Put_Line ("Removed charge from " &
                                     N_Id'Image (I.Id) & Integer'Image (Mags) &
                                     Integer'Image (Tubes));
                  if Number_Removed = Amt then
                     return;
                  end if;
               end loop;
            end;
         end loop;
      end loop;
      if Number_Removed < Amt then
         Pace.Log.Put_Line ("Cannot remove any more charges from " &
                            N_Id'Image (I.Id));
      end if;
   end Remove_Bottle;

   procedure Initialize (I : in out Bottle_Inventory_Type) is
      L : Pace.Semaphore.Lock (Mutex'Access);
      Vehicle : constant String :=
        Ada.Characters.Handling.To_Lower (N_Id'Image (I.Id));
      Id : Integer := 0;
      D : Integer;
   begin
      for Mags in I.Mag'Range loop
         for Tubes in I.Mag (Mags).Tube'Range loop
            Id := Id + 1; -- assuming starting at 1
            declare
               P : Bottle_Type;
               Tube : Tube_Stack.Vector
                 renames I.Mag (Mags).Tube (Tubes).Stack;
               use Tube_Stack;
            begin
               declare
                  use Pace.Strings;
                  Data : constant String := Get_Kb ("initial_bottle", Id);
               begin
                  D := Integer'Value (Select_Field (Data, 4));
                  for I in 1 .. D loop
                     P.Name := To_Ustr (Select_Field (Data, 1));
                     P.Bottle_Lot := To_Ustr (Select_Field (Data, 2));
                     P.Bottle_Short_Lot := To_Ustr (Select_Field (Data, 3));
                     if Initialize.I.Id = Fore then
                        P.At_Location := On_Fore;
                     else
                        P.At_Location := On_Aft;
                     end if;
                     P.At_State := Stored;
                     P.Compartment := Mags;
                     P.Temperature := 21.0;
                     P.Load_Number := 1;
                     P.Load_Index := Integer (Tubes);
                     Tube.Prepend (P);
                  end loop;
               end;
               I.Bottle_Count := I.Bottle_Count + 1;
               I.Mag (Mags).Tube (Tubes).Filled :=
                 Is_Tube_Filled (Integer (Tube.Length), I.Depth);
            exception
               when Vkb.Rules.No_Match =>
                  Pace.Log.Put_Line (Vehicle & " tube empty #" &
                                     Integer'Image (Id));
            end;
         end loop;
      end loop;
   end Initialize;


   The_Default_Box : Unbounded_String := To_Ustr ("M107");
   The_Default_Box_Lot : Unbounded_String := To_Ustr ("MA-94F002S483");
   The_Default_Box_Short_Lot : Unbounded_String := To_Ustr ("M");
   The_Default_Timer : Unbounded_String := To_Ustr ("M739A1");
   The_Default_Timer_Lot : Unbounded_String := To_Ustr ("FG-3428FS3FD3");
   The_Default_Timer_Short_Lot : Unbounded_String := To_Ustr ("F");
   The_Default_Bottle : Unbounded_String := To_Ustr ("XM231");
   The_Default_Bottle_Lot : Unbounded_String := To_Ustr ("XY-212M892590");
   The_Default_Bottle_Short_Lot : Unbounded_String := To_Ustr ("X");

   function Default_Box return Unbounded_String is
   begin
      return The_Default_Box;
   end Default_Box;

   function Default_Timer return Unbounded_String is
   begin
      return The_Default_Timer;
   end Default_Timer;

   function Default_Box_Lot return Unbounded_String is
   begin
      return The_Default_Box_Lot;
   end Default_Box_Lot;

   function Default_Box_Short_Lot return Unbounded_String is
   begin
      return The_Default_Box_Short_Lot;
   end Default_Box_Short_Lot;

   function Default_Timer_Lot return Unbounded_String is
   begin
      return The_Default_Timer_Lot;
   end Default_Timer_Lot;

   function Default_Timer_Short_Lot return Unbounded_String is
   begin
      return The_Default_Timer_Short_Lot;
   end Default_Timer_Short_Lot;

   function Default_Bottle return Unbounded_String is
   begin
      return The_Default_Bottle;
   end Default_Bottle;

   function Default_Bottle_Lot return Unbounded_String is
   begin
      return The_Default_Bottle_Lot;
   end Default_Bottle_Lot;


   function Default_Bottle_Short_Lot return Unbounded_String is
   begin
      return The_Default_Bottle_Short_Lot;
   end Default_Bottle_Short_Lot;


-- EXAMPLE
--    <box>
--     <timer>ak</timer>
--     <name>alla</name>
--     <lot>qqqq</lot>
--     <short_lot>akak</short_lot>
--    </box>

   type Xml_Tree is new Gnu.Xml_Tree.Tree with null record;
   procedure Callback (T : in out Xml_Tree; Tag, Value, Attributes : in String);

   Box : Boolean := False;

   procedure Callback (T : in out Xml_Tree;
                       Tag, Value, Attributes : in String) is
      Element : Unbounded_String := To_Ustr (Value);
   begin
      Pace.Log.Put_Line ("[xml] " & Tag & " : " & Value & " : " & Attributes);
      if Tag = "box" then
         Box := True;
      elsif Tag = Xml_Timer then
         The_Default_Timer := Element;
      elsif Tag = Xml_Name then
         if Box then
            The_Default_Box := Element;
         else
            The_Default_Bottle := Element;
         end if;
      elsif Tag = Xml_Box_Lot then
         The_Default_Box_Lot := Element;
      elsif Tag = Xml_Box_Short_Lot then
         The_Default_Box_Short_Lot := Element;
      elsif Tag = Xml_Timer_Lot then
         The_Default_Timer_Lot := Element;
      elsif Tag = Xml_Timer_Short_Lot then
         The_Default_Timer_Short_Lot := Element;
      elsif Tag = Xml_Bottle_Lot then
         The_Default_Bottle_Lot := Element;
      elsif Tag = Xml_Bottle_Short_Lot then
         The_Default_Bottle_Short_Lot := Element;
      else
         Pace.Log.Put_Line ("Unused XML tag => " & Tag);
      end if;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Callback;

   procedure Set_Default_Inventory (Default : in String) is
      L : Pace.Semaphore.Lock (Mutex'Access);
      Root : Xml_Tree;
   begin
      Box := False;
      Pace.Log.Put_Line ("Inventory " & Default);
      Parse (Default, Root);
      -- Xml.Print (Root);
      Search (Root);
   end Set_Default_Inventory;


------------------------------------------------------------------------------
-- $id: plant-inventory.adb,v 1.4 01/15/2003 19:30:41 ludwiglj Exp $
------------------------------------------------------------------------------
end Plant.Inventory;

