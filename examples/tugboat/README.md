# Tugbot Simulation

Ada/PACE simulation for the **tugbot** warehouse logistics robot, integrated
with the Gazebo 3D 6-DOF physics model and equipped with a WMI (Web-Machine
Interface) web server for remote manipulation.

## Architecture

The simulation follows the patterns established by:
- **HumanRobot** — two `Hal.Gazebo_Commands` instantiations; multiple focused
  Ada tasks per subsystem
- **joint_position_controller (Panda)** — `libTablePlugin.so` SDF shared-memory bridge
- **delivery_vehicle (`uio-dbw.adb`)** — web dispatch action types, `use Pace.Server.Dispatch`,
  `Drive_State'Value(+Obj.Set)`, `Pace.Server.Keys.Value`, `Pace.Server.Xml.Item`
- **`demo_drone.adb`** — `Wmi.Create` + `Wmi.Call` pattern

```
tugboat/
├── tugbot.ads          -- Package spec: Joints & Links enums, Gz instances,
│                          WMI Action types (Navigate, Set_Speed, Drive,
│                          Gripper, Light, Get_Status, Heading_Monitor)
├── tugbot.adb          -- Package body: 4 Ada tasks + WMI dispatch bodies
│      Drive_Task       --   differential-drive kinematics + odometry
│      Sensor_Task      --   sensor link pose propagation
│      Light_Task       --   warning beacon rotation (revolute joint)
│      Gripper_Task     --   gripper/hand servo (revolute joints)
├── tugbot_main.adb     -- Main: Wmi.Create + Tugbot.Start + Wmi.Call
├── tugboat.gpr         -- GNAT project file
├── tugbot.sdf          -- Gazebo world: ground plane + tugbot model
├── session.pro         -- P4 launcher session (Ada proc + gz sim proc)
├── BUILD               -- Build script (gprbuild + ipcrm)
└── RUN                 -- Run script  (env P4PATH … drivers/p4)
```

## WMI — Woman-Machine Interface

`Wmi` (`wmi.ads`) is a rename of `Uio.Server`:

```ada
package Wmi renames Uio.Server;
```

It provides three roles:

| Call | Description |
|---|---|
| `Wmi.Create` | Start HTTP web server + P4 parser task in one call |
| `Wmi.Call(Query, Params)` | Programmatic dispatch (bypasses HTTP, direct `Dispatch_To_Action`) |
| `Wmi.P("key", value)` | Build a CGI parameter string |
| `Wmi."+"(l, r)` | Concatenate parameters: `Wmi.P("a","1") + Wmi.P("b","2")` |
| `Wmi.Url(Query, Params)` | Make an HTTP GET to localhost |

### Wmi.Create vs UIO.Server.Create

`Wmi.Create` (= `Uio.Server.Create` with `P4_On => True`) internally spawns
a `Parser_Task` that runs `Ses.Pp.Parser`. There is **no need** to call
`Ses.Pp.Parser` separately — doing so would start a second parser task.

### Wmi.Call pattern (from demo_drone.adb / eng-test.adb)

```ada
--  Trigger an action programmatically (bypasses HTTP):
Wmi.Call (Query  => "tugbot.navigate",
          Params => Wmi.P ("set", "MOVING_FORWARD"));

--  Multiple params (like joystick Drive action):
Wmi.Call (Query  => "tugbot.drive",
          Params => Wmi.P ("direction", "MOVING_FORWARD") +
                    Wmi.P ("speed", 0.8));
```

## Web Dispatch Action Patterns

All web action types derive from `Pace.Server.Dispatch.Action` following
`uio-dbw.ads`. The bodies follow `uio-dbw.adb` conventions:

