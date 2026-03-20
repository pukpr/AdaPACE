# Gyrator Example

This is a fundamental example demonstrating **Remote Inter-Process Communication (IPC)** using the PACE Command pattern.

## Architecture

- **Gyrator**: A singleton agent that simulates a mechanical device with two states: `Halted` and `Moving`.
- **Gyrator_Main**: The server process that hosts the Gyrator object.
- **Client_Main**: A client process that sends `Move`, `Halt`, and `Get_Status` commands to the server.

## PACE Patterns Demonstrated

- **Command Pattern**: Commands are defined as types derived from `Pace.Msg` with overridden `Input` (for commands) or `Output` (for status requests) primitives.
- **Proxy (Socket) Pattern**: Messages are transparently routed between the client and server processes via sockets based on the `nodes.pro` configuration.
- **Remote Dispatching**: Shows how `Pace.Socket.Send` and `Pace.Socket.Send_Out` facilitate distributed interaction.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
```bash
sh RUN
```
This uses the `P4` driver to launch both the client and server processes.
