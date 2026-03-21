with Pace;
with Pace.Notify;
with Ifc.Fm_Data;

package Ahd.Delivery_Mission is

   pragma Elaborate_Body;

   -- the data for the delivery mission comes down through this
   type Delivery_Solution is new Pace.Msg with
      record
         Mission : Mission_Record;
      end record;
   procedure Input (Obj : in Delivery_Solution);

   type Configure is new Pace.Msg with null record;
   procedure Input (Obj : in Configure);

   -- triggers the inventory handling to start the delivery mission to anyone
   -- who is listening
   type Start_Delivery_Mission is new Pace.Notify.Subscription with
      record
         Num_Items : Integer;
      end record;

   -- signal that flight solution has been calculated
   type Flight_Solution is new Pace.Notify.Subscription with null record;

   -- triggers the configuration of equipment
   type Configure_Equipment is new Pace.Notify.Subscription with null record;

   -- triggers the execution of the delivery order
   type Execute_Delivery_Order is new Pace.Notify.Subscription with null record;

   -- communication between aho/ahm to tell ahd to publish that mission is complete
   type Delivery_Mission_Done is new Pace.Notify.Subscription with null record;

   -- subscription message triggered when delivery mission is complete
   type Delivery_Mission_Complete is new Pace.Msg with null record;
   procedure Input (Obj : in Delivery_Mission_Complete);

   -- accessible for publishing the Delivery_Mission_Complete list
   procedure Publish_Delivery_Mission_Complete;

   -- note that the mission data here is preliminary.. the velocity and azimuth are
   -- recalculated directly before delivery and may be different than what is stored here!
   type Get_Delivery_Mission is new Pace.Msg with
      record
         Mission : Mission_Record;
      end record;
   procedure Output (Obj : out Get_Delivery_Mission);

   type Adjust_Items is new Pace.Msg with
      record
         Items : Items_Array;
      end record;
   procedure Input (Obj : in Adjust_Items);

   function Get_Fms_Completed return Integer;

   function Has_Target return Boolean;

   -- returns when the specified item will delivery (in simulation time)
   function Get_Delivery_Time (Index : Integer) return Duration;

   function Is_Time_On_Target return Boolean;

private
   pragma Inline (Input);

end Ahd.Delivery_Mission;
