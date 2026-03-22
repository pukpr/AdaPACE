with Tugbot;
with Wmi;
with Pace.Log;

--
--  Tugbot main driver.
--
--  Uses Wmi (Woman-Machine Interface = Uio.Server) following the
--  delivery_vehicle / demo_drone.adb pattern:
--
--    Wmi.Create  -- starts the HTTP web server + P4 distributed-launcher
--                   parser task (both in one call, no separate Ses.Pp.Parser)
--
--    Wmi.Call    -- programmatic dispatch: triggers a web action directly,
--                   bypassing HTTP (like demo_drone / eng-test usage)
--
--    Wmi.P       -- builds a CGI query parameter: Wmi.P("set", "TRUE")
--
--  URL scheme after launch:
--    TUGBOT.NAVIGATE?set=MOVING_FORWARD
--    TUGBOT.SET_SPEED?set=0.8
--    TUGBOT.DRIVE?direction=MOVING_FORWARD&speed=0.8
--    TUGBOT.GRIPPER?set=CLOSED
--    TUGBOT.LIGHT?set=TRUE
--    TUGBOT.GET_STATUS
--    TUGBOT.HEADING_MONITOR
--

procedure Tugbot_Main is
   Msg : Tugbot.Start;
begin
   --  Start the HTTP web server and the P4 distributed-launcher parser task.
   --  Wmi.Create = Uio.Server.Create which internally spawns a Parser_Task
   --  running Ses.Pp.Parser -- no separate Ses.Pp.Parser call needed.
   Wmi.Create;
   Pace.Log.Agent_ID;
   Pace.Log.Put_Line ("Tugbot WMI ready.");

   --  Start the four Gazebo simulation tasks
   --  (Drive_Task, Sensor_Task, Light_Task, Gripper_Task).
   Tugbot.Input (Msg);

   --  Demonstrate Wmi.Call: programmatic dispatch at startup.
   --  Wmi.Call bypasses HTTP and calls Dispatch_To_Action directly.
   --  This enables the warning beacon immediately on robot power-on,
   --  following the demo_drone.adb / eng-test.adb usage pattern.
   Wmi.Call (Query  => "tugbot.light",
             Params => Wmi.P ("set", "TRUE"));

end Tugbot_Main;
