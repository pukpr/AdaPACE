with Pace.Log;
with Pace.Multicast;
with Pace.Config;

package body Gis.Unit_Multicaster is

   function Id is new Pace.Log.Unit_Id;
   function Name return String renames Pace.Log.Name;

   -- for when using multiple ssom's with multicast to avoid
   -- multiple simulation problems.  Only process messages that match network_id
   Network_Id : Integer := Integer'Value (Pace.Getenv ("FCS_NETWORK_ID", "0"));

   task Agent is
      pragma Task_Name (Name);
   end Agent;
   task body Agent is

   begin
      Pace.Log.Agent_Id (Id);

      Pace.Log.Wait (5.0);

      declare
         Tx : Pace.Multicast.Sender;
         Rx : Pace.Multicast.Receiver;

         Address : String := Pace.Config.Get_String ("multicast_address",
                                                     "unit_tracker");
      begin
         Tx := Pace.Multicast.Create (Address);
         Rx := Pace.Multicast.Create (Address);

         loop
            Pace.Log.Wait (Broadcast_Interval);

            declare
               Broadcast_Msg : Gis.Unit_Tracker.Update_Unit;
            begin
               Broadcast_Msg.Unit.Id := Unit_Id;
               Broadcast_Msg.Unit.Side := Side;
               Broadcast_Msg.Unit.Location := Get_Location;
               Broadcast_Msg.Network_Id := Network_Id;
               Pace.Multicast.Send (Tx, Broadcast_Msg);
            end;

         end loop;
      end;
   exception
      when E: Pace.Config.Not_Found =>
         Pace.Log.Put_Line ("NOTE: GIS Unit Multicasting address not found in Kbase!");
      when Event: others =>
         Pace.Log.Ex (Event);
   end Agent;

end Gis.Unit_Multicaster;
