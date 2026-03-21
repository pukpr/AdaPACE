
with Pace.Notify;

-- Note:  there is no corresponding body for the spec. Uio.Job_Order_Status
-- utilizes this type.  It is located here purely for clarity of design.
package Ahd.Job_Order_Status is

   type Box_Status is (Nil, Ready, Timerd, Placed, Delivered);

   type Box_Setup is new Pace.Notify.Subscription with
      record
         Num_Boxs : Integer;
      end record;

   type Modify_Box is new Pace.Notify.Subscription with
      record
         Index : Integer;
         Status : Box_Status;
      end record;

end Ahd.Job_Order_Status;
