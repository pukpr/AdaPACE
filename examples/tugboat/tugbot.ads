with Pace;
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
   --  Ada Command Pattern Operation Specs
   --

   --  Navigate: set drive direction and normalised speed [0.0 .. 1.0]
   type Navigate is new Pace.Msg with
      record
         Direction : Drive_State := Stopped;
         Speed     : Long_Float  := 1.0;
      end record;
   procedure Input (Obj : in Navigate);

   --  Set_Gripper: open or close the end-effector
   type Set_Gripper is new Pace.Msg with
      record
         State : Gripper_State := Open;
      end record;
   procedure Input (Obj : in Set_Gripper);

   --  Set_Warning_Light: enable/disable the revolute warning beacon
   type Set_Warning_Light is new Pace.Msg with
      record
         Enabled : Boolean := False;
      end record;
   procedure Input (Obj : in Set_Warning_Light);

   --  Get_Status: non-blocking snapshot of current robot state (Output pattern)
   type Get_Status is new Pace.Msg with
      record
         Drive   : Drive_State   := Stopped;
         Gripper : Gripper_State := Open;
         Light   : Boolean       := False;
         X       : Long_Float    := 0.0;
         Y       : Long_Float    := 0.0;
         Heading : Long_Float    := 0.0;
      end record;
   procedure Output (Obj : out Get_Status);

   --  Start: kick off the simulation agent loop
   type Start is new Pace.Msg with null record;
   procedure Input (Obj : in Start);

end Tugbot;
