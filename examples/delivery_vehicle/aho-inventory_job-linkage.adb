with Pace.Log;

separate (Aho.Inventory_Job)
package body Linkage is

   procedure Input (Obj : in Raise_Loader) is
   begin
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Lower_Loader) is
   begin
      Pace.Log.Trace (Obj);
   end Input;

end Linkage;
