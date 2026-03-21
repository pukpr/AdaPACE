with Pace;
with Pace.Notify;
with Str;

package Ifc.Delivery_Mission is

   pragma Elaborate_Body;

   -- setting a delivery mission through the kbase
   type Accept_Delivery_Order is new Pace.Msg with
      record
         Id : Str.Bstr.Bounded_String;
         Mission_Accepted : Boolean;  -- output .. true means mission was accepted, false it was denied
      end record;
   procedure Inout (Obj : in out Accept_Delivery_Order);

   function Get_Delivery_Mission_Id return Str.Bstr.Bounded_String;

   type Check_Azimuth is new Pace.Msg with
      record
         Within_Azimuth : Boolean;
      end record;
   procedure Output (Obj : out Check_Azimuth);

private
   pragma Inline (Inout);
   pragma Inline (Get_Delivery_Mission_Id);

-- $id: ifc-delivery_mission.ads,v 1.9 12/22/2003 14:14:53 ludwiglj Exp $
end Ifc.Delivery_Mission;
