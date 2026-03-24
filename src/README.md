# src

Source code for the AdaPACE library.

This directory contains the core Ada package specifications (`.ads`) and package bodies (`.adb`) that implement the PACE component library.  Components emphasise hardware independence, concurrency via Ada tasking, and IPC-based communication using the command pattern.

## Conventions

* One package per file; file names mirror the Ada package name in lower-case with underscores (e.g. `pace-comms.ads`).
* Public API lives in `.ads` files; implementation in the corresponding `.adb` file.
* All packages are children of the top-level `PACE` package.

# Top-Layer Package Naming Conventions

| Package | Description                                                                                          |
|---------|------------------------------------------------------------------------------------------------------|
| **hal** | Hardware Abstraction Layer (Interface to hardware or simulated environment)                          |
| **gis** | Geographic Information Systems                                                                       |
| **gkb** | Generic Knowledge Base (interface to Prolog)                                                         |
| **gnu** | GNU Utilities                                                                                        |
| **mob** | Mobility (skeletal vehicles)                                                                         |
| **pbm** | Plant-Based Models (model plant as in actuator/controller systems)                                   |
| **ses** | Sim/Emu/Stim (launching distributed simulation/emulation/stimulation apps)                           |
| **tdb** | Terrain Database                                                                                     |
| **ual** | User Abstraction Layer                                                                               |
| **uio** | User Input/Output                                                                                    |
| **wmi** | Web Machine Interface (e.g. Man-Machine Interface via a web interface)                               |

These package names are intended as concise, high-level domains for the major functional areas within the system. Each one encapsulates a particular concern or interface, helping to promote modularity and maintainability.

