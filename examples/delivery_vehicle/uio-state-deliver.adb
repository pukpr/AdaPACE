with Mob;
with Acu;
with Mxr.Delivery_Order;
with Pace.Log;
with Pace.Server.Dispatch;
with Pace.Server.Html;
with Ifc.Delivery_Job;
with Ahd.Delivery_Job;
with Uio.Job_Order_Status;
with Uio.Job_Audio_Alert;
with Ual.Utilities;
with Pace.Server.Xml;
with Nav.Route_Following;
--with Hal.Flybox;
with Uio.State.Move; -- high coupling sucks!  fix some time.
with Pace.Strings; use Pace.Strings;

package body Uio.State.Deliver is

   function Get_Equipment_Configured return Boolean;
   function Have_Job return Boolean;
   function Is_Within_Azimuth return Boolean;
   function Is_Items_Complete return Boolean;
   procedure Attempt_Configure_Equipment;

   -- state transitions --
   function Do_Acknowledge return Boolean;
   function Do_Emplacement return Boolean;
   function Do_Reemplacement return Boolean;
   function Do_Enable return Boolean;
   function Do_Items_Complete return Boolean;
   function Do_Clear_Items_Complete return Boolean;
   procedure Call (Val : in Boolean; Info : String := "");

   -- this is used to compare against ahd.delivery_job.fms_completed to know if the
   -- delivery job has completed
   Fms_Completed : Integer := 0;

   Equipment_Configured : Boolean := False;

   -- overall state of the delivery job
   Current_State : State_Enum := Initial;

   function Get_Equipment_Configured return Boolean is
   begin
      return Equipment_Configured;
   end Get_Equipment_Configured;

   function Have_Job return Boolean is
      Msg : Mxr.Delivery_Order.Is_Delivery_Order_Received;
   begin
      Pace.Dispatching.Inout (Msg);
      return Msg.Val;
   end Have_Job;

   function Is_Within_Azimuth return Boolean is
      Msg : Ifc.Delivery_Job.Check_Azimuth;
   begin
      if Have_Job then
         Pace.Dispatching.Output (Msg);
         return Msg.Within_Azimuth;
      else
         return False;
      end if;
   end Is_Within_Azimuth;

   function Is_Items_Complete return Boolean is
      Result : Boolean := False;
   begin
      if Ahd.Delivery_Job.Get_Fms_Completed > Fms_Completed then
         Result := True;
      end if;
      return Result;
   end Is_Items_Complete;

   procedure Output (Obj : out Get_Current_State) is
   begin
      Obj.Current_State := Current_State;
      Pace.Log.Trace (Obj);
   end Output;

   procedure Set_Initial_State is
   begin
      Current_State := Initial;
   end Set_Initial_State;

   procedure Prepare_To_Emplace is
   begin
      -- turn off the delivery job alert sound
      declare
         Msg : Uio.Job_Audio_Alert.End_Alert;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Acu.Vehicle.Emplace;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Prepare_To_Emplace;

   procedure Attempt_Configure_Equipment is
   begin
      if Have_Job and then Is_Within_Azimuth then
         declare
            Msg : Ahd.Delivery_Job.Configure;
         begin
            Pace.Dispatching.Input (Msg);
         end;

         -- for now, let's just assume that the equipment
         -- is configured instantly once they are docked.
         -- how is the equipment "configured" for an emplacement
         -- where a job has not been sent in?
         Equipment_Configured := True;
      end if;
   end Attempt_Configure_Equipment;

   ------ state transitions ------

   function Do_Acknowledge return Boolean is
   begin
      if Current_State = Initial then
         Current_State := Acknowledged;
         return True;
      else
         return False;
      end if;
   end Do_Acknowledge;

   function Do_Emplacement return Boolean is
   begin
      if Current_State = Acknowledged then
         Prepare_To_Emplace;
         if not Get_Equipment_Configured then
            Attempt_Configure_Equipment;
         end if;

         Current_State := Docked;

         declare
            Msg : Vehicle_State;
         begin
            Msg.State := Deliver_State;
            Input (Msg);
         end;

         -- turn flybox mode to None
--          declare
--             Msg : Hal.Flybox.Change_Mode;
--          begin
--             Msg.Mode := 0;
--             Pace.Dispatching.Input (Msg);
--          end;

         return True;
      else
         return False;
      end if;
   end Do_Emplacement;

   function Do_Reemplacement return Boolean is
   begin
      if Current_State = Docked then
         declare
            Msg : Uio.State.Move.Next_State;
         begin
            Uio.State.Move.Append (Msg, "DISPLACE");
            Pace.Dispatching.Inout (Msg);
         end;
