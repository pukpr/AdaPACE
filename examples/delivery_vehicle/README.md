# Delivery Vehicle Demo — `demo_drone`

## Overview

`demo_drone` simulates an autonomous delivery vehicle equipped with a drone launcher.
The vehicle navigates to a delivery position, then uses a fully automated loading station
to prepare and launch a drone carrying a box payload (i.e. the delivery)
to each target in a delivery mission. The process repeats for every item in the mission
at a cadence governed by `Time_Between_Items` (9 seconds).

The simulation is built on the **PACE** (Patterned Agent-based Concurrent Execution)
Ada framework, in which independent hardware subsystems are modelled as concurrent Ada
tasks that communicate through typed message passing (rendezvous entries, pub/sub
notifications, and non-blocking surrogates).

---

## Main Procedure (`demo_drone.adb`)

```ada
Wmi.Create (10, 500_000);          -- start 10-thread WMI server, 500 ms timeout
Pace.Log.Agent_Id;                  -- log this process identity
Wmi.Call ("eng.test.trigger_delivery_mission", id => "1");
```

The main procedure is deliberately minimal. It instantiates the PACE World-Model
Interface (WMI), then issues a single WMI call that triggers `Eng.Test` to inject
a scripted mission sequence. All subsequent work is performed by the concurrently
running agent tasks that were elaborated at program startup.

---

## Agent Roles

| Agent | Package | Role |
|---|---|---|
| **Eng.Test** | `eng-test` | Test harness: drives state machine transitions and injects the delivery mission |
| **Mxr.Delivery_Order** | `mxr-delivery_order` | Queues and dispatches an incoming delivery order |
| **Ifc.Delivery_Mission** | `ifc-delivery_mission` | Translates the external delivery order into internal mission data; triggers flight solution calculation |
| **Abk.Technical_Delivery_Direction** | `abk-technical_delivery_direction` | Computes per-item elevation, azimuth, launch velocity and delivery time for every destination |
| **Ahd.Delivery_Mission** | `ahd-delivery_mission` | Persistent mission record; publishes coordination notifications (`Start_Delivery_Mission`, `Flight_Solution`, `Configure_Equipment`, `Execute_Delivery_Order`) |
| **Aho.Delivery_Handling_Coordinator** | `aho-delivery_handling_coordinator` | Top-level orchestrator: fans out startup to shuttles, waits for flight solution, then signals the drone to begin |
| **Aho.Drone** | `aho-drone` | Controls drone elevation/traverse drives, waits for load completion and `Clear_To_Delivery`, then executes launch |
| **Aho.Inventory_Loader** | `aho-inventory_loader` | Raises/lowers the loader arm; coordinates transfer from both shuttles; calls stacker to chamber items; signals `Clear_To_Delivery` |
| **Aho.Box_Shuttle** | `aho-box_shuttle` | Rotates and extends to the box compartment, grips a box, spins to the tag station (removes ID tag), then delivers to the loader |
| **Aho.Bottle_Shuttle** | `aho-bottle_shuttle` | Rotates and extends to the bottle compartment, grips a bottle, spins to the loader |
| **Aho.Timer_Setter** | `aho-timer_setter` | Sets and counts down the delivery timer on the box; notifies completion (`Timer_Complete`) |
| **Aho.Stacker** | `aho-stacker` | Hydraulic actuator: `Place_Box` pushes the box into the launch chamber; `Place_Bottle` pushes the bottle in |
| **Aho.Door** | `aho-door` | Opens and closes the launch chamber door; emits `Rotate_Done` notification when the door rotation is complete |
| **Uio.State.Deliver** | `uio-state-deliver` | State machine: `Initial → Acknowledged → Emplaced → Enabled → Delivering → Items_Complete` |
| **Uio.State.Survive** | `uio-state-survive` | Parallel survival/operational-readiness state machine |
| **Uio.Delivery_Order_Status** | `uio-delivery_order_status` | Tracks and broadcasts per-item status (`Ready → Timered → Rammed → Delivered`) |
| **Acu.Vehicle** | `acu` | Updates 6-DOF vehicle dynamics every 1 s; provides heading and position |
| **Nav.Route_Following** | `nav-route_following` | Drives the vehicle along a waypoint route; monitors progress every 0.5 s |

---


## Operational Flow

### Phase 1 — Mission Injection (t = 0 – 3.5 s)

