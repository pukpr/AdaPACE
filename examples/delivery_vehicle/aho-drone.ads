with Pace;
with Hal;
with Ada.Strings.Unbounded;
with Pace.Notify;
with Ahd;
with Ifc.Fm_Data;

package Aho.Drone is

   pragma Elaborate_Body;

   type Initialize is new Pace.Msg with
      record
         Num_Items : Integer;
         Items : Ahd.Items_Array;
      end record;
   procedure Input (Obj : in Initialize);

   type Aim_Drone is new Pace.Msg with null record;
   procedure Input (Obj : in Aim_Drone);

   type Start_Delivery_Job is new Pace.Msg with null record;
   procedure Input (Obj : in Start_Delivery_Job);

   type Elevation_Complete is new Pace.Notify.Subscription with null record;
   type Traverse_Complete is new Pace.Notify.Subscription with null record;
--   type Clear_To_Delivery is new Pace.Notify.Subscription with null record;

   type Load_Complete is new Pace.Msg with null record;
   procedure Input (Obj : in Load_Complete);

   type Test_Drone_Movement is new Pace.Msg with
      record
         Elevation : Float;
         Azimuth : Float;
      end record;
   procedure Input (Obj : in Test_Drone_Movement);

private
   pragma Inline (Input);

end Aho.Drone;
