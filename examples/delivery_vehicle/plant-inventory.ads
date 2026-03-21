with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Plant.Inventory is
   pragma Elaborate_Body;

   type N_Id is (Fore, Aft, Transfer, Any);
   subtype N_Box_Mags is Integer range 0 .. 5;
   subtype N_Box_Slots is Integer range 0 .. 30;
   subtype N_Bottle_Mags is Integer range 0 .. 2;
   subtype N_Bottle_Tubes is Integer range 0 .. 13;
   subtype N_Tube_Depth is Integer range 0 .. 20;

   subtype Ustring is Ada.Strings.Unbounded.Unbounded_String;

   ------------------------------------------------------
   -- Abstract COMPONENT
   type Component_Type is abstract tagged limited private;

   ------------------------------------------------------
   -- BOX CELL
   --   State (Empty, Filled)
   --   Box_Type

   -- BOTTLE CELL
   --   Number filled (1..20)
   --   Filled (boolean)
   --   Stack of Bottle_Type

   type Box_Cell_Type (Id : N_Id) is new Component_Type with private;
   type Bottle_Cell_Type (Id : N_Id; Depth : N_Tube_Depth) is
     new Component_Type with private;

   ------------------------------------------------------
   -- BOX COMPARTMENT   Array (<>) of BOX CELL

   -- BOTTLE COMPARTMENT    Array (<>) of BOTTLE CELL

   type Box_Compartment_Type (Id : N_Id; Slots : N_Box_Slots) is
     new Component_Type with private;
   type Bottle_Compartment_Type
          (Id : N_Id; Tubes : N_Bottle_Tubes; Depth : N_Tube_Depth) is
     new Component_Type with private;

   ------------------------------------------------------
   -- BOX INVENTORY
   --   Array (1..5) of BOX COMPARTMENT

   -- BOTTLE INVENTORY
   --   Array (1..5) of BOTTLE COMPARTMENT

   type Box_Inventory_Type
          (Id : N_Id; Mags : N_Box_Mags; Slots : N_Box_Slots) is
     new Component_Type with private;
   type Bottle_Inventory_Type (Id : N_Id;
                                   Mags : N_Bottle_Mags;
                                   Tubes : N_Bottle_Tubes;
                                   Depth : N_Tube_Depth) is
     new Component_Type with private;


   function Get_Slot_Xml (I : in Box_Inventory_Type;
                          Mag_Num : Integer;
                          Slot_Num : Integer) return String; -- XML
   function Current_Box_Inventory
              (I : in Box_Inventory_Type) return String; -- XML
   function Get_Box_Count (I : in Box_Inventory_Type) return Integer;
   procedure Add_Box (I : in out Box_Inventory_Type;
                             I_Temp : in out Box_Inventory_Type;
                             Amt : in Integer := 1);
   procedure Remove_Box (I : in out Box_Inventory_Type;
                                I_Temp : in out Box_Inventory_Type;
                                Amt : in Integer := 1);
   procedure Initialize (I : in out Box_Inventory_Type);

   function Get_Charge_Xml (I : in Bottle_Inventory_Type;
                            Mag_Num : Integer;
                            Tube_Num : Integer;
                            Charge_Num : Integer) return String; -- XML
   function Current_Bottle_Inventory
              (I : in Bottle_Inventory_Type) return String; -- XML
   function Get_Bottle_Count (I : in Bottle_Inventory_Type) return Integer;
   procedure Add_Bottle
               (I : in out Bottle_Inventory_Type; Amt : in Integer := 1);
   procedure Remove_Bottle
               (I : in out Bottle_Inventory_Type; Amt : in Integer := 1);
   procedure Initialize (I : in out Bottle_Inventory_Type);

   function To_Str (U : in Ustring) return String
     renames Ada.Strings.Unbounded.To_String;
   function To_Ustr (S : in String) return Ustring;


   procedure Set_Default_Inventory (Default : in String); -- XML

   function Get_Box_Assembly (I : in Box_Inventory_Type;
                                Mags : in Integer;
                                Slots : in Integer) return Ustring;

   function Get_Box_Assembly
              (I : in Box_Inventory_Type; Number : in Integer)
              return Ustring;

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