```
t=0.0  ENG.TEST  ──►  MXR.DELIVERY_ORDER.CALL_FOR_DELIVERY
t=1.0  MXR.DELIVERY_ORDER queues the order internally (QUEUE_UPDATE)
t=3.0  UIO.ROUTE sets waypoints → NAV.ROUTE_FOLLOWING.START
       NAV.ROUTE_FOLLOWING monitors progress every 0.5 s
       ACU.VEHICLE.TRANSMISSION updates 6-DOF every 1 s
```

`Eng.Test` submits mission id "1" to `Mxr.Delivery_Order`, which queues it.
The vehicle simultaneously begins navigating its pre-planned route via
`Uio.Route` → `Nav.Route_Following`.

---

### Phase 2 — Mission Acceptance and Flight Solution (t = 3.0 – 6.55 s)

```
t=3.0   MXR.DELIVERY_ORDER ──►  IFC.DELIVERY_MISSION.ACCEPT_DELIVERY_ORDER
         (takes 3 s to process; completes at t=6.0)
t=3.5   IFC.DELIVERY_MISSION ──►  AHD.DELIVERY_MISSION.START_DELIVERY_MISSION
         AHO.DELIVERY_HANDLING_COORDINATOR unblocks (was waiting on START_DELIVERY_MISSION)
t=3.5   COORDINATOR  ──►  AHO.BOX_SHUTTLE.BEGIN_DELIVERY_ORDER     (non-blocking)
t=3.5   COORDINATOR  ──►  AHO.BOTTLE_SHUTTLE.BEGIN_DELIVERY_ORDER  (non-blocking)
         Both shuttles immediately begin spinning to their compartments.
t=3.5–3.7  IFC.DELIVERY_MISSION → ABK.CALCULATE_FLIGHT_SOLUTION
              (200 ms: computes elevation, azimuth, velocity, delivery time per item)
t=3.7   IFC.DELIVERY_MISSION ──►  AHD.DELIVERY_MISSION.FLIGHT_SOLUTION
         COORDINATOR unblocks from FLIGHT_SOLUTION notification.
```

In parallel with route navigation, `Ifc.Delivery_Mission` reads mission data from the
knowledgebase (`get_fm_static` / `get_item` Prolog queries), then calls
`Abk.Technical_Delivery_Direction.Calculate_Flight_Solution` (200 ms) to determine
the launch parameters for each item. Results are published via the `Flight_Solution`
notification so the coordinator can proceed.

The coordinator also fires off the two shuttles non-blocking as soon as the mission
starts, so compartment indexing overlaps with the flight computation.

---

### Phase 3 — Emplacement and Equipment Configuration (t = 6.0 – 6.55 s)

```
t=6.0   ENG.TEST → ACU.VEHICLE.EMPLACE
t=6.0   ENG.TEST → IFC.DELIVERY_MISSION.CHECK_AZIMUTH  (×2: confirms drone is on-bearing)
t=6.0   ENG.TEST → AHD.DELIVERY_MISSION.CONFIGURE_EQUIPMENT
         COORDINATOR unblocks (was waiting on CONFIGURE_EQUIPMENT notification).
t=3.5–6.55  IFC.DELIVERY_MISSION → ABK.PERFORM_TECHNICAL_DELIVERY_DIRECTION
              (full solution for all items; 3.05 s elapsed)
t=6.55  IFC.DELIVERY_MISSION ──►  AHD.DELIVERY_MISSION.MISSION_IS_READY
         COORDINATOR unblocks from MISSION_IS_READY notification.
```

`Eng.Test` drives the state machine to `Emplaced` then `Enabled`. Azimuth checks
verify the vehicle heading is within tolerance for the destination. The full technical
delivery direction computation finalises at t=6.55 s.

---

### Phase 4 — Drone Initialization and Pre-Aim (t = 6.55 – 6.60 s)

