with Plant;
with Ifc.Fm_Data;

package Ahd is
   -- Inventory Handling & Delivery

   -- extra item info that is not in kbase
   -- as well as elevation and azimuth.... see mission_record comments below
   type Item_Extra is
      record
         Elevation : Float; -- degrees
         Azimuth : Float; -- degrees
         Num_Charges : Plant.Charge_Range;
         Launchpad_Velocity : Float; -- m/s
         -- seconds from beginning of simulation start when the item should be delivered..
         -- see pace.config.to_sim_time and pace.config.to_calendar_time
         -- if delivery_time is 0.0 then delivery ASAP
         Delivery_Time : Duration;
         Misdelivery : Boolean := False; -- if true then this item will misdelivery
         Reload : Boolean := False; -- if true then this item will be put back in compartment
                                    -- and a item with a different type will be selected
      end record;

   type Items_Array is array (1 .. Plant.Max_Boxs) of Item_Extra;

   -- data represents what is in the kbase
   -- items has extra data on each item as well as the calculated flight data
   -- i.e. values of Data will never change, whereas Items values are recalculated
   -- by flights kernel immediately before delivery
   type Mission_Record is
      record
         -- set to false during flight calculations if any of the targets are out of range
         Within_Range : Boolean := True;
         Data : Ifc.Fm_Data.Delivery_Mission_Data;
         Items : Items_Array;
      end record;

   -- $Id: ahd.ads,v 1.16 2005/04/21 16:18:37 ludwiglj Exp $
end Ahd;

