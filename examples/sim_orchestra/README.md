# Discrete Event Simulation: Producer-Processor-Consumer

This example demonstrates a pure discrete-event simulation (DES) using the PACE library.

## Simulation Characteristics

-   **Standalone (Node 0)**: Runs as a single process (`PACE_NODE=0`) without the need for the P4 driver.
-   **Simulation Mode**: Time is governed by the PACE simulation engine (`PACE_SIM=1`), meaning the execution "jumps" between events rather than waiting in real-time.
-   **Agent Architecture**: Features three independent Ada packages (`Producer_Pkg`, `Processor_Pkg`, `Consumer_Pkg`), each containing an active task.
-   **Trace Instrumentation**: All `Input` primitives are instrumented with `Pace.Log.Trace(Obj)`, enabling timeline and performance analysis as described in the PACE documentation.

## Process Flow

1.  **Producer**: Generates `Raw_Data` every 10 simulated seconds.
2.  **Processor**: Waits for data using the `Notify` pattern, processes it for 2 simulated seconds, and sends `Refined_Data` to the Consumer.
3.  **Consumer**: Logs the arrival of refined data.
4.  **Main**: Orchestrates the startup and shuts down the simulation after 100 simulated seconds.

## PACE Patterns Demonstrated

-   **Simulation Awareness**: Uses `Pace.Log.Wait` instead of `delay` to ensure compatibility with DES mode.
-   **Agent Registration**: Each task calls `Pace.Log.Agent_Id` for identification in logs and traces.
-   **Publish/Subscribe (Notify)**: Used within the Processor agent to synchronize its internal task with incoming messages.
-   **Trace Pattern**: Manual instrumentation of message primitives for simulation data collection.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
```bash
sh RUN
```
The simulation will execute 100 seconds of logic in near-instantaneous wall-clock time and then exit.
