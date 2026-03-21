with Pace;
with Hal;
with Pace.Notify;
with Ada.Strings.Unbounded;
with Pace.Semaphore;

package Aho.Inventory_Loader is

   pragma Elaborate_Body;

   type Loader_Type is (Morph_Loader, Jack_Loader, Four_Loader,
                        Demonstrator_Loader, Linkage_Loader);
--   function Get_Which_Loader return Loader_Type;

   type Initialize is new Pace.Msg with
      record
         Total_Items : Integer;
      end record;
   procedure Input (Obj : in Initialize);

   type Load_Drone is new Pace.Msg with
      record
         Item_Index : Integer;
         Azimuth : Float;
         Elevation : Float;
      end record;
   procedure Input (Obj : in Load_Drone);

   type Ack_Load_Drone_Complete is new Pace.Msg with null record;
   procedure Input (Obj : in Ack_Load_Drone_Complete);

   type Stow_Equipment is new Pace.Msg with null record;
   procedure Input (Obj : in Stow_Equipment);

   type Raise_Loader_For_Rearm is new Pace.Msg with null record;
   procedure Input (Obj : in Raise_Loader_For_Rearm);

   type Lower_Loader_For_Rearm is new Pace.Msg with null record;
   procedure Input (Obj : in Lower_Loader_For_Rearm);

   type Raise_Loader is new Pace.Msg with null record;
   procedure Input (Obj : in Raise_Loader);

   type Lower_Loader is new Pace.Msg with null record;
   procedure Input (Obj : in Lower_Loader);

   type Swing_Tray_To_Bottle is new Pace.Msg with null record;
   procedure Input (Obj : in Swing_Tray_To_Bottle);

   type Swing_Tray_To_Box is new Pace.Msg with null record;
   procedure Input (Obj : in Swing_Tray_To_Box);

   type Swing_Bottle_Tray_Door_Open is new Pace.Msg with null record;
   procedure Input (Obj : in Swing_Bottle_Tray_Door_Open);

   type Swing_Bottle_Tray_Door_Close is new Pace.Msg with null record;
   procedure Input (Obj : in Swing_Bottle_Tray_Door_Close);

   type Open_Loader_Retainer is new Pace.Msg with null record;
   procedure Input (Obj : in Open_Loader_Retainer);

   type Close_Loader_Retainer is new Pace.Msg with null record;
   procedure Input (Obj : in Close_Loader_Retainer);

   type Clear_To_Delivery is new Pace.Notify.Subscription with null record;


   type Counter_Rotate is new Pace.Msg with
      record
         Offset : Float;
         Max_Velocity : Float;  -- radians
         Ramp_Up : Duration;
         Ramp_Down : Duration;
      end record;
   procedure Input (Obj : in Counter_Rotate);

   type Rotate_Loader is new Pace.Msg with
      record
         Final : Hal.Orientation;
         Total_Time : Duration;
         Assembly : Ada.Strings.Unbounded.Unbounded_String;
      end record;
   procedure Input (Obj : in Rotate_Loader);
private
   pragma Inline (Input);

end Aho.Inventory_Loader;
