with Tugbot;
with Pace.Log;
with UIO.Server;
with Ses.Pp;

--
--  Tugbot main driver.
--
--  Starts the PACE web server for remote manipulation, then sends the Start
--  command to the Tugbot package which brings the four simulation tasks
--  (Drive_Task, Sensor_Task, Light_Task, Gripper_Task) to life.
--  Finally calls Ses.Pp.Parser for P4 distributed-launcher integration.
--
--  Following the SUV driver pattern (suv-driver.adb) for web server creation
--  and the HumanRobot walk_main.adb pattern for Ses.Pp.Parser integration.
--
procedure Tugbot_Main is
   Msg : Tugbot.Start;
begin
   --  Create the PACE web server thread pool (configurable via env vars
   --  MAX_CLIENTS and MAX_STACK; defaults: 10 threads, 1 MB stack each)
   UIO.Server.Create;
   Pace.Log.Agent_ID;
   Pace.Log.Put_Line ("Tugbot web server ready.");

   --  Start the Tugbot simulation agent (drives all Gazebo link commands)
   Tugbot.Input (Msg);

   --  P4 distributed-launcher integration (blocks until shutdown signal)
   Ses.Pp.Parser;

exception
   when others =>
      Ses.Os_Exit (0);
end Tugbot_Main;
