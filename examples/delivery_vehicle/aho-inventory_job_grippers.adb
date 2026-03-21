with Pace;
with Pace.Log;

package body Aho.Inventory_Job_Grippers is

  function ID is new Pace.Log.Unit_ID;

  procedure Input (Obj : in Open_Box_Grippers) is
  begin
    Pace.Log.Trace (Obj);
  end Input;
  
  procedure Input (Obj : in Close_Box_Grippers) is
  begin
    Pace.Log.Trace (Obj);
  end Input;

  procedure Input (Obj : in Open_Bottle_Grippers) is
  begin
    Pace.Log.Trace (Obj);
  end Input;
  
  procedure Input (Obj : in Close_Bottle_Grippers) is
  begin
    Pace.Log.Trace (Obj);
  end Input;

end Aho.Inventory_Job_Grippers;
