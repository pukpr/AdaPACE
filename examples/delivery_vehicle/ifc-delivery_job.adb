
with Pace.Log;
with Pace.Surrogates;
with Ahd.Job_Order_Status;
with Ahd.Delivery_Job;
with Ahd;
with Vkb;
with Nav.Location;
with Hal;
with Ada.Strings.Unbounded;
with Abk.Technical_Delivery_Direction;
with Str;
with Ifc.Job_Data;
with Plant;

package body Ifc.Delivery_Job is

   function Id is new Pace.Log.Unit_Id;

   package Asu renames Ada.Strings.Unbounded;

   use Str;

   Delivery_Job_Id : Bstr.Bounded_String := +"1";

   -- used internally when a publish occurs.. essentially makes the publish/subscribe synchronous
   type Job_Done is new Pace.Notify.Subscription with null record;

   -- used for publishing to Delivery_Job_Complete subscription
   type Ifc_Delivery_Job_Complete is new
     Ahd.Delivery_Job.Delivery_Job_Complete with null record;
   procedure Input (Obj : in Ifc_Delivery_Job_Complete);
   procedure Input (Obj : in Ifc_Delivery_Job_Complete) is
   begin
      declare
         Msg : Job_Done;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Input;

   -- to satisfy timeline
   type Flight_To_Index is new Pace.Msg with null record;
   procedure Input (Obj : in Flight_To_Index);
   procedure Input (Obj : in Flight_To_Index) is
   begin
      declare
         Msg : Abk.Technical_Delivery_Direction.Calculate_Flight_Solution;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Ahd.Delivery_Job.Flight_Solution;
      begin
         -- don't block here since there may be no one waiting
         Msg.Ack := False;
         Pace.Dispatching.Input (Msg);
      end;
   end Input;


   procedure Job_Order_Status_Setup (Num_Items : Integer) is
      Msg : Ahd.Job_Order_Status.Box_Setup;
   begin
      Msg.Num_Boxs := Num_Items;
      Pace.Dispatching.Input (Msg);
   end Job_Order_Status_Setup;

   -- accesses kbase with Delivery_Job_Id and sends data to
   -- ahd.delivery_job
   procedure Send_Data_To_Ahd is
      use Vkb.Rules;

      Job : Ahd.Job_Record;
      Found_It : Boolean;
   begin

      Ifc.Job_Data.Get_Delivery_Job (Delivery_Job_Id, Found_It, Job.Data);
      if not Found_It then
         Pace.Log.Put_Line ("Delivery Job " & (+Delivery_Job_Id) & " could not be found!");
         raise Vkb.Rules.No_Match;
      end if;

      declare
         Msg : Ahd.Delivery_Job.Start_Delivery_Job;
      begin
         Msg.Num_Items := Natural (Ifc.Job_Data.Item_Vector.Length (Job.Data.Items));
         Pace.Dispatching.Input (Msg);
      end;

      Job_Order_Status_Setup (Natural (Ifc.Job_Data.Item_Vector.Length (Job.Data.Items)));

      -- do flight calculations
      declare
         Msg : Flight_To_Index;
      begin
         Pace.Surrogates.Input (Msg);
      end;
      declare
         Msg : Abk.Technical_Delivery_Direction.Perform_Technical_Delivery_Direction;
      begin
         Msg.Job := Job;
         Pace.Dispatching.Inout (Msg);
         Job := Msg.Job;
      end;

      -- trigger the Ahd layer to start
      declare
         Msg : Ahd.Delivery_Job.Delivery_Solution;
      begin
         Msg.Job := Job;
         Pace.Dispatching.Input (Msg);
      end;

   exception
      when E: Constraint_Error =>
         Pace.Log.Ex (E);
      when E: No_Match =>
         Pace.Log.Ex (E);
         Pace.Log.Put_Line
           ("Kbase error during accessing of delivery_job.pro.");
   end Send_Data_To_Ahd;


   function Get_Delivery_Job_Id return Str.Bstr.Bounded_String is
   begin
      return Delivery_Job_Id;
   end Get_Delivery_Job_Id;


   procedure Output (Obj : out Check_Azimuth) is
      use Ifc.Job_Data.Item_Vector;
      Job : Ifc.Job_Data.Delivery_Job_Data;
      Found_It : Boolean;
      I : Integer;
   begin
      -- must go and get the customer locations.. may or may not be in job data
      -- in ahd yet
      Ifc.Job_Data.Get_Delivery_Job (Delivery_Job_Id, Found_It, Job);
      if not Found_It then
         Pace.Log.Put_Line ("Delivery Job " & (+Delivery_Job_Id) & " could not be found!");
         raise Vkb.Rules.No_Match;
      end if;

      if Ifc.Job_Data.Has_Customer (Job) then
         -- check it for each item
         Obj.Within_Azimuth := True;
         I := First_Index (Job.Items);
         while Obj.Within_Azimuth = True and I <= Last_Index (Job.Items) loop
            declare
               Msg : Nav.Location.Track_Heading;
            begin
               Msg.Target_Easting := Element (Job.Items, I).Customer.Easting;
               Msg.Target_Northing := Element (Job.Items, I).Customer.Northing;
               Pace.Dispatching.Inout (Msg);
               -- Msg.Heading_Difference is always positive
               if Msg.Heading_Difference > Hal.Rads (Plant.Max_Traverse_Angle) then
                  Pace.Log.Put_Line ("azimuth NOT okay.. heading difference on item " &
                                     I'Img & " is " & Float'Image (Hal.Degs (Msg.Heading_Difference)));
                  Obj.Within_Azimuth := False;
               end if;
            end;
            I := I + 1;
         end loop;
      else
         -- if there is no customer then always within azimuth
         Obj.Within_Azimuth := True;
      end if;
      Pace.Log.Trace (Obj);
   end Output;


   task Agent is
      entry Inout (Obj : in out Accept_Delivery_Order);
   end Agent;

   -- takes notify from UI layer, access kbase, and passes notify onto
   -- ahd layer with data from kbase.
   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);

      -- subscribe to Delivery_Job_Complete subscription
      declare
         use Ahd.Delivery_Job;
         Msg : Ifc_Delivery_Job_Complete;
      begin
         Ahd.Delivery_Job.Input (Delivery_Job_Complete (Msg));
      end;

      loop

         -- wait to be triggered by ui
         accept Inout (Obj : in out Accept_Delivery_Order) do
            Delivery_Job_Id := Obj.Id;
         end Inout;
         Send_Data_To_Ahd;

         -- wait for end of delivery job from ahd before moving on
         declare
            Msg : Job_Done;
         begin
            Pace.Dispatching.Inout (Msg);
         end;

         -- assert to kbase that delivery job is done
         declare
            Msg : Vkb.Query;
         begin
            Msg.Set := Ada.Strings.Unbounded.To_Unbounded_String
                         ("assert(fm_completed(" &
                          (+Delivery_Job_Id) & "))");
            Pace.Dispatching.Inout (Msg);
         end;

      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   type Release_Travel_Lock is new Pace.Msg with null record;
   procedure Input (Obj : Release_Travel_Lock);
   procedure Input (Obj : Release_Travel_Lock) is
   begin
      Pace.Log.Wait (3.0);
      Pace.Log.Trace (Obj);
   end Input;

   -- all delivery jobs are accepted at the moment
   -- should deny those that don't have a valid kbase id
   procedure Inout (Obj : in out Accept_Delivery_Order) is
   begin
      Agent.Inout (Obj);
--       declare
--          Msg : Release_Travel_Lock;
--       begin
--          Pace.Surrogates.Input (Msg);
--       end;
      Pace.Log.Wait (3.0);
      Obj.Job_Accepted := True;
      Pace.Log.Trace (Obj);
   end Inout;


end Ifc.Delivery_Job;
