with Ada.Task_Attributes;

package body Pace.Signals.Tid is

   type Slot is access Pace.Signals.Event;

   package Task_Events is new Ada.Task_Attributes (Slot, null);

   procedure Signal (Id : Ada.Task_Identification.Task_Id) is
   begin
      Task_Events.Value (Id).Signal;
   end Signal;

   procedure Signal (Msg : Pace.Msg'Class) is
   begin
      Task_Events.Value (Msg.Id).Signal;
   end Signal;

   procedure Wait is
      Id : constant Ada.Task_Identification.Task_Id :=
         Ada.Task_Identification.Current_Task;
   begin
      if Task_Events.Value (Id) = null then
         Task_Events.Set_Value (new Pace.Signals.Event, Id);
      end if;
      Task_Events.Value (Id).Suspend;
   end Wait;

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-signals-tid.adb,v 1.1 09/16/2002 18:18:48 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Signals.Tid;
