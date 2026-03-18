# Distributed Maximum Finder Example

This example demonstrates a worker-server architecture using the PACE library, where multiple workers generate data and a central server aggregates the results.

## Architecture

-   **Worker Nodes (Nodes 2 & 3)**: 
    -   Each worker runs a task that draws numbers from a normal (Gaussian) distribution.
    -   The distribution has a mean of 0.0 and a standard deviation of 10.0.
    -   Numbers are sent to the server at a rate of approximately 2 per second to avoid overworking the IPC system.
    -   The `Found_Value` message includes both the value and the worker's `Node_ID`.
-   **Server Node (Node 1)**:
    -   Contains a `Max_Store` protected type that thread-safely maintains the largest value seen so far.
    -   Whenever a worker sends a value that exceeds the current maximum, the server prints an alert indicating the new value and its node of origin.

## PACE Patterns Demonstrated

-   **Command Pattern**: The `Found_Value` message inherits from `Pace.Msg` and is dispatched via `Pace.Socket.Send`.
-   **Protected Types**: Used within the server agent to synchronize access to shared state (the maximum value).
-   **Generic Math Integration**: Demonstrates how to integrate external or internal generic math libraries (`Sal.Gen_Math.Gen_Gauss`) within a PACE agent.
-   **Logical Node Mapping**: `nodes.pro` defines node 1 as the destination for all `Found_Value` messages.
-   **Session Launching**: `session.pro` defines a 3-node topology for the `P4` launcher.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
```bash
sh RUN
```
To shutdown the entire distributed system, type `-999` into the console.