```
t=6.55  COORDINATOR  ──►  AHO.DRONE.INITIALIZE        (sends all per-item flight data)
t=6.55  DRONE        ──►  AHO.INVENTORY_LOADER.INITIALIZE   (non-blocking)
t=6.55  COORDINATOR  ──►  AHO.DRONE.AIM_DRONE          (non-blocking)
t=6.55  COORDINATOR  ──►  AHO.DRONE.START_DELIVERY_MISSION  (non-blocking, completes t=6.60)
t=6.55  COORDINATOR  waits on AHD.DELIVERY_MISSION.EXECUTE_DELIVERY_ORDER
           (ENG.TEST posts this at t=6.0; coordinator unblocks at t=6.55)
t=6.60  TRAVERSE_DRIVE  ──►  DRONE.TRAVERSE_COMPLETE   (drone on azimuth)
t=6.60  ELEVATION_DRIVE ──►  DRONE.ELEVATION_COMPLETE  (drone on elevation)
```

The drone stores the complete array of per-item flight parameters and 
commands the loader to prepare. The loader opens its retainer door at t=6.55 → 6.87 s (non-blocking surrogate).

---

### Phase 5 — Compartment Indexing (t = 3.7 – 8.2 s, overlapped)

```
t=3.7   COORDINATOR  ──►  BOX_COMPARTMENT.INDEX_TO_SHUTTLE_GATE    (non-blocking)
t=3.7   COORDINATOR  ──►  BOTTLE_COMPARTMENT.INDEX_TO_SHUTTLE_GATE (non-blocking)
t=4.3   BOX_SHUTTLE spins to compartment (spin complete)
t=8.2   BOX_COMPARTMENT.INDEX_COMPLETE  → BOX_SHUTTLE unblocks
t=8.2   BOTTLE_COMPARTMENT.INDEX_COMPLETE → BOTTLE_SHUTTLE unblocks
```

Both compartment rotary magazines index to align their next item with the shuttle gate.
This takes ~4.5 s from when the coordinator initiates it (t=3.7) and completes at t=8.2 s,
at which point both shuttles are released to begin retrieval.

---

### Phase 6 — Per-Item Load and Launch Loop

This loop executes once per item (twice visible in `trace.out` for items 1 and 2).
Each iteration spans approximately 7 seconds of simulation time and the following
sub-phases run with significant parallelism between the box shuttle, bottle shuttle,
and inventory loader.

#### 6a — Box Retrieval from Compartment (starts at t=8.2 / t=15.3 for item 2)

```
BOX_SHUTTLE.EXTEND_SHUTTLE_TO_MAG     (~0.7 s) — arm extends into compartment
BOX_SHUTTLE_GRIPPERS.CLOSE_BOX_SHUTTLE_GRIPPERS (~0.3 s) — grippers close on box
BOX_SHUTTLE.TRANSFER_BOX_TO_SHUTTLE  (~0.3 s) — box transferred to shuttle arm
BOX_SHUTTLE.RETRACT_SHUTTLE           (~0.7 s) — arm retracts with box
BOX_SHUTTLE.SPIN_TO_TAG_STATION       (~0.8 s) — rotates to tag removal station
BOX_SHUTTLE.REMOVE_TAG_ID             (~0.5 s) — identification tag stripped from box
```

#### 6b — Bottle Retrieval from Compartment (starts t=8.2 / t=16.0, in parallel)

```
BOTTLE_SHUTTLE.SPIN_TO_MAG            (~0.8 s) — rotates to bottle compartment
BOTTLE_SHUTTLE.EXTEND_SHUTTLE         (~0.7 s) — arm extends into compartment
BOTTLE_SHUTTLE_GRIPPERS.CLOSE         (~0.3 s) — grippers close on bottle
BOTTLE_SHUTTLE.TRANSFER_BOTTLE_TO_SHUTTLE (~0.3 s)
BOTTLE_SHUTTLE.RETRACT_SHUTTLE        (~0.7 s)
BOTTLE_SHUTTLE.SPIN_TO_LOADER         (~0.8 s) — rotates to align with loader
```

#### 6c — Timer Setting (overlaps retrieval, starts at t=9.93)

```
TIMER_SETTER.SET_TIMER  (~2.5 s) — counts down delivery timer on box
TIMER_SETTER → AHD.DELIVERY_ORDER_STATUS.MODIFY_BOX (status: Timered)
TIMER_SETTER.TIMER_COMPLETE notification — unblocks BOX_SHUTTLE to continue
```

The timer setter begins counting as soon as the box shuttle has retracted from the
compartment (box is in hand). Completion at t=12.43 (item 1) / t=19.52 (item 2)
signals the box shuttle to extend toward the loader.

#### 6d — Transfer to Loader (loader coordinates both shuttles)

