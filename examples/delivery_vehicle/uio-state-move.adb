with Pace.Log;
--with Pace.Socket;
--with Uio.Joystick;
with Acu;
with Mob;
with Pace.Strings; use Pace.Strings;

package body Uio.State.Move is

   function Get_State return State_Enum;

   -- state transitions --
   function Do_Displacement return Boolean;
   function Do_Initial return Boolean;
   procedure Call (Val : in Boolean; Info : String := "");

   -- overall state of moving
   Current_State : State_Enum := Moving;

   function Get_State return State_Enum is
   begin
      return Current_State;
   end Get_State;

   procedure Set_Initial_State is
   begin
      Current_State := Initial;
   end Set_Initial_State;

   ------ state transitions ------

   function Do_Initial return Boolean is
   begin
      if Current_State /= Initial then
         Current_State := Initial;
         return True;
      else
         return False;
      end if;
   end Do_Initial;

   function Do_Displacement return Boolean is
   begin
      if Current_State = Initial then
         Current_State := Displacing;
         Pace.Log.Put_Line ("Displacing");

         -- for now, let's just remove the parking brake
         -- and put the gear box in drive
         declare
            Msg : Acu.Vehicle.Park_Brake_Control;
         begin
            Msg.Brake_Control := False;
            Pace.Dispatching.Input (Msg);
         end;
         declare
            Msg : Acu.Vehicle.Transmission_Control;
         begin
            Msg.Mode := Mob.Neutral;
            Pace.Dispatching.Input (Msg);
         end;

         Current_State := Moving;
         declare
            Msg : Vehicle_State;
         begin
            Msg.State := Move_State;
            Input (Msg);
         end;

         -- turn flybox mode to steer
--          declare
--             Msg : Uio.Joystick.Set_Mode;
--          begin
--             Msg.Mode := Steering;
--             Pace.Socket.Send (Msg);
--          end;

         return True;
      else
         return False;
      end if;
   end Do_Displacement;

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
      if Cmd = "DISPLACE" then
         Call (Do_Displacement, Cmd);
      elsif Cmd = "INITIAL" then
         Call (Do_Initial, Cmd);
      else
         Call (False, Cmd & " -> Unknown Move State Change attempted");
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

end Uio.State.Move;
