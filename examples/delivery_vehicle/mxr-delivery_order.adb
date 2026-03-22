with Wmi;

with Pace;
with Pace.Notify;
with Pace.Queue.Guarded;
with Pace.Server.Dispatch;
with Pace.Server.Peek_Factory;
with Pace.Surrogates;
with Pace.Log;
with Pace.Jobs;

with Ifc.Delivery_Job;
with Uio.Route;
with Uio.Job_Audio_Alert;
with Acu;
with Vkb;
with Ahd;
with Ahd.Delivery_Job;
with Ifc.Job_Data;

package body Mxr.Delivery_Order is

   function Id is new Pace.Log.Unit_Id;

   use Str;

   -- this is set to true when a job is received and set to false when the crew
   -- clears the job at the end!
   Job_Received : Boolean := False;
   function Peek_Job_Received return String is
   begin
      return Job_Received'Img;
   end Peek_Job_Received;
   package Job_Received_Img is
     new Pace.Server.Peek_Factory (Peek_Job_Received);

   -- queue to hold any call for deliverys
   package Queue is new Pace.Queue (Bstr.Bounded_String, Fifo => True);
   package Delivery_Order_Queue is new Queue.Guarded;

   -- main task lets the agent task know that the queue has been updated
   type Queue_Update is new Pace.Notify.Subscription with null record;

   -- used internally when a publish occurs.. essentially makes the publish/subscribe synchronous
   type Job_Done is new Pace.Notify.Subscription with null record;

   -- used for publishing to Delivery_Job_Complete subscription
   type Mxr_Delivery_Job_Complete is new
     Ahd.Delivery_Job.Delivery_Job_Complete with null record;
   procedure Input (Obj : in Mxr_Delivery_Job_Complete);
   procedure Input (Obj : in Mxr_Delivery_Job_Complete) is
   begin
      declare
         Msg : Job_Done;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Input;

   task Agent is
      entry Input (Obj : in Clear_Delivery_Order_Received);
   end Agent;

   task body Agent is
      Job_Id : Bstr.Bounded_String;
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
         Delivery_Order_Queue.Get (Job_Id);

         Pace.Log.Put_Line ("kbase id is " & (+Job_Id), 4);
         declare
            Msg : Uio.Job_Audio_Alert.Begin_Alert;
         begin
            Pace.Dispatching.Input (Msg);
         end;

         declare
            Msg : Uio.Route.Load_Customer;
            use Pace.Server.Dispatch;
         begin
            Msg.Set := +Job_Id;
            Pace.Dispatching.Inout (Msg);
         end;

         declare
            Msg : Ifc.Delivery_Job.Accept_Delivery_Order;
         begin
            Msg.Id := Job_Id;
            Pace.Dispatching.Inout (Msg);
            Job_Received := True;
            declare
               Msg : Wait_For_Job_Received;
            begin
               -- don't block since most of time no one will be on other end
               Msg.Ack := False;
               Input (Msg);
            end;

            declare
               Result : String := "<html><body>" & "Delivery Order " &
                                    (+Job_Id) &
                                    " accepted" & "</body></html>";
            begin
               Pace.Server.Put_Data (Result);
            end;

            -- if the vehicle is already docked then let the audio play once and end it
            declare
               Msg : Acu.Vehicle.Emplacement_Status;
            begin
               Pace.Dispatching.Output (Msg);
               if Msg.Is_Emplaced then
                  declare
                     Msg : Uio.Job_Audio_Alert.End_Alert;
                  begin
                     Pace.Dispatching.Input (Msg);
                  end;
               end if;
            end;

         end;

         -- wait for the crew to clear the delivery job before moving on
         accept Input (Obj : in Clear_Delivery_Order_Received) do
            Job_Received := False;
         end Input;

      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;


   procedure Inout (Obj : in out Is_Delivery_Order_Received) is
   begin
      Obj.Val := Job_Received;
   end Inout;

   procedure Input (Obj : in Clear_Delivery_Order_Received) is
   begin
      Agent.Input (Obj);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Add_To_Queue (Job_Id : Str.Bstr.Bounded_String) is
   begin
      Delivery_Order_Queue.Put (Job_Id);
      -- in case the agent task is waiting on the update_queue, notify it, but don't block!
      declare
         Msg : Queue_Update;
      begin
         Msg.Ack := False;
         Pace.Dispatching.Input (Msg);
      end;
   end Add_To_Queue;

   -- the Action taken by a scheduled delivery job or a delivery job coming do
   -- input method must end when delivery job is done
   type Execute_Delivery_Job is new Pace.Msg with
      record
         Job_Id : Bstr.Bounded_String;
      end record;
   procedure Input (Obj : in Execute_Delivery_Job);
   procedure Input (Obj : in Execute_Delivery_Job) is
   begin

      -- subscribe to Delivery_Job_Complete subscription
      declare
         use Ahd.Delivery_Job;
         Msg : Mxr_Delivery_Job_Complete;
      begin
         Ahd.Delivery_Job.Input (Delivery_Job_Complete (Msg));
      end;

      -- START THE DELIVERY JOB
      Add_To_Queue (Obj.Job_Id);

      -- WAIT UNTIL DELIVERY JOB IS COMPLETED!
      declare
         Msg : Job_Done;
      begin
         Pace.Log.Put_Line ("Job surrogate within mxr is waiting for delivery job to complete");
         Inout (Msg);
         Pace.Log.Put_Line ("Job surrogate within mxr is done waiting for job to complete");
      end;

   end Input;

   procedure Inout (Obj : in out Call_For_Delivery) is
      Job_Id : Bstr.Bounded_String := +Pace.Server.Keys.Value ("set", U2s (Obj.Set));
      Job : Ifc.Job_Data.Delivery_Job_Data;
      Found_It : Boolean;
   begin

      Ifc.Job_Data.Get_Delivery_Job (Job_Id, Found_It, Job);
      if not Found_It then
         Pace.Log.Put_Line ("Delivery Job " & (+Job_Id) & " could not be found!");
      else
         Pace.Log.Put_Line ("schedule job");
         declare
            J : Pace.Jobs.Job;
            A : Execute_Delivery_Job;
         begin
            J.Unique_Id := +("job_" & (+Job_Id) & Pace.Jobs.Get_Next_Id_Counter);
            J.Start_Time := Job.Start_Time;
            -- approximation
            J.Expected_Duration := 10.0 + Duration (8.5 * Float (Ifc.Job_Data.Item_Vector.Length (Job.Items)));
            A.Job_Id := Job_Id;
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

