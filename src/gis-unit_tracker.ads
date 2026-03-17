with Ada.Containers.Hashed_Sets;
with Ada.Strings.Hash;
with Pace.Strings;

package Gis.Unit_Tracker is

   pragma Elaborate_Body;

   use Pace.Strings;

   type Side_Enum is (Grey, Red, Blue);

   type Unit_Type is
      record
         Id : Bs;
         Side : Side_Enum;
         Location : Gis.Utm_Coordinate;
      end record;

   function Hash (Unit : Unit_Type) return Ada.Containers.Hash_Type;
   function "=" (L, R : Unit_Type) return Boolean;


   type Add_Unit is new Pace.Msg with
      record
         Unit : Unit_Type;
      end record;
   procedure Input (Obj : in Add_Unit);

   type Update_Unit is new Pace.Msg with
      record
         Unit : Unit_Type;
         Network_Id : Integer;
      end record;
   procedure Input (Obj : in Update_Unit);

   procedure Clear_Units;

   function Get_Entity_List_Xml return String;

private



   package Unit_Hashset is new Ada.Containers.Hashed_Sets (Element_Type => Unit_Type,
                                                           Hash => Hash,
                                                           Equivalent_Elements => "=",
                                                           "=" => "=");


   Unit_Set : Unit_Hashset.Set;

end Gis.Unit_Tracker;
