
with Ada.Containers.Hashed_Maps;
with Ada.Strings.Hash;
with Ada.Text_Io;
with Pace.Semaphore;

package body Hal.Velocity_Plots is

   function Hash (Key : Bounded_String) return Ada.Containers.Hash_Type is
   begin
      return Ada.Strings.Hash (To_String (Key));
   end Hash;

   package Velocity_Plot_Map is
     new Ada.Containers.Hashed_Maps (Key_Type => Bounded_String,
                                     Element_Type => Velocity_Plot_Data,
                                     Hash => Hash,
                                     Equivalent_Keys => "=",
                                     "=" => "=");

   Map_Mutex : aliased Pace.Semaphore.Mutex;

   use Velocity_Plot_Map;
   Velocity_Map : Map;

   procedure Add_Plot_Data (Assembly : Bounded_String;
                            Plot_Data : Velocity_Plot_Data) is
      L : Pace.Semaphore.Lock (Map_Mutex'Access);
   begin
      Include (Velocity_Map, Assembly, Plot_Data);
   end Add_Plot_Data;

   function Get_Assembly_List return Assembly_Vector.Vector is
      Result : Assembly_Vector.Vector;
      L : Pace.Semaphore.Lock (Map_Mutex'Access);
   begin
      if not Is_Empty (Velocity_Map) then
         declare
            Iter : Cursor := First (Velocity_Map);
         begin
            while Iter /= No_Element loop
               Assembly_Vector.Append (Result, Key (Iter));
               Next (Iter);
            end loop;
         end;
      end if;
      return Result;
   end Get_Assembly_List;

   function Get_Velocity_Vector (Assembly : String) return Velocity_Plot_Data is
      L : Pace.Semaphore.Lock (Map_Mutex'Access);
   begin
      return Element (Find (Velocity_Map, To_Bounded_String (Assembly)));
   end Get_Velocity_Vector;

end Hal.Velocity_Plots;
