# AdaPACE
Ada library for concurrent, distrubuted, and real-time &amp;simulated RT apps, emphasizing HW independence and open systems.  It was designed as a common simulation framework to avoid proprietary infrastructures.  PACE uses Ada's strengths for concurrency &amp; runtime features, resulting in a compact, reusable component library (PACE).  Comms is built on IPC using the command pattern. 

It also features a Prolog knowledegabase and interpter used for creating and executing rules for managing distributed apps. See the ecxamples folder for usage with robotics applications, specifically deploying with 3D visualization software.

# PACE Capabilities Overview

PACE empowers development of distributed, concurrent, and real-time systems in Ada using powerful agent-based and messaging patterns. The following highlights its capabilities as showcased in real-world example applications within the project.

---

## Core Features

- **Concurrent Multi-Agent Systems:** Model complex systems as independent agents (Ada tasks) communicating via typed messages—supporting both synchronous and asynchronous workflows.
- **Distributed Application Skeletons:** Launch and coordinate multi-node systems using session scripts (`session.pro`) and the P4 launcher utility.
- **Real-Time Control:** Suitable for embedded and simulation use-cases requiring precise timing and responsiveness.

---

## Demonstrated Design Patterns

- **Command Pattern:** Encapsulate and dispatch control actions as command messages to agents (e.g., in vehicle and robotic control examples).
- **Singleton Objects:** Represent major subsystems as single-instance Ada packages (used in control system architectures).
- **Active Objects:** Internal Ada tasks model physical concurrency, such as motion controllers, sensors, and actuators.
- **Publish/Subscribe:** Broadcast state changes and data to multiple agents via notifications, supporting loose coupling and scalability.
- **Unreliable Multicast:** Efficiently distribute high-frequency, transient data (such as telemetry/streaming) using UDP multicast sockets.
- **Synchronous/Asynchronous Messaging:** Both one-way commands and request/response (inout) primitives are available for agent coordination.
- **State Machines in Tasks:** Implement complex sequential and parallel logic within coordinated agent tasks.
- **Socket Abstraction:** Uniform, high-level networking interface for point-to-point, publish/subscribe, and multicast communication.

---

## Selected Example Systems

### 1. **Robotic Battery Assembly**
- Emulates a multi-agent assembly line with parallel robot controllers, vision systems, safety handshakes, and distributed coordination.
- Highlights: Multi-agent state synchronization, collision avoidance, and two-way messaging for inspection/feedback.

### 2. **Warehouse Tugbot Simulation**
- Simulates a logistics robot in Gazebo with remote control through a Web-Machine Interface (WMI).
- Provides: REST-like command API, Ada-side HTTP server, real-time kinematic and sensor tasks.

### 3. **Humanoid Walking Robot**
- Demonstrates real-time gait generation with partitioned multi-task controllers and direct integration to physics simulation.

### 4. **Autonomous Delivery Vehicle**
- Orchestrates delivery by ground vehicle and drone launcher, with modular agent roles for inventory, navigation, and job scheduling.

### 5. **SUV Control Simulation**
- Showcases vehicle control via a Singleton agent, command processing, and modular assembly of subsystem models.

### 6. **Publish/Subscribe Messaging**
- Illustrates centralized and distributed broadcasting of system state and updates.

### 7. **Multicast Telemetry**
- Shows non-blocking, unreliable communication for transient data among distributed agents.

### 8. **Embedded Traffic Light Controller**
- Real-time control at a highway intersection, driven by timers, state variables, and remote interaction via P4.

---

## Building and Running Examples

Each example is a GNAT Ada project, buildable with `gprbuild` and often runnable via simple shell scripts. Distributed examples use a session/proc launcher to start agents across one or more processes or machines.

For more details, explore the [examples directory on GitHub](https://github.com/pukpr/AdaPACE/tree/main/examples/) or consult each example's README file.

---

*Note: This summary is based on a sampling of README files within the first 10 example folders. Other examples and usage patterns may be available—visit the [AdaPACE examples folder](https://github.com/pukpr/AdaPACE/tree/main/examples/) for the full suite.*