private

   use Ada.Strings.Unbounded;

   type Component_Type is tagged limited null record;

   ------------------------------------------------------
   -- Defaults
   ------------------------------------------------------
   function Default_Box return Unbounded_String;
   function Default_Box_Lot return Unbounded_String;
   function Default_Box_Short_Lot return Unbounded_String;

   function Default_Timer return Unbounded_String;
   function Default_Timer_Lot return Unbounded_String;
   function Default_Timer_Short_Lot return Unbounded_String;

   function Default_Bottle return Unbounded_String;
   function Default_Bottle_Lot return Unbounded_String;
   function Default_Bottle_Short_Lot return Unbounded_String;

   ------------------------------------------------------
   -- INVENTORY
   ------------------------------------------------------

   type Location is (Offboard, On_Fore, On_Aft, On_Boom);
   type State is (Off, Loading, Unloading, Stored, Delivery, Delivered);

   ------------------------------------------------------
   -- BOX
   --   Type of box
   --   Type of timer
   --   Vehicle (offboard, Fore, Aft)
   --   State (off, loading, unloading, stored, delivery, delivered)
   --   Compartment number (1..5)
   --   Slot (1..30)
   --   At_Gate
   --   Temperature
   --   Box Lot number
   --   Box Short Lot number
   --   Timer Lot number
   --   Timer Short Lot number
   --   Load number
   --   Load index
   --   Bottle type match

   type Box_Type is
      record
         Name : Unbounded_String;
         Assembly_Name : Unbounded_String;
         Timer : Unbounded_String;
         At_Location : Location := Offboard;
         At_State : State := Off;
         Compartment : N_Box_Mags := 0;
         Slot : N_Box_Slots := 0;
         Cell : Integer;
         At_Gate : Boolean := False;
         Temperature : Float := 0.0;
         Box_Lot : Unbounded_String;
         Box_Short_Lot : Unbounded_String;
         Timer_Lot : Unbounded_String;
         Timer_Short_Lot : Unbounded_String;
         Load_Number : Integer := 0;
         Load_Index : Integer := 0;
      end record;

   -- BOTTLE
   --   Type of bottle
   --   Vehicle (offboard, Fore, Aft)
   --   State (off, loading, unloading, stored, delivery, delivered)
   --   Compartment number (1..2)
   --   Tube (1..13)
   --   Top_Of_Stack
   --   Stack_Depth
   --   Temperature
   --   Lot number
   --   Short Lot number
   --   Grouped
   --   Zone
   --   Load number
   --   Load index
   --   Box type match

   type Bottle_Type is
      record
         Name : Unbounded_String; -- := Default_Bottle;
         At_Location : Location := Offboard;
         At_State : State := Off;
         Compartment : N_Bottle_Mags := 0;
         Tube : N_Bottle_Tubes := 0;
         Top_Of_Stack : Boolean := False;
         Stack_Depth : N_Tube_Depth := 0;
         Temperature : Float := 0.0;
         Bottle_Lot : Unbounded_String;
         Bottle_Short_Lot : Unbounded_String;
         Grouped : Boolean := False;
         Zone : Integer := 1;
         Load_Number : Integer := 0;
         Load_Index : Integer := 0;
      end record;

   ------------------------------------------------------
   -- CELLS
   ------------------------------------------------------

   type Box_Cell_Type (Id : N_Id) is new Component_Type with
      record
         Empty : Boolean := True;
         Box : Box_Type;
      end record;
   type Box_Cell_Access is access all Box_Cell_Type;

   package Tube_Stack is new Ada.Containers.Vectors (Positive, Bottle_Type);

   type Bottle_Cell_Type (Id : N_Id; Depth : N_Tube_Depth) is
     new Component_Type with
      record
         Filled : Boolean := False;
         Stack : aliased Tube_Stack.Vector;
      end record;
   type Bottle_Cell_Access is access all Bottle_Cell_Type;

   ------------------------------------------------------
   -- MAGAZINES
   ------------------------------------------------------

   type Box_Slots is array (N_Box_Slots range <>) of Box_Cell_Access;

   type Box_Compartment_Type (Id : N_Id; Slots : N_Box_Slots) is
     new Component_Type with
      record
         Slot : Box_Slots (1 .. Slots) :=
           (others => new Box_Cell_Type (Id));
      end record;
   type Box_Compartment_Access is access Box_Compartment_Type;

   type Bottle_Tubes is array (N_Bottle_Tubes range <>) of Bottle_Cell_Access;

   type Bottle_Compartment_Type
          (Id : N_Id; Tubes : N_Bottle_Tubes; Depth : N_Tube_Depth) is
     new Component_Type with
      record
         Tube : Bottle_Tubes (1 .. Tubes) :=
           (others => new Bottle_Cell_Type (Id, Depth));
      end record;
   type Bottle_Compartment_Access is access Bottle_Compartment_Type;


   ------------------------------------------------------
   -- INVENTORY
   ------------------------------------------------------

   type Box_Mags is array (N_Box_Mags range <>) of
                        Box_Compartment_Access;

   type Box_Inventory_Type
          (Id : N_Id; Mags : N_Box_Mags; Slots : N_Box_Slots) is
     new Component_Type with
      record
         Mag : Box_Mags (1 .. Mags) :=
           (others => new Box_Compartment_Type (Id, Slots));
         -- this is the number of boxs currently in entire inventory
         Box_Count : Integer;
      end record;

   type Bottle_Mags is array (N_Bottle_Mags range <>) of Bottle_Compartment_Access;

   -- This is needed to gain aliased access to internal stack iterator (i.e. JpRosen trick)
   type Bottle_Inventory (Self : access Bottle_Inventory_Type) is
     limited null record;

   type Bottle_Inventory_Type (Id : N_Id;
                                   Mags : N_Bottle_Mags;
                                   Tubes : N_Bottle_Tubes;
                                   Depth : N_Tube_Depth) is
     new Component_Type with
      record
         Inv : Bottle_Inventory (Bottle_Inventory_Type'Access);
         Mag : Bottle_Mags (1 .. Mags) :=
           (others => new Bottle_Compartment_Type (Id, Tubes, Depth));
         -- this is the number of bottles currently in entire inventory
         Bottle_Count : Integer;
      end record;

------------------------------------------------------------------------------
-- $id: plant-inventory.ads,v 1.3 01/15/2003 19:30:44 ludwiglj Exp $
------------------------------------------------------------------------------
end Plant.Inventory;
