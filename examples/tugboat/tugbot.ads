with Pace;
with Pace.Server.Dispatch;
with Hal.Gazebo_Commands;

--
--  Tugbot -- Warehouse/logistics tugbot robot simulation
--
--  Adapted to the Gazebo 3D 6-DOF "tugbot" SDF model.
--  Following the HumanRobot pattern: two separate Hal.Gazebo_Commands
--  instantiations are used so that joints (position-controlled) and links
--  (pose/velocity-controlled) each have a clean, type-safe enumeration.
--  The shared-memory plugin finds entities by NAME, so both packages can
--  safely share the same key without index conflicts.
--
--  WMI (Woman-Machine Interface) web dispatch action types follow the
--  delivery_vehicle / uio-dbw.ads pattern:
--    - Single-value commands  : set= parameter, e.g. NAVIGATE?set=MOVING_FORWARD
--    - Multi-value commands   : named CGI params, e.g. DRIVE?direction=MOVING_FORWARD&speed=0.8
--    - Status queries         : return XML, e.g. GET_STATUS
--    - Server-push monitoring : live stream, e.g. HEADING_MONITOR
--
--  Revolute / ball joints controlled:
--    warnign_light_joint  (revolute -- spinning beacon)
--    gripper_joint        (revolute -- end-effector arm)
--    gripper_hand_joint   (revolute -- end-effector fingers)
--    wheel_left_joint     (revolute -- left  drive wheel, velocity)
--    wheel_right_joint    (revolute -- right drive wheel, velocity)
--    wheel_front_joint    (ball     -- front caster, physics only)
--    wheel_back_joint     (ball     -- back  caster, physics only)
--
--  Links with pose / angular-velocity commands:
--    base_link, imu_link, warnign_light, camera_front, camera_back,
--    scan_front, scan_back, scan_omni, gripper, gripper_hand,
--    wheel_front, wheel_back, wheel_left, wheel_right
--
--  Ada Singleton Object Pattern
--

package Tugbot is

   pragma Elaborate_Body;

   --
   --  Revolute joints controlled via Set_Pose (JointPosition in Gazebo).
   --  Note: "warnign" matches the typo present in the real tugbot SDF.
   --
   type Joints is (
      warnign_light_joint,   -- revolute: spinning warning beacon
      gripper_joint,         -- revolute: gripper arm
      gripper_hand_joint,    -- revolute: gripper fingers
      wheel_left_joint,      -- revolute: left  drive wheel
      wheel_right_joint      -- revolute: right drive wheel
   );

   --
   --  All 14 SDF links, used for Set_Pose (link pose) and Set_Rot (velocity).
   --  Note: "warnign_light" matches the typo in the real tugbot SDF.
   --
   type Links is (
      base_link,
      imu_link,
      warnign_light,
      camera_front,
      camera_back,
      scan_front,
      scan_back,
      scan_omni,
      gripper,
      gripper_hand,
      wheel_front,
      wheel_back,
      wheel_left,
      wheel_right
   );

   --
   --  Shared-memory interface to the Gazebo TableControlPlugin.
   --  Key 123456 must match SHM_KEY in shared_structs.h / tugbot.sdf plugin.
   --  The plugin dispatches by entity NAME, so both packages safely coexist.
   --
   package Gz_Joints is new Hal.Gazebo_Commands (Key => 123456, Entities => Joints);
   package Gz_Links  is new Hal.Gazebo_Commands (Key => 123456, Entities => Links);

   --
   --  Robot state types
   --
   type Drive_State is (Stopped,
                        Moving_Forward,
                        Moving_Backward,
                        Turning_Left,
                        Turning_Right);

   type Gripper_State is (Open, Closed);

   --
   --  WMI (Woman-Machine Interface) web dispatch action types
   --  Following the delivery_vehicle / uio-dbw.ads pattern.
   --  Types placed in the spec so they can also be called programmatically
   --  via Wmi.Call as well as through the HTTP URL command pattern.
   --

   --  Navigate: single-value direction command
   --  URL:  TUGBOT.NAVIGATE?set=MOVING_FORWARD
   --  Values: STOPPED | MOVING_FORWARD | MOVING_BACKWARD | TURNING_LEFT | TURNING_RIGHT
   type Navigate is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Navigate);

   --  Set_Speed: normalized speed in range [0.0 .. 1.0]
   --  URL:  TUGBOT.SET_SPEED?set=0.8
   type Set_Speed is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Set_Speed);

   --  Drive: joystick-style combined direction + speed (multi CGI params)
   --  URL:  TUGBOT.DRIVE?direction=MOVING_FORWARD&speed=0.8
   type Drive is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Drive);

   --  Gripper_Action: open or close the end-effector
   --  URL:  TUGBOT.GRIPPER?set=CLOSED
   --  Values: OPEN | CLOSED
   type Gripper_Action is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Gripper_Action);

   --  Light: enable or disable the spinning warning beacon
   --  URL:  TUGBOT.LIGHT?set=TRUE
   --  Values: TRUE | FALSE
   type Light is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Light);

   --  Get_Status: XML snapshot of full robot state
   --  URL:  TUGBOT.GET_STATUS
   type Get_Status is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Status);

   --  Heading_Monitor: server-push live heading stream (like delivery_vehicle Compass)
   --  URL:  TUGBOT.HEADING_MONITOR
   type Heading_Monitor is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Heading_Monitor);

   --
   --  Internal simulation start message (kicks off the four simulation tasks)
   --
   type Start is new Pace.Msg with null record;
   procedure Input (Obj : in Start);

end Tugbot;
