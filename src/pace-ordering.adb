with Unchecked_Conversion;
with System;
with Interfaces;

function Pace.Ordering (From : in Data) return Data is
   type Bytes is array (0 .. N - 1) of Interfaces.Integer_8;
   function To_Bytes is new Unchecked_Conversion (Data, Bytes);
   function To_Data is new Unchecked_Conversion (Bytes, Data);

   Temp : Bytes := To_Bytes (From);
   To : Bytes;
   use type System.Bit_Order;
begin
   if System.Default_Bit_Order = System.High_Order_First then
      To := Temp;
   else
      for I in Bytes'Range loop
         To (Bytes'Last - I) := Temp (I);
      end loop;
   end if;
   return To_Data (To);
   -- $id: hal-ordering.adb,v 1.2 06/26/2003 22:18:48 pukitepa Exp $
end Pace.Ordering;
