with Pace.Log;
with Pace.Socket.Publisher;
with Pace.Server.Dispatch;
with Str;

package body Ahd.Delivery_Mission is

   use Ifc.Fm_Data.Item_Vector;

   Fms_Completed : Integer := 0;

   -- current Delivery Mission data is stored here
   Mission : Mission_Record;

   Mission_Ready : Boolean := False;

   -- list of subscribers to Delivery_Mission_Complete signal
   Fm_List : Pace.Socket.Publisher.Subscription_List (100);

   procedure Input (Obj : in Delivery_Mission_Complete) is
   begin
      Pace.Socket.Publisher.Subscribe (Fm_List, Obj);
   end Input;

   procedure Publish_Delivery_Mission_Complete is
      use Str;
      Msg : Delivery_Mission_Complete;
   begin
      Fms_Completed := Fms_Completed + 1;
      Pace.Socket.Publisher.Publish (Fm_List, Msg);

      -- clear out mission
      Mission_Ready := False;
   end Publish_Delivery_Mission_Complete;

   function Get_Fms_Completed return Integer is
   begin
      return Fms_Completed;
   end Get_Fms_Completed;

   -- used to synch up getting a delivery mission with processing it
   type Mission_Is_Ready is new Pace.Notify.Subscription with null record;

   procedure Input (Obj : in Delivery_Solution) is
   begin
      -- assign delivery mission data
      Mission := Obj.Mission;
      Mission_Ready := True;

      -- send out signal that mission is ready for use
      declare
         Msg : Mission_Is_Ready;
      begin
         -- may not be any listeners, so don't block
         Msg.Ack := False;
         Input (Msg);
      end;

   end Input;

   procedure Input (Obj : in Configure) is
   begin

      -- send out configure notify to any listeners
      declare
         Msg : Ahd.Delivery_Mission.Configure_Equipment;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Input;

   procedure Output (Obj : out Get_Delivery_Mission) is
   begin
      -- check to see if mission is ready
      if not Mission_Ready then
         declare
            Msg : Mission_Is_Ready;
         begin
            Inout (Msg);
         end;
      end if;
      Obj.Mission := Mission;
   end Output;

   procedure Input (Obj : in Adjust_Items) is
   begin
      Mission.Items := Obj.Items;
   end Input;

   type Peek_Fms_Completed is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Peek_Fms_Completed);

   procedure Inout (Obj : in out Peek_Fms_Completed) is
      use Pace.Server.Dispatch;
      use Str;
   begin
      Obj.Set := S2u(Integer'Image (Fms_Completed));
      Pace.Server.Put_Data (U2s(Obj.Set));
   end Inout;

   function Has_Target return Boolean is
      use Ifc.Fm_Data;
   begin
      if Is_Empty (Mission.Data.Items) then
         return False;
      elsif Has_Target (Mission.Data) then
         return True;
      else
         return False;
      end if;
   end Has_Target;

   function Get_Delivery_Time (Index : Integer) return Duration is
   begin
      return Mission.Items (Index).Delivery_Time;
   exception
      when E : Constraint_Error =>
         Pace.Log.Ex (E);
         return 0.0;
   end Get_Delivery_Time;

   function Is_Time_On_Target return Boolean is
   begin
      if Is_Empty (Mission.Data.Items) then
         return False;
      elsif Str.Bstr.To_String (Mission.Data.Control) = "Time On Target" then
         return True;
      else
         return False;
      end if;
   end Is_Time_On_Target;

   use Pace.Server.Dispatch;
begin
   Save_Action (Peek_Fms_Completed'(Pace.Msg with Set => Default));
end Ahd.Delivery_Mission;
