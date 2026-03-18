# Robotic Battery Assembly Emulation

This example emulates a complex, concurrent robotic assembly line for battery modules using the PACE library.

## System Components (Agents)

1.  **PLC (Node 1)**: The central conductor. Orchestrates all concurrent motions and safety handshakes.
2.  **Conveyor (Node 2)**: Handles material transport (tray loading and indexing).
3.  **Robot A - SCARA (Node 3)**: High-speed cell placement robot. Uses vision data for precision adjustments.
4.  **Robot B - 6-Axis (Node 4)**: Heavy-lifting robot for busbar handling.
5.  **Robot C - SCARA (Node 5)**: High-speed ultrasonic welder.
6.  **Vision System (Node 6)**: Inspects trays and provides coordinate offsets.

## Process Flow & Handshaking

The cyclical process demonstrates several key distributed coordination patterns:

-   **Parallel Initialization**: While the Conveyor is loading a new tray, Robot A simultaneously moves to its "pick" position.
-   **Data-Driven Feedback**: The Vision System inspects the tray and sends coordinate offsets to the PLC, which then relays them to Robot A for precise placement.
-   **Collision Avoidance (The "Conducting" Pattern)**: Robot B (Busbar) and Robot C (Welder) share overlapping work envelopes. The PLC ensures Robot B has signaled "Cleared" before commanding Robot C to begin welding.
-   **Cycle Synchronization**: All agents signal completion to the PLC before the conveyor indexes the tray to restart the cycle.

## PACE Patterns Demonstrated

-   **Multi-Agent Coordination**: 6 nodes interacting in a complex state machine.
-   **Synchronous & Asynchronous Messaging**: Mixture of `Ack => True` (blocking) and `Ack => False` (non-blocking) sends.
-   **State Machine in Tasks**: The PLC uses an Ada task to manage the sequential and parallel stages of the assembly cycle.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
```bash
sh RUN
```
To shutdown the system, type `-999` into the console.
