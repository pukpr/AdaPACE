with Pace.Log;
with Pace.Socket;
with Orchestra;

package body Producer_Pkg is

   task Producer;
   task body Producer is
      function ID is new Pace.Log.Unit_ID;
      Msg : Orchestra.Raw_Data;
      Count : Integer := 0;
   begin
      Pace.Log.Agent_Id (ID);
      Pace.Log.Wait (1.0); -- Simulation wait

      loop
         Count := Count + 1;
         Msg.Serial := Count;
         Pace.Log.Put_Line ("Producer: Generating data #" & Integer'Image(Count));
         Pace.Socket.Send (Msg);
         Pace.Log.Wait (10.0); -- Wait 10 simulated seconds
      end loop;
   end Producer;

end Producer_Pkg;
