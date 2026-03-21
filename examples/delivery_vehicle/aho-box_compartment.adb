with Pace.Log;

with hal.bounded_Assembly;
with Hal.Sms_Lib.Racetrack;
with Hal.Racetrack_Pin;

package body Aho.Box_Compartment is

   function Id is new Pace.Log.Unit_Id;

   task Agent is
      entry Input (Obj : Select_Box);
      entry Input (Obj : Increment_Slot);
   end Agent;

   use hal.bounded_Assembly;

   Num_Slots : constant := 24;
   Final_Pos : Boolean := False;

   package Box_Racetrack is
     new Hal.Racetrack_Pin (Num_Slots => Num_Slots,
                            Num_Intervals => 13,
                            Slot_Distance => 0.178,
                            Track_Width => 0.178,
                            Assembly_Prefix => To_Bounded_String ("RSlot"),
                            Slot_To_Slot_Time => 2.0);

   procedure Input (Obj : Abort_Selection) is
   begin
      Box_Racetrack.Abort_Selection;
      declare
         Msg : Aho.Box_Compartment.Select_Box_Completed;
      begin
         Pace.Dispatching.Inout (Msg);
      end;
      Pace.Log.Trace (Obj);
   end Input;

   Available_Slot : Integer := 1;

   task body Agent is
      use Box_Racetrack;

      Slot_To_Select : Integer;
      Which_Way : Hal.Rotation_Direction;
      use type Hal.Rotation_Direction;
   begin -- the task starts
      Pace.Log.Agent_Id (Id);

      Pace.Log.Put_Line ("configuring track");
      Configure_Track;

      loop
         select
            accept Input (Obj : Select_Box) do
               Slot_To_Select := Obj.Slot_Num;
               Pace.Log.Trace (Obj);
            end Input;
            Available_Slot := Select_Slot (Slot_To_Select);
            declare
               Msg : Select_Box_Completed;
            begin
               Msg.Available_Slot := Available_Slot;
               Input (Msg);
            end;
         or
            accept Input (Obj : Increment_Slot) do
               Which_Way := Obj.Which_Way;
               Pace.Log.Trace (Obj);
            end Input;
            Inc_Slot (Which_Way);
            if Which_Way = Hal.Cw then
               Available_Slot := Available_Slot - 1;
            else
               Available_Slot := Available_Slot + 1;
            end if;
            if Available_Slot > Num_Slots then
               Available_Slot := 1;
            elsif Available_Slot < 1 then
               Available_Slot := Num_Slots;
            end if;
         or
            terminate;
         end select;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Open_Door) is
   begin
      --Hal.Sms.Set ("axis_door", "openDoor");
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Close_Door) is
   begin
      --Hal.Sms.Set ("axis_door", "closeDoor");
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Select_Box) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Increment_Slot) is
   begin
      Agent.Input (Obj);
   end Input;



--    procedure Input (Obj : in Index_Compartment) is
--    begin
--       Pace.Log.Wait (4.5);  -- just a placeholder until we have motions in place
--       declare
--          Msg : Index_Complete;
--       begin
--          Pace.Dispatching.Input (Msg);
--       end;
--       Pace.Log.Trace (Obj);
--    end Input;

   procedure Input (Obj : in Index_To_Delivery_Position) is
   begin
      Pace.Log.Wait (4.5);
      Final_Pos := False;
      Pace.Log.Trace (Obj);
   end;

   procedure Input (Obj : in Index_To_Shuttle_Gate) is
   begin
      Pace.Log.Wait (4.5);
      declare
         Msg : Index_Complete;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      Final_Pos := True;
      Pace.Log.Trace (Obj);
   end;

   procedure Input (Obj : in Index_To_Final_Position) is
   begin
      if not Final_Pos then
         Pace.Log.Wait (0.5);
		 Pace.Log.Put_Line ("Index To Final Position");
         declare
            Msg : Index_Complete;
         begin
            Pace.Dispatching.Input (Msg);
         end;
      end if;
      Pace.Log.Trace (Obj);
   end;

end Aho.Box_Compartment;
