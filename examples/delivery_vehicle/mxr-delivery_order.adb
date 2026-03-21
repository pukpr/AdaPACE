with Wmi;

with Pace;
with Pace.Notify;
with Pace.Queue.Guarded;
with Pace.Server.Dispatch;
with Pace.Server.Peek_Factory;
with Pace.Surrogates;
with Pace.Log;
with Pace.Jobs;

with Ifc.Delivery_Mission;
with Uio.Route;
with Uio.Mission_Audio_Alert;
with Acu;
with Vkb;
with Ahd;
with Ahd.Delivery_Mission;
with Ifc.Fm_Data;

package body Mxr.Delivery_Order is

   function Id is new Pace.Log.Unit_Id;

   use Str;

   -- this is set to true when a mission is received and set to false when the crew
   -- clears the mission at the end!
   Mission_Received : Boolean := False;
   function Peek_Mission_Received return String is
   begin
      return Mission_Received'Img;
   end Peek_Mission_Received;
   package Mission_Received_Img is
     new Pace.Server.Peek_Factory (Peek_Mission_Received);

   -- queue to hold any call for deliverys
   package Queue is new Pace.Queue (Bstr.Bounded_String, Fifo => True);
   package Delivery_Order_Queue is new Queue.Guarded;

   -- main task lets the agent task know that the queue has been updated
   type Queue_Update is new Pace.Notify.Subscription with null record;

   -- used internally when a publish occurs.. essentially makes the publish/subscribe synchronous
   type Fm_Done is new Pace.Notify.Subscription with null record;

   -- used for publishing to Delivery_Mission_Complete subscription
   type Mxr_Delivery_Mission_Complete is new
     Ahd.Delivery_Mission.Delivery_Mission_Complete with null record;
   procedure Input (Obj : in Mxr_Delivery_Mission_Complete);
   procedure Input (Obj : in Mxr_Delivery_Mission_Complete) is
   begin
      declare
         Msg : Fm_Done;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Input;

   task Agent is
      entry Input (Obj : in Clear_Delivery_Order_Received);
   end Agent;

   task body Agent is
      Mission_Id : Bstr.Bounded_String;
   begin
      Pace.Log.Agent_Id (Id);

      loop
         -- if queue is empty then wait for the notify
         if not Delivery_Order_Queue.Is_Ready then
            declare
               Msg : Queue_Update;
            begin
               Pace.Dispatching.Inout (Msg);
            end;
         end if;

         -- get id from queue
         Delivery_Order_Queue.Get (Mission_Id);

         Pace.Log.Put_Line ("kbase id is " & (+Mission_Id), 4);
         declare
            Msg : Uio.Mission_Audio_Alert.Begin_Alert;
         begin
            Pace.Dispatching.Input (Msg);
         end;

         declare
            Msg : Uio.Route.Load_Target;
            use Pace.Server.Dispatch;
         begin
            Msg.Set := +Mission_Id;
            Pace.Dispatching.Inout (Msg);
         end;

         declare
            Msg : Ifc.Delivery_Mission.Accept_Delivery_Order;
         begin
            Msg.Id := Mission_Id;
            Pace.Dispatching.Inout (Msg);
            Mission_Received := True;
            declare
               Msg : Wait_For_Mission_Received;
            begin
               -- don't block since most of time no one will be on other end
               Msg.Ack := False;
               Input (Msg);
            end;

            declare
               Result : String := "<html><body>" & "Delivery Order " &
                                    (+Mission_Id) &
                                    " accepted" & "</body></html>";
            begin
               Pace.Server.Put_Data (Result);
            end;

            -- if the vehicle is already emplaced then let the audio play once and end it
            declare
               Msg : Acu.Vehicle.Emplacement_Status;
            begin
               Pace.Dispatching.Output (Msg);
               if Msg.Is_Emplaced then
                  declare
                     Msg : Uio.Mission_Audio_Alert.End_Alert;
                  begin
                     Pace.Dispatching.Input (Msg);
                  end;
               end if;
            end;

         end;

         -- wait for the crew to clear the delivery mission before moving on
         accept Input (Obj : in Clear_Delivery_Order_Received) do
            Mission_Received := False;
         end Input;

      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;


   procedure Inout (Obj : in out Is_Delivery_Order_Received) is
   begin
      Obj.Val := Mission_Received;
   end Inout;

   procedure Input (Obj : in Clear_Delivery_Order_Received) is
   begin
      Agent.Input (Obj);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Add_To_Queue (Mission_Id : Str.Bstr.Bounded_String) is
   begin
      Delivery_Order_Queue.Put (Mission_Id);
      -- in case the agent task is waiting on the update_queue, notify it, but don't block!
      declare
         Msg : Queue_Update;
      begin
         Msg.Ack := False;
         Pace.Dispatching.Input (Msg);
      end;
   end Add_To_Queue;

   -- the Action taken by a scheduled delivery mission or a delivery mission coming do
   -- input method must end when delivery mission is done
   type Execute_Delivery_Mission is new Pace.Msg with
      record
         Mission_Id : Bstr.Bounded_String;
      end record;
   procedure Input (Obj : in Execute_Delivery_Mission);
   procedure Input (Obj : in Execute_Delivery_Mission) is
   begin

      -- subscribe to Delivery_Mission_Complete subscription
      declare
         use Ahd.Delivery_Mission;
         Msg : Mxr_Delivery_Mission_Complete;
      begin
         Ahd.Delivery_Mission.Input (Delivery_Mission_Complete (Msg));
      end;

      -- START THE DELIVERY MISSION
      Add_To_Queue (Obj.Mission_Id);

      -- WAIT UNTIL DELIVERY MISSION IS COMPLETED!
      declare
         Msg : Fm_Done;
      begin
         Pace.Log.Put_Line ("Job surrogate within mxr is waiting for delivery mission to complete");
         Inout (Msg);
         Pace.Log.Put_Line ("Job surrogate within mxr is done waiting for fm to complete");
      end;

   end Input;

   procedure Inout (Obj : in out Call_For_Delivery) is
      Mission_Id : Bstr.Bounded_String := +Pace.Server.Keys.Value ("set", U2s (Obj.Set));
      Mission : Ifc.Fm_Data.Delivery_Mission_Data;
      Found_It : Boolean;
   begin

      Ifc.Fm_Data.Get_Delivery_Mission (Mission_Id, Found_It, Mission);
      if not Found_It then
         Pace.Log.Put_Line ("Delivery Mission " & (+Mission_Id) & " could not be found!");
      else
         Pace.Log.Put_Line ("schedule mission");
         declare
            J : Pace.Jobs.Job;
            A : Execute_Delivery_Mission;
         begin
            J.Unique_Id := +("fm_" & (+Mission_Id) & Pace.Jobs.Get_Next_Id_Counter);
            J.Start_Time := Mission.Start_Time;
            -- approximation
            J.Expected_Duration := 10.0 + Duration (8.5 * Float (Ifc.Fm_Data.Item_Vector.Length (Mission.Items)));
            A.Mission_Id := Mission_Id;
            J.Action := Pace.To_Channel_Msg (A);
            Pace.Surrogates.Input (J);
         end;
      end if;

      Pace.Log.Trace (Obj);
   end Inout;

   use Pace.Server.Dispatch;

begin
   Save_Action (Call_For_Delivery'(Pace.Msg with Set => +"1"));
end Mxr.Delivery_Order;