| Pattern | Delivery_vehicle equivalent | Tugbot action |
|---|---|---|
| `Drive_State'Value(+Obj.Set)` | `Gear?set=FORWARD` | `NAVIGATE?set=MOVING_FORWARD` |
| `Float'Value(+Obj.Set)` | `Accelerate?set=1.0` | `SET_SPEED?set=0.8` |
| `Pace.Server.Keys.Value("k",d)` | `Joystick?x=0.5&y=0.8` | `DRIVE?direction=…&speed=…` |
| `Put_Content("")` + `Item(…)` | `Get_All_Gauges` | `GET_STATUS` |
| `Push_Content` + loop | `Compass` | `HEADING_MONITOR` |

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

> **Note:** `warnign_light` / `warnign_light_joint` preserves the typo in the
> original tugbot model. `TableControlPlugin` matches by name string exactly.

## Build

```bash
cd examples/tugboat
bash BUILD
```

## Run

```bash
bash RUN
```

Requires Gazebo Sim, `libTablePlugin.so` in `../../plugins/gazebo/`, and the
P4 launcher in `../../drivers/`.

## Remote Manipulation API

After launch the web server listens on `PACE_PORT_WEB` (default: 5600 + `PACE_NODE`).

### Navigate (direction only)

```bash
# Like delivery_vehicle: GEAR?set=FORWARD
curl "http://localhost:5601/TUGBOT.NAVIGATE?set=MOVING_FORWARD"
curl "http://localhost:5601/TUGBOT.NAVIGATE?set=TURNING_LEFT"
curl "http://localhost:5601/TUGBOT.NAVIGATE?set=STOPPED"
```

Values: `STOPPED` | `MOVING_FORWARD` | `MOVING_BACKWARD` | `TURNING_LEFT` | `TURNING_RIGHT`

### Set_Speed

```bash
# Like delivery_vehicle: ACCELERATE?set=1.0
curl "http://localhost:5601/TUGBOT.SET_SPEED?set=0.8"
```

### Drive (joystick-style, direction + speed in one call)

```bash
# Like delivery_vehicle: JOYSTICK?x=0.5&y=0.8
curl "http://localhost:5601/TUGBOT.DRIVE?direction=MOVING_FORWARD&speed=0.8"
curl "http://localhost:5601/TUGBOT.DRIVE?direction=TURNING_RIGHT&speed=0.5"
curl "http://localhost:5601/TUGBOT.DRIVE?direction=STOPPED"
```

### Gripper

```bash
curl "http://localhost:5601/TUGBOT.GRIPPER?set=CLOSED"
curl "http://localhost:5601/TUGBOT.GRIPPER?set=OPEN"
```

### Warning Light

```bash
curl "http://localhost:5601/TUGBOT.LIGHT?set=TRUE"
curl "http://localhost:5601/TUGBOT.LIGHT?set=FALSE"
```

### Status Query

```bash
# Like delivery_vehicle: GET_ALL_GAUGES (returns XML)
curl "http://localhost:5601/TUGBOT.GET_STATUS"
# Returns: <status><drive>STOPPED</drive><gripper>OPEN</gripper>
#           <light>TRUE</light><x>0.0</x><y>0.0</y><heading>0.0</heading></status>
```

### Heading Monitor (server push)

```bash
# Like delivery_vehicle: COMPASS (streaming server-push)
curl "http://localhost:5601/TUGBOT.HEADING_MONITOR"
# Streams: <heading>0.0</heading><heading>0.012</heading>...
```

### Programmatic dispatch via Wmi.Call (from Ada code)

```ada
--  Following demo_drone.adb / eng-test.adb pattern:
Wmi.Call (Query  => "tugbot.navigate",
          Params => Wmi.P ("set", "MOVING_FORWARD"));
Wmi.Call (Query  => "tugbot.set_speed",
          Params => Wmi.P ("set", "0.8"));
Wmi.Call (Query  => "tugbot.drive",
          Params => Wmi.P ("direction", "MOVING_FORWARD") +
                    Wmi.P ("speed", 0.8));
Wmi.Call (Query => "tugbot.get_status");
```