--         declare
--             Msg : Acu.Vehicle.Displace;
--          begin
--             Pace.Dispatching.Input (Msg);
--          end;
         declare
            Msg : Acu.Vehicle.Transmission_Control;
         begin
            Msg.Mode := Mob.Pivot;
            Pace.Dispatching.Input (Msg);
         end;

         Current_State := Acknowledged;
         return True;
      else
         return False;
      end if;
   end Do_Reemplacement;

   function Do_Enable return Boolean is
   begin
      if Current_State = Docked then
         if not Equipment_Configured then
            Attempt_Configure_Equipment;
         end if;
         Current_State := Delivering;
         -- in case the alert is somehow still playing, turn it off here
         declare
            Msg : Uio.Job_Audio_Alert.End_Alert;
         begin
            Pace.Dispatching.Input (Msg);
         end;
         declare
            Msg : Ahd.Delivery_Job.Execute_Delivery_Order;
         begin
            Pace.Dispatching.Input (Msg);
         end;
         Pace.Log.Put_Line ("Enabled");
         return True;
      else
         return False;
      end if;
   end Do_Enable;

   function Do_Items_Complete return Boolean is
   begin
      if Current_State = Delivering then
         Current_State := Items_Complete;
         Equipment_Configured := False;
         Pace.Log.Put_Line ("ITEMS COMPLETE");
         return True;
      else
         return False;
      end if;
   end Do_Items_Complete;

   function Do_Clear_Items_Complete return Boolean is
   begin
      if Current_State = Items_Complete then
         Current_State := Docked;
         Fms_Completed := Fms_Completed + 1;
         -- the next two declare blocks could potentially be replaced by a publish/subscribe
         -- mechanism..
         declare
            Msg : Mxr.Delivery_Order.Clear_Delivery_Order_Received;
         begin
            Pace.Dispatching.Input (Msg);
         end;
         -- this tells the route following to stop and reset itself
         declare
            Msg : Nav.Route_Following.Stop;
         begin
            Pace.Dispatching.Input (Msg);
         end;
         -- clears the data being sent to UI about delivery job
         declare
            Msg : Uio.Job_Order_Status.Clear_Delivery_Job;
         begin
            Pace.Dispatching.Input (Msg);
         end;

         Pace.Log.Put_Line ("Items Complete CLEARED");
         return True;
      else
         return False;
      end if;
   end Do_Clear_Items_Complete;

   ------ end state transitions ------

   procedure Call (Val : in Boolean; Info : String := "") is
   begin
      if not Val then
         Pace.Log.Put_Line ("ERROR: could not '" & Info & "'");
      end if;
   end Call;

   procedure Inout (Obj : in out Next_State) is
      use Pace.Server.Dispatch;
      Cmd : constant String := U2s(Obj.Set);
   begin
      Obj.Set := S2u(Null_Tag);
      if Cmd = "EMPLACE" then
         if Current_State = Acknowledged then
            Call (Do_Emplacement, Cmd);
         end if;
      elsif Cmd = "ENABLE" then
         if Current_State = Docked then
            if Have_Job and then Is_Within_Azimuth then
               Call (Do_Enable, Cmd);
            else
               Null; -- Do nothing
            end if;
         end if;
      elsif Cmd = "RE-EMPLACE" then
         if Current_State = Docked then
            Call (Do_Reemplacement, "Re-emplacement");
            -- The call to Do_Reemplacement calls
            -- UIO.STATE-MOVE.NEXT_STATE?set=DISPLACE, which
            -- already calls Pace.Server.Put_Data.
            -- We want to avoid doing this more than once, so
            -- simply return from this function.
            Return;
         end if;
      elsif Cmd = "ACKNOWLEDGE" then
         Call (Do_Acknowledge, Cmd);
      elsif Cmd = "CLEAR_ITEMS_COMPLETE" then
         if Current_State = Items_Complete then
            Call (Do_Clear_Items_Complete, Cmd);
         else
            Obj.Set := S2u("<val>no</val>");
         end if;
      elsif Cmd = "ITEMS_COMPLETE" then
         if Current_State = Delivering and Is_Items_Complete then
            Call (Do_Items_Complete, Cmd);
         else
            Obj.Set := S2u("<val>no</val>");
         end if;
      elsif Cmd = "ATTEMPT_CONFIGURE_EQUIPMENT" then
         if Current_State = Docked and not Get_Equipment_Configured then
            Attempt_Configure_Equipment;
         end if;
      elsif Cmd = "READY_TO_DELIVERY_ENABLE" then
         if Have_Job and then Is_Within_Azimuth then
            null;
         else
            Obj.Set := S2u("<val>no</val>");
         end if;
      elsif Cmd = "HAVE_JOB" then
         if Have_Job then
            null;
         else
            Obj.Set := S2u("<val>no</val>");
         end if;
      elsif Cmd = "IN_PROCESS" then
         if Current_State = Initial or Current_State = Acknowledged or
            Current_State = Docked then
            null;
         else
            Obj.Set := S2u("<val>no</val>");
         end if;
      else
         Call (False, Cmd & " -> Unknown Deliver State Change attempted");
      end if;
      Pace.Server.Put_Data (U2s(Obj.Set));
      Pace.Log.Trace (Obj);
   end Inout;

   procedure Inout (Obj : in out State) is
      use Pace.Server.Dispatch;
   begin
      Obj.Set := S2u("<state>" & State_Enum'Image (Current_State) & "</state>");
      Pace.Server.Put_Data (U2s(Obj.Set));
      Pace.Log.Trace (Obj);
   end Inout;

   use Pace.Server.Dispatch;
begin
   Save_Action (Next_State'(Pace.Msg with Default));
   Save_Action (State'(Pace.Msg with Default));

-- $Id: uio-state-deliver.adb,v 1.32 2005/04/08 15:44:17 ludwiglj Exp $ --
end Uio.State.Deliver;