```
t=11.50  LOADER  ──►  BOTTLE_SHUTTLE.TRANSFER_BOTTLE_TO_LOADER  (loader signals ready for bottle)
          BOTTLE_SHUTTLE extends into loader (~0.7 s)
t=12.05  LOADER  ──►  BOX_SHUTTLE.TRANSFER_BOX_TO_LOADER        (after bottle aligns)
          BOX_SHUTTLE spins to loader (~0.8 s), extends (~0.7 s)
t=12.05  LOADER  ──►  BOTTLE_SHUTTLE.AWAIT_BOTTLE_TRANSFER       (loader waits for bottle handoff)
t=12.22  BOTTLE_SHUTTLE.TRANSFER_BOTTLE_FROM_SHUTTLE             (bottle released)
t=12.22  LOADER  ──►  BOX_SHUTTLE.AWAIT_BOX_TRANSFER             (loader waits for box handoff)
t=13.15  BOX_SHUTTLE.OPEN_BOX_SHUTTLE_GRIPPERS + TRANSFER_BOX_FROM_SHUTTLE (box released)
t=13.15  LOADER  ──►  INVENTORY_LOADER.CLOSE_LOADER_RETAINER     (loader closes, sealing both items)
t=13.46  LOADER  ──►  BOTTLE_SHUTTLE.ACK_BOTTLE_TRANSFER
t=13.46  LOADER  ──►  BOX_SHUTTLE.ACK_BOX_TRANSFER
```

The loader acts as a two-handed rendezvous point: it signals each shuttle when to
hand off its payload, waits for the physical transfer, then closes its retainer to
capture both items. Acknowledgements release both shuttles to reset for the next item.

#### 6e — Compartment Advance (overlaps loader close)

```
t=13.46  LOADER  ──►  BOTTLE_SHUTTLE.BOTTLE_SHUTTLE_CLEAR
t=14.48  LOADER  ──►  BOX_SHUTTLE.BOX_SHUTTLE_CLEAR
t=14.48  LOADER  ──►  BOTTLE_SHUTTLE.INDEX_COMPARTMENT  (advance bottle compartment)
t=14.48  LOADER  ──►  BOX_SHUTTLE.INDEX_COMPARTMENT     (advance box compartment)
          Both compartments begin rotating to the next item position
          while chambering of the current item proceeds.
```

#### 6f — Stacking

```
t=14.48  LOADER -> STACKER.PLACE_BOX           (0.7 s) — stacker pushes box into chamber
t=15.18  LOADER → AHD.DELIVERY_ORDER_STATUS.MODIFY_BOX (status: Rammed)
t=15.18  LOADER -> STACKER.RETRACT_STACKER     (0.7 s)
t=15.88  LOADER -> SWING_TRAY_TO_BOTTLE        (0.6 s) — loader tray aligns for bottle
t=16.48  LOADER -> STACKER.PLACE_BOTTLE        (0.7 s) — stacker pushes bottle in
```

In parallel the door has been commanded closed:
```
t=18.63  DOOR.CLOSE_DOOR_DOOR -> DOOR.SWING_DOOR    (0.7 s)
t=19.33  DOOR.CLOSE_DOOR_DOOR -> DOOR.ROTATE_DOOR_TIMED (0.2 s) — door sealed
```

#### 6g — Drone Waits for Load Completion and `Clear_To_Delivery`

```
t=14.48  DRONE  ──►  LOADER.ACK_LOAD_DRONE_COMPLETE  (drone notifies loader load can start)
t=18.13  DRONE waits on TRAVERSE_COMPLETE  (drone re-aims to current item azimuth)
t=18.13  DRONE waits on ELEVATION_COMPLETE (drone on correct elevation)
t=20.55  LOADER  ->  CLEAR_TO_DELIVERY notification
t=18.13  DRONE  <waits on CLEAR_TO_DELIVERY>  ── unblocks at t=20.55
```

The drone re-slews to the current item's computed azimuth and elevation while the
loader is still chambering. It then blocks on `CLEAR_TO_DELIVERY`, which the loader
posts only after the retainer has been closed and both shuttle transfers acknowledged.

#### 6h — Launch

