with Gis;
with Str; use Str;
with Ada.Containers.Vectors;
with Vkb;

package Ifc.Fm_Data is

   pragma Elaborate_Body;

   type Item is
      record
         Target : Gis.Utm_Coordinate;
         Elevation : Float;
         Azimuth : Float;
         -- this time is only relevant if the missions Control = "Time On Target"
         -- this time is relative to Start_Time of mission
         On_Target_Time : Duration;
         Box : Bstr.Bounded_String;
         Bottle : Bstr.Bounded_String;
         Timer : Bstr.Bounded_String;
         Timer_Setting : Bstr.Bounded_String;
      end record;

   package Item_Vector is new Ada.Containers.Vectors (Positive, Item, "=");

   type Delivery_Mission_Data is
      record
         Id : Bstr.Bounded_String;
         Start_Time : Duration;
         Target_Description : Bstr.Bounded_String;
         Mission_Description : Bstr.Bounded_String;
         -- Control should be either "When Ready" or "Time On Target"
         Control : Bstr.Bounded_String;
         Phase : Bstr.Bounded_String;
         Items : Item_Vector.Vector;
      end record;

   procedure Add_Delivery_Mission (Id : Bstr.Bounded_String;
                               Data : Delivery_Mission_Data;
                               Description : Bstr.Bounded_String := Bstr.To_Bounded_String("No Description"));

   procedure Remove_Delivery_Mission (Id : Bstr.Bounded_String);

   procedure Get_Delivery_Mission (Id : in Bstr.Bounded_String;
                               Found_It : out Boolean;
                               Data : out Delivery_Mission_Data);

   -- Regularly delivery missions have a target and the azimuth and velocity are calculated
   -- in order to hit that target, but sometimes we just want to deliver at a specific
   -- elevation and azimuth and there is no target.
   function Has_Target (Data : Delivery_Mission_Data) return Boolean;

   -- Since the zoning (amount of bottle) is determined dynamically during
   -- flight calculations, and since we rely on accessing the kbase to return
   -- the item xml, this method is provided here and should be called during
   -- flight calculations once the zoning is determined.
   procedure Set_Zoning (Id : Bstr.Bounded_String;
                         Item_Num : Integer;
                         Zone_Num : Integer);

end Ifc.Fm_Data;
