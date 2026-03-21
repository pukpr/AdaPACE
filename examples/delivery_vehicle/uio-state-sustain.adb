with Pace.Log;
with Pace.Strings; use Pace.Strings;
with Pace.Server.Xml;
with Acu;
with Mob;
with Uio.State.Move;

package body Uio.State.Sustain is
   function Id is new Pace.Log.Unit_Id;

   function Get_State return State_Enum;

   -- state transitions --
   function Do_Emplacement return Boolean;
   procedure Call (Val : in Boolean; Info : String := "");

   -- overall state of the sustain job
   Current_State : State_Enum := Initial;


   function Get_State return State_Enum is
   begin
      return Current_State;
   end Get_State;

   procedure Set_Initial_State is
   begin
      Current_State := Initial;
   end Set_Initial_State;

   ------ state transitions ------

   function Do_Emplacement return Boolean is
   begin
      if Current_State = Initial then
         declare
            Msg : Acu.Vehicle.Emplace;
         begin
            Pace.Dispatching.Input (Msg);
         end;
         Current_State := Docked;
         declare
            Msg : Vehicle_State;
         begin
            Msg.State := Sustain_State;
            Input (Msg);
         end;
         return True;
      else
         return False;
      end if;
   end Do_Emplacement;

   function Do_Enable return Boolean is
   begin
      if Current_State = Docked then
         Current_State := Sustaining;
         return True;
      else
         return False;
      end if;
   end Do_Enable;

   function Do_Reemplacement return Boolean is
   begin
      if Current_State = Docked then
         declare
            Msg : Uio.State.Move.Next_State;
         begin
            Uio.State.Move.Append (Msg, "DISPLACE");
            Pace.Dispatching.Inout (Msg);
         end;
         declare
            Msg : Acu.Vehicle.Transmission_Control;
         begin
            Msg.Mode := Mob.Pivot;
            Pace.Dispatching.Input (Msg);
         end;
         Current_State := Initial;
         return True;
      else
         return False;
      end if;
   end Do_Reemplacement;

   function Do_Items_Loaded return Boolean is
   begin
      if Current_State = Sustaining then
         -- insert call here to rearm package
         return True;
      else
         return False;
      end if;
   end Do_Items_Loaded;


   ------ end state transitions ------

   procedure Call (Val : in Boolean; Info : String := "") is
   begin
      if not Val then
         Pace.Log.Put_Line ("ERROR: could not " & Info);
      end if;
   end Call;

   procedure Inout (Obj : in out Next_State) is
      use Pace.Server.Dispatch;
      Cmd : constant String := +Obj.Set;
   begin
      Obj.Set := +Null_Tag;
      if Cmd = "EMPLACE" then
         Call (Do_Emplacement, Cmd);
      elsif Cmd = "RE-EMPLACE" then
         Call (Do_Reemplacement, Cmd);
         -- The call to Do_Reemplacement calls
         -- UIO.STATE-MOVE.NEXT_STATE?set=DISPLACE, which
         -- already calls Pace.Server.Put_Data.
         -- We want to avoid doing this more than once, so
         -- simply return from this function.
         Return;
      elsif Cmd = "ENABLE" then
         Call (Do_Enable, Cmd);
      elsif Cmd = "ITEMS_LOADED" then
         Call (Do_Items_Loaded, Cmd);
      else
         Call (False, Cmd & " -> Unknown Sustain State Change attempted");
      end if;
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

   procedure Inout (Obj : in out State) is
      use Pace.Server.Dispatch;
   begin
      Obj.Set := +("<state>" & State_Enum'Image (Get_State) & "</state>");
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

   use Pace.Server.Dispatch;
begin
   Save_Action (Next_State'(Pace.Msg with Default));
   Save_Action (State'(Pace.Msg with Default));
-- $Id: uio-state-sustain.adb,v 1.12 2005/02/17 16:17:26 ludwiglj Exp $ --
end Uio.State.Sustain;