```
t=20.55  DRONE => AHO.DRONE.LAUNCH                 (100 ms: pyrotechnic ignition model)
t=20.66  DRONE -> AHO.DRONE.LIFT_OFF               (0.9 s: drone rises after launch)
t=20.55  DRONE => AHD.DELIVERY_ORDER_STATUS.MODIFY_BOX  (status: Delivered)
t=20.55  DRONE => SIM.INVENTORY.UPDATE_INVENTORY   (decrement simulated inventory)
```

The launch action commands `Veh.Delivery_Motion.Rock_Vehicle` (platform recoil) and
`Veh.Delivery_Motion.Rebound_Vehicle` (suspension rebound), then plays the acoustic
boom (`drone_boom`). After the drone lifts off, the loader immediately  begins stacking the next item.

---

### Phase 7 — Reset for Next Item (starts immediately after LAUNCH)

```
t=20.55  LOADER  ──►  BOTTLE_SHUTTLE.BOTTLE_SHUTTLE_CLEAR
t=21.56  LOADER  ──►  BOX_SHUTTLE.BOX_SHUTTLE_CLEAR
t=21.56  LOADER  ──►  BOTTLE_SHUTTLE.INDEX_COMPARTMENT  (next position)
t=21.56  LOADER  ──►  BOX_SHUTTLE.INDEX_COMPARTMENT     (next position)
          Box and bottle compartments index to the next item simultaneously.
```

The shuttles retract, grippers open, and both compartments advance to the next
position. The cycle from Phase 6a restarts for item 2 from approximately t=21.6 s,
overlapping with the stacker retract of the preceding item.

---

### Phase 8 — Mission Completion

After the last item is launched:

1. `Aho.Drone.Finalize_Delivery_Mission` is called.
2. Drone slews to stow position (azimuth = 0°, elevation = standby).
3. `Aho.Inventory_Loader.Stow_Equipment` lowers and secures the loader arm.
4. `Ahd.Delivery_Mission.Delivery_Mission_Complete` notification is published.
5. State machine transitions: `Delivering → Items_Complete → Initial`.
6. `Uio.State.Deliver` resets, ready for the next mission order.

---

## Task Synchronization Summary

The system uses three distinct PACE synchronization primitives:

| Pattern | Notation in trace | Semantics |
|---|---|---|
| **Blocking rendezvous** | `A => B.MSG` | Caller blocks until callee accepts the entry |
| **Non-blocking send** | `A >> B.MSG` | Caller continues immediately; callee queues message |
| **Pub/sub wait** | `A <> B.MSG` | Subscriber blocks until publisher posts notification |
| **Surrogate** | `A -> B.MSG` | Long-running action offloaded to a surrogate task |

Key synchronization points that enforce correctness:

- **`FLIGHT_SOLUTION`** — coordinator must not start drone aim until flight data is ready.
- **`MISSION_IS_READY`** — coordinator must not start mission execution until the full per-item solution set is available.
- **`COMPARTMENT.INDEX_COMPLETE`** — shuttle must not extend to retrieve until the rotary compartment has stopped.
- **`TIMER_COMPLETE`** — box shuttle must not deliver to loader until the timer has been set.
- **`AWAIT_BOTTLE_TRANSFER` / `AWAIT_BOX_TRANSFER`** — loader enforces a strict two-phase handshake with each shuttle before closing the retainer.
- **`CLEAR_TO_DELIVERY`** — drone cannot launch until the loader has sealed the chamber and cleared both shuttles.

---

## Knowledge Base Integration

Mission destinations and item parameters are stored in Prolog-syntax files under `../../kbase/`.
At startup the following queries are issued against the knowledgebase:

| Query | Purpose |
|---|---|
| `get_fm_static` | Retrieves mission header (target, mission type, control, phase, item count) |
| `get_item` | Retrieves per-item target coordinates, elevation, azimuth, box type, timer type/setting, on-target time |
| `box_bottle_velocity` | Maps (box type, charge zone) → launch velocity |
| `mission_alert` | Audio file for mission-received alert |

---

## Building and Running

```bash
# Build
gprbuild dv.gpr

# Run (30 second simulation, mission id 1)
env PACE_SIM=1 PACE_RUN_TIME=30.0 PACE=../.. obj/demo_drone

# Run with full knowledgebase debug output
env GKB_DEBUG=1 PACE_SIM=1 PACE_RUN_TIME=30.0 PACE=../.. obj/demo_drone

# Select a different mission
env PACE_SIM=1 PACE_RUN_TIME=60.0 PACE=../.. obj/demo_drone -id 2
```
