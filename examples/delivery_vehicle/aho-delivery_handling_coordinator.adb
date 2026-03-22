with Pace;
with Pace.Log;
with Pace.Surrogates;
with Pace.Server.Dispatch;

with Ifc.Job_Data;
with Ahd.Delivery_Job;
with Ahd;
with Aho.Drone;
with Aho.Bottle_Shuttle;
with Aho.Box_Shuttle;
with Aho.Bottle_Compartment;
with Aho.Box_Compartment;
with Abk.Technical_Delivery_Direction;
with Hal;

package body Aho.Delivery_Handling_Coordinator is

   function Id is new Pace.Log.Unit_Id;


   task Agent is
   end Agent;

   task body Agent is

   begin
      Pace.Log.Agent_Id (Id);
      loop

         declare
            Num_Items : Integer;
            Items : Ahd.Items_Array;
         begin
            -- wait on this notify
            declare
               Msg : Ahd.Delivery_Job.Start_Delivery_Job;
            begin
               Pace.Dispatching.Inout (Msg);
               -- start shuttles here
               declare
                  use Aho.Box_Shuttle;
                  Inner_Msg : Begin_Delivery_Order;
               begin
                  Inner_Msg.Num_Items := Msg.Num_Items;
                  Pace.Dispatching.Input (Inner_Msg);
               end;
               declare
                  use Aho.Bottle_Shuttle;
                  Inner_Msg : Begin_Delivery_Order;
               begin
                  Inner_Msg.Num_Items := Msg.Num_Items;
                  Pace.Dispatching.Input (Inner_Msg);
               end;
            end;
            -- must wait until flight solution has been calculated before
            -- beginning the indexing of the bottle compartment
            declare
               Msg : Ahd.Delivery_Job.Flight_Solution;
            begin
               Pace.Dispatching.Inout (Msg);
            end;
            declare
               Msg : Aho.Bottle_Compartment.Index_To_Shuttle_Gate;
            begin
               Pace.Surrogates.Input (Msg);
            end;

            declare
               Msg : Aho.Box_Compartment.Index_To_Shuttle_Gate;
            begin
               Pace.Surrogates.Input (Msg);
            end;

            -- wait for configure signal through Ahd interface
            declare
               Msg : Ahd.Delivery_Job.Configure_Equipment;
            begin
               Pace.Dispatching.Inout (Msg);
            end;

            -- go and get delivery job data
            declare
               Msg : Ahd.Delivery_Job.Get_Delivery_Job;
            begin
               Pace.Dispatching.Output (Msg);
               Num_Items := Integer (Ifc.Job_Data.Item_Vector.Length (Msg.Job.Data.Items));
               Items := Msg.Job.Items;
            end;

--             declare
--                use Ico.Fm_Inventory_Coordinator;
--                Msg : Review_Delivery_Order_Message;
--             begin
--                Msg.Num_Items := Num_Items;
--                Pace.Dispatching.Input (Msg);
--             end;

            declare
               use Aho.Drone;
               Msg : Initialize;
            begin
               Msg.Num_Items := Num_Items;
               Msg.Items := Items;
               Pace.Dispatching.Input (Msg);
            end;

            declare
               Msg : Aho.Drone.Aim_Drone;
            begin
               Pace.Dispatching.Input (Msg);
            end;

            -- wait for execute signal through Ahd interface
            declare
               Msg : Ahd.Delivery_Job.Execute_Delivery_Order;
            begin
               Pace.Dispatching.Inout (Msg);
            end;
            declare
               use Aho.Drone;
               Msg : Start_Delivery_Job;
            begin
               Pace.Dispatching.Input (Msg);
            end;
         end;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

end Aho.Delivery_Handling_Coordinator;
