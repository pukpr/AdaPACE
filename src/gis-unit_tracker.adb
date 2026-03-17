with Ada.Strings.Unbounded;
with Pace.Log;
with Pace.Server.Xml;
with Pace.Strings;

package body Gis.Unit_Tracker is

   use Pace.Strings;

   Pace_Node : Integer := Integer'Value (Pace.Getenv ("PACE_NODE", "0"));
   Network_Id : Integer := Integer'Value (Pace.Getenv ("FCS_NETWORK_ID", "0"));

   function Hash (Unit : Unit_Type) return Ada.Containers.Hash_Type is
   begin
      return Pace.Strings.Hash (Unit.Id);
   end Hash;

   function "=" (L, R : Unit_Type) return Boolean is
   begin
      return B2s (L.Id) = B2s (R.Id);
   end "=";

   use Unit_Hashset;

   procedure Input (Obj : in Add_Unit) is
   begin
      if Unit_Set.Contains(Obj.Unit) then
         Replace(Unit_Set, Obj.Unit);
      else
         Insert(Unit_Set, Obj.Unit);
      end if;
   end Input;

   procedure Input (Obj : in Update_Unit) is
   begin
      -- Skip messages sent by self and those that do not match the Network_Id.
      if Pace.Get_Node (Obj) /= Pace_Node and Obj.Network_Id = Network_Id then
         Include (Unit_Set, Obj.Unit);
      end if;
   end Input;

   procedure Clear_Units is
   begin
      Clear (Unit_Set);
   end Clear_Units;

   function Get_Entity_List_Xml return String is
      use Ada.Strings.Unbounded;
      use Pace.Server.Xml;
      Result : Us;
      Iter : Cursor := First (Unit_Set);
      Unit : Unit_Type;
   begin
      while Iter /= No_Element loop
         Unit := Element (Iter);
         Append (Result, Item ("entity",
                               Item ("status", Unit.Side'Img) &
                               Item ("type", B2s (Unit.id)) &
                               Item ("location",
                                     Item ("easting", Trim (Unit.Location.Easting)) &
                                     Item ("northing", Trim (Unit.Location.Northing)))));
         Next (Iter);
      end loop;
      return Item ("entity_list", U2s (Result));
   end Get_Entity_List_Xml;

end Gis.Unit_Tracker;
