# src

Source code for the AdaPACE library.

This directory contains the core Ada package specifications (`.ads`) and package bodies (`.adb`) that implement the PACE component library.  Components emphasise hardware independence, concurrency via Ada tasking, and IPC-based communication using the command pattern.

## Conventions

* One package per file; file names mirror the Ada package name in lower-case with underscores (e.g. `pace-comms.ads`).
* Public API lives in `.ads` files; implementation in the corresponding `.adb` file.
* All packages are children of the top-level `PACE` package.
