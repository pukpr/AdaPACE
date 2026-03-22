with Pace;
with Pace.Notify;
with Str;

package Ifc.Delivery_Job is

   pragma Elaborate_Body;

   -- setting a delivery job through the kbase
   type Accept_Delivery_Order is new Pace.Msg with
      record
         Id : Str.Bstr.Bounded_String;
         Job_Accepted : Boolean;  -- output .. true means job was accepted, false it was denied
      end record;
   procedure Inout (Obj : in out Accept_Delivery_Order);

   function Get_Delivery_Job_Id return Str.Bstr.Bounded_String;

   type Check_Azimuth is new Pace.Msg with
      record
         Within_Azimuth : Boolean;
      end record;
   procedure Output (Obj : out Check_Azimuth);

private
   pragma Inline (Inout);
   pragma Inline (Get_Delivery_Job_Id);

end Ifc.Delivery_Job;
