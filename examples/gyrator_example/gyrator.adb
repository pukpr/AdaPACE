with Pace.Log;

package body Gyrator is

   Current_Status : Status_Type := Halted;

   procedure Input (Obj : in Move) is
   begin
      Pace.Log.Put_Line ("Gyrator: Received Move command. Starting motion...");
      Current_Status := Moving;
   end Input;

   procedure Output (Obj : out Get_Status) is
   begin
      Pace.Log.Put_Line ("Gyrator: Received Get_Status request.");
      Obj.Value := Current_Status;
   end Output;

   procedure Input (Obj : in Halt) is
   begin
      Pace.Log.Put_Line ("Gyrator: Received Halt command. Stopping...");
      Current_Status := Halted;
   end Input;

end Gyrator;
