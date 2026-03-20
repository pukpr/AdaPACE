# POST (Power-On Self Test) Example

This example demonstrates sequential task orchestration and self-test logic using the PACE Command pattern.

## Components

- **Post.A, Post.B, Post.C**: Independent agents that perform sequential operations (`First`, `Second`, `Third`, `Fourth`).
- **Post-Small**: A minimal driver for the self-test sequence.

## PACE Patterns Demonstrated

- **Command Chaining**: Shows how one message can trigger a sequence of follow-on operations across different agents.
- **Task Synchronization**: Uses synchronous and asynchronous messaging to ensure steps are performed in the correct order.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
```bash
sh RUN
```
