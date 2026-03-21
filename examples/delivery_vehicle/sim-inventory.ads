with Str;
with Pace.Notify;
with Ada.Strings.Unbounded;
with Plant;

package Sim.Inventory is

   pragma Elaborate_Body;

   use Str;

   package Asu renames Ada.Strings.Unbounded;

   Max_Boxs : constant Integer := 24;
   Max_Charges : constant Integer := 96;

   type Bottle_Type is (Half, Full);

   -- If operation succeeded Success will be true, but if there isn't room
   -- for Num more boxs then Success will be false
   procedure Add_Boxs (Box_Kind : Bstr.Bounded_String;
                              Num : Positive;
                              Success : out Boolean);

   -- returns true if there are Num boxs of type Box_Kind available and
   -- false if there isn't
   function Is_Onboard (Box_Kind : Bstr.Bounded_String; Num : Positive) return Boolean;

   function Get_Num (Box_Kind : Bstr.Bounded_String) return Natural;

   -- Use in conjunction with Is_Onboard to ensure there are Num amount of Box_Kind
   -- to remove.
   procedure Remove_Box (Box_Kind : Bstr.Bounded_String; Num_To_Remove : Positive := 1);




   -- If operation succeeded Success will be true, but if there isn't room
   -- for Num more charge canisters then Success will be false
   procedure Add_Bottle (Bottle_Kind : Bottle_Type;
                             Num : Positive;
                             Success : out Boolean);

   -- returns true if there are Num charge canisters of type Bottle_Kind available and
   -- false if there isn't
   function Is_Onboard (Bottle_Kind : Bottle_Type; Num : Positive) return Boolean;

   function Get_Num_Half return Natural;

   function Get_Num_Full return Natural;

   procedure Remove_Bottle (Bottle_Kind : Bottle_Type; Num : Positive);

   -- removes all bottles and boxs
   procedure Clear_Inventory;

   -- returns the current inventory as xml
   function Get_Inventory_Xml return String;

   -- this notify will be triggered anytime the inventory changes
   type Update_Inventory is new Pace.Notify.Subscription with
      record
         Inventory_Xml : Asu.Unbounded_String;
      end record;

   function Get_Launchpad_Velocity (Box_Type : String; Power_Level : Plant.Charge_Range) return Float;

end Sim.Inventory;
