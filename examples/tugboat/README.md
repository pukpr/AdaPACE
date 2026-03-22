# Tugbot Simulation

Ada/PACE simulation for the **tugbot** warehouse logistics robot, integrated
with the Gazebo 3D 6-DOF physics model and equipped with a PACE web server for
remote manipulation.

## Architecture

The simulation follows the patterns established by:
- **HumanRobot** – two `Hal.Gazebo_Commands` instantiations; multiple focused
  Ada tasks per subsystem
- **joint_position_controller (Panda)** – clean single-file project, `jpc.sdf`
  style SDF with `libTablePlugin.so` shared-memory bridge
- **SUV** – PACE web server via `UIO.Server.Create`; web dispatch actions

```
tugboat/
├── tugbot.ads          -- Package spec: Joints & Links enums, Gz instances,
│                          PACE message types (Navigate, Set_Gripper, …)
├── tugbot.adb          -- Package body: 4 Ada tasks + web dispatch actions
│      Drive_Task       --   differential-drive kinematics + odometry
│      Sensor_Task      --   sensor link pose propagation
│      Light_Task       --   warning beacon rotation (revolute joint)
│      Gripper_Task     --   gripper/hand servo (revolute joints)
├── tugbot_main.adb     -- Main: UIO.Server + Tugbot.Start + Ses.Pp.Parser
├── tugboat.gpr         -- GNAT project file
├── tugbot.sdf          -- Gazebo world: ground plane + tugbot model
├── session.pro         -- P4 launcher session (Ada proc + gz sim proc)
├── BUILD               -- Build script (gprbuild + ipcrm)
└── RUN                 -- Run script  (env P4PATH … drivers/p4)
```

## Tugbot Articulated Parts

| Link / Joint | Joint Type | Ada enum | Control |
|---|---|---|---|
| `base_link` | root | `Links.base_link` | `Set_Pose` (odometry) |
| `imu_link` | fixed | `Links.imu_link` | `Set_Pose` (heading) |
| `warnign_light` | revolute | `Links.warnign_light` | `Set_Rot` |
| `warnign_light_joint` | revolute | `Joints.warnign_light_joint` | `Set_Pose` (angle) |
| `camera_front` | fixed | `Links.camera_front` | `Set_Pose` |
| `camera_back` | fixed | `Links.camera_back` | `Set_Pose` |
| `scan_front` | fixed | `Links.scan_front` | `Set_Pose` |
| `scan_back` | fixed | `Links.scan_back` | `Set_Pose` |
| `scan_omni` | fixed | `Links.scan_omni` | `Set_Pose` |
| `gripper` | revolute | `Links.gripper` | `Set_Pose` (mirror) |
| `gripper_joint` | revolute | `Joints.gripper_joint` | `Set_Pose` (angle) |
| `gripper_hand` | revolute | `Links.gripper_hand` | `Set_Pose` (mirror) |
| `gripper_hand_joint` | revolute | `Joints.gripper_hand_joint` | `Set_Pose` (angle) |
| `wheel_front` | ball | `Links.wheel_front` | `Set_Pose` (heading) |
| `wheel_back` | ball | `Links.wheel_back` | `Set_Pose` (heading) |
| `wheel_left` | revolute | `Links.wheel_left` | `Set_Rot` (ω) |
| `wheel_left_joint` | revolute | `Joints.wheel_left_joint` | `Set_Pose` (ω) |
| `wheel_right` | revolute | `Links.wheel_right` | `Set_Rot` (ω) |
| `wheel_right_joint` | revolute | `Joints.wheel_right_joint` | `Set_Pose` (ω) |

> **Note:** `warnign_light` preserves the typo present in the original tugbot
> Gazebo model. The TableControlPlugin finds entities by name string, so this
> must match exactly.

## Gazebo Interface

Both Ada packages share SHM key **123456** (matching `SHM_KEY` in
`shared_structs.h`). The `TableControlPlugin` dispatches commands by entity
**name** (not by array index), so two simultaneous `Hal.Gazebo_Commands`
instantiations are safe:

```ada
package Gz_Joints is new Hal.Gazebo_Commands (Key => 123456, Entities => Joints);
package Gz_Links  is new Hal.Gazebo_Commands (Key => 123456, Entities => Links);
```

Command routing inside the plugin:
- **Command 0 (`Set_Pose`)** → `JointPosition` if a joint, else `Pose` for links
- **Command 1 (`Set_Rot`)** → `SetAngularVelocity` on the link
- **Command 2 (`Set_Torque`)** → `JointForceCmd` or `AddWorldWrench`

## Build

```bash
cd examples/tugboat
bash BUILD
```

Requires GNAT, `gprbuild`, and the PACE library (`pace.gpr` at `../../`).

## Run

```bash
bash RUN
```

Requires Gazebo Sim (`gz sim`), `libTablePlugin.so` built in
`../../plugins/gazebo/`, and the P4 distributed launcher in `../../drivers/`.

## Remote Manipulation (PACE Web Server)

After launch the web server listens on port **8080** by default
(set `PACE_PORT` env var to change).

### Navigate

```bash
# Forward at 80 % speed
curl "http://localhost:8080/Tugbot.Navigate_Action?set=<xml><direction>forward</direction><speed>0.8</speed></xml>"

# Turn left at 50 %
curl "http://localhost:8080/Tugbot.Navigate_Action?set=<xml><direction>left</direction><speed>0.5</speed></xml>"

# Stop
curl "http://localhost:8080/Tugbot.Navigate_Action?set=<xml><direction>stop</direction></xml>"
```

### Gripper

```bash
curl "http://localhost:8080/Tugbot.Gripper_Action?set=<xml><state>close</state></xml>"
curl "http://localhost:8080/Tugbot.Gripper_Action?set=<xml><state>open</state></xml>"
```

### Warning Beacon

```bash
curl "http://localhost:8080/Tugbot.Light_Action?set=<xml><enabled>true</enabled></xml>"
curl "http://localhost:8080/Tugbot.Light_Action?set=<xml><enabled>false</enabled></xml>"
```

### Status Query

```bash
curl "http://localhost:8080/Tugbot.Status_Action"
# Returns: <status><drive>STOPPED</drive><gripper>OPEN</gripper>
#           <light>FALSE</light><x>0.0</x><y>0.0</y><heading>0.0</heading></status>
```
