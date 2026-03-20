# Multicast Example

This example demonstrates the use of **Unreliable Multicast** for transient data distribution in the PACE library.

## Architecture

- **Mcast_Test**: A driver that sends and receives data via the multicast socket interface.
- **Pace.Socket.Multicast**: Uses the underlying UDP multicast support to reach multiple nodes simultaneously.

## PACE Patterns Demonstrated

- **Multicast Pattern**: Ideal for high-frequency, transient data like telemetry or video streams where occasional packet loss is acceptable.
- **Socket Abstraction**: Shows how the `Pace.Socket` layer provides a common interface for both point-to-point and multicast communication.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
```bash
sh RUN
```
