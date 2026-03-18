# Distributed Handshake Example

This example demonstrates a complex distributed handshaking scenario using the **Patterned Agentic Comms Environment (PACE)** library. It showcases collaborative interaction between three independent Ada nodes.

## Handshake Scenario

The handshake follows a circular collaborative flow:

1.  **Node 1 (Initiator)**: Sends a `Propose` message to Node 2.
2.  **Node 2 (Responder)**: Receives `Propose`, logs it, and sends a `Validate` message to Node 3.
3.  **Node 3 (Verifier)**: Receives `Validate`, logs it, and sends a `Confirm` message back to Node 1.
4.  **Node 1 (Initiator)**: Receives `Confirm` and logs the completion of the handshake.

## PACE Patterns Demonstrated

-   **Command Pattern**: All interactions use types derived from `Pace.Msg` with overridden `Input` primitives.
-   **Socket Dispatch**: Messages are routed transparently across nodes using `Pace.Socket.Send`.
-   **Node Routing**: The `nodes.pro` file defines the logical topology, mapping message types to specific node IDs.
-   **Session Management**: The `session.pro` file and the `p4` driver manage the concurrent launch and lifecycle of the three nodes.
-   **Graceful Shutdown**: All nodes utilize `Ses.Pp.Parser` to listen for the `-999` shutdown signal.
-   **Simulation Readiness**: Uses `Pace.Log.Wait` instead of Ada's `delay` to ensure compatibility with discrete-event simulation mode.

## How this Example was Created

This example was authored by an AI assistant (Gemini CLI) through the following process:

1.  **Library Analysis**: Studied the `PetriNetAdaComponentEnvironment.pdf` documentation to understand core mandates (e.g., the "No delay" rule, message-centric design).
2.  **Pattern Extraction**: Analyzed existing examples like `gyrator_example` to identify the required project structure (`.gpr`), configuration files (`nodes.pro`, `session.pro`), and boilerplate for main procedures.
3.  **Surgical Implementation**: 
    -   Defined a new Ada package (`Handshake`) to encapsulate the message types and their distributed logic.
    -   Implemented three distinct main procedures to act as the distributed agents.
    -   Configured the routing table to create a multi-hop handshake loop.
4.  **Verification**: Validated the build process using `gprbuild` and ensured the `P4` session configuration correctly identifies the executable paths.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
```bash
sh RUN
```
Once running, type `-999` into the console to terminate all nodes.
