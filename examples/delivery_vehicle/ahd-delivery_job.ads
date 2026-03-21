with Pace;
with Pace.Notify;
with Ifc.Fm_Data;

package Ahd.Delivery_Job is

   pragma Elaborate_Body;

   -- the data for the delivery job comes down through this
   type Delivery_Solution is new Pace.Msg with
      record
         Job : Job_Record;
      end record;
   procedure Input (Obj : in Delivery_Solution);

   type Configure is new Pace.Msg with null record;
   procedure Input (Obj : in Configure);

   -- triggers the inventory handling to start the delivery job to anyone
   -- who is listening
   type Start_Delivery_Job is new Pace.Notify.Subscription with
      record
         Num_Items : Integer;
      end record;

   -- signal that flight solution has been calculated
   type Flight_Solution is new Pace.Notify.Subscription with null record;

   -- triggers the configuration of equipment
   type Configure_Equipment is new Pace.Notify.Subscription with null record;

   -- triggers the execution of the delivery order
   type Execute_Delivery_Order is new Pace.Notify.Subscription with null record;

   -- communication between aho/ahm to tell ahd to publish that job is complete
   type Delivery_Job_Done is new Pace.Notify.Subscription with null record;

   -- subscription message triggered when delivery job is complete
   type Delivery_Job_Complete is new Pace.Msg with null record;
   procedure Input (Obj : in Delivery_Job_Complete);

   -- accessible for publishing the Delivery_Job_Complete list
   procedure Publish_Delivery_Job_Complete;

   -- note that the job data here is preliminary.. the velocity and azimuth are
   -- recalculated directly before delivery and may be different than what is stored here!
   type Get_Delivery_Job is new Pace.Msg with
      record
         Job : Job_Record;
      end record;
   procedure Output (Obj : out Get_Delivery_Job);

   type Adjust_Items is new Pace.Msg with
      record
         Items : Items_Array;
      end record;
   procedure Input (Obj : in Adjust_Items);

   function Get_Fms_Completed return Integer;

   function Has_Customer return Boolean;

   -- returns when the specified item will delivery (in simulation time)
   function Get_Delivery_Time (Index : Integer) return Duration;

   function Is_Time_On_Customer return Boolean;

private
   pragma Inline (Input);

end Ahd.Delivery_Job;
