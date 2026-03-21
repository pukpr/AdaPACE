with Pace;
with Pace.Log;
with Ahd.Job_Order_Status;

package body Aho.Timer_Setter is

   function Id is new Pace.Log.Unit_Id;

   task Agent is
      entry Input (Obj : Timer_Item);
   end Agent;

   type Set_Timer is new Pace.Msg with
      record
         Item_Number : Integer;
      end record;
   procedure Input (Obj : Set_Timer);
   procedure Input (Obj : Set_Timer) is
   begin
      Pace.Log.Wait (2.5);
      Pace.Log.Trace (Obj);
   end Input;

   task body Agent is
      Item_Number : Integer;
   begin
      Pace.Log.Agent_Id (Id);
      loop
         accept Input (Obj : Timer_Item) do
            Item_Number := Obj.Item_Number;
         end Input;
         declare
            Msg : Set_Timer;
         begin
            Msg.Item_Number := Item_Number;
            Input (Msg);
         end;
      	declare
        	use Ahd.Job_Order_Status;
         	Msg : Modify_Box;
      	begin
         	Msg.Index := Item_Number;
         	Msg.Status := Timerd;
         	Pace.Dispatching.Input (Msg);
      	end;
      	declare
         	Msg : Timer_Complete;
      	begin
         	Input (Msg);
      	end;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Timer_Item) is
   begin
      Agent.Input (Obj);
   end Input;

end Aho.Timer_Setter;
