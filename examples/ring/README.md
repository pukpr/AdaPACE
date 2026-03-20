# Ring Token Passing Example

This example demonstrates a classic **Circular Token Ring** topology using distributed PACE agents.

## Architecture

- **Ring**: A package defining the `Token` message which contains a value and a color.
- **Pace-Ring_Driver**: Orchestrates the movement of the token through a logical ring of nodes.

## PACE Patterns Demonstrated

- **Circular Routing**: Each node in the ring receives a token, processes it (incrementing a value or changing state), and forwards it to the next node defined in `nodes.pro`.
- **Node Topology**: Uses the `nodes.pro` file to define a circular "connection" graph.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
```bash
sh RUN
```
