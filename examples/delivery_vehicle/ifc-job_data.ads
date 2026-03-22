with Gis;
with Str; use Str;
with Ada.Containers.Vectors;
with Vkb;

package Ifc.Job_Data is

   pragma Elaborate_Body;

   type Item is
      record
         Customer : Gis.Utm_Coordinate;
         Elevation : Float;
         Azimuth : Float;
         -- this time is only relevant if the jobs Control = "Time On Customer"
         -- this time is relative to Start_Time of job
         On_Customer_Time : Duration;
         Box : Bstr.Bounded_String;
         Bottle : Bstr.Bounded_String;
         Timer : Bstr.Bounded_String;
         Timer_Setting : Bstr.Bounded_String;
      end record;

   package Item_Vector is new Ada.Containers.Vectors (Positive, Item, "=");

   type Delivery_Job_Data is
      record
         Id : Bstr.Bounded_String;
         Start_Time : Duration;
         Customer_Description : Bstr.Bounded_String;
         Job_Description : Bstr.Bounded_String;
         -- Control should be either "When Ready" or "Time On Customer"
         Control : Bstr.Bounded_String;
         Phase : Bstr.Bounded_String;
         Items : Item_Vector.Vector;
      end record;

   procedure Add_Delivery_Job (Id : Bstr.Bounded_String;
                               Data : Delivery_Job_Data;
                               Description : Bstr.Bounded_String := Bstr.To_Bounded_String("No Description"));

   procedure Remove_Delivery_Job (Id : Bstr.Bounded_String);

   procedure Get_Delivery_Job (Id : in Bstr.Bounded_String;
                               Found_It : out Boolean;
                               Data : out Delivery_Job_Data);

   -- Regularly delivery jobs have a customer and the azimuth and velocity are calculated
   -- in order to "hit" that customer, but sometimes we just want to deliver at a specific
   -- elevation and azimuth and there is no customer.
   function Has_Customer (Data : Delivery_Job_Data) return Boolean;

   -- Since the zoning (amount of bottle) is determined dynamically during
   -- flight calculations, and since we rely on accessing the kbase to return
   -- the item xml, this method is provided here and should be called during
   -- flight calculations once the zoning is determined.
   procedure Set_Zoning (Id : Bstr.Bounded_String;
                         Item_Num : Integer;
                         Zone_Num : Integer);

end Ifc.Job_Data;
