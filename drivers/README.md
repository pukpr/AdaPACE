# drivers

Hardware-specific Ada drivers that plug into the AdaPACE abstraction layer.

Each driver package implements the abstract interfaces defined in `src/` so that higher-level components remain hardware-independent.  A driver sub-directory typically contains:

* `<device>_driver.ads` / `<device>_driver.adb` — the Ada implementation.
* `<device>.gpr` — a GNAT project file that can be included by application projects.
* `README.md` — wiring notes, supported hardware revisions, and known limitations.

## Conventions

* Drivers must **not** import any package outside of `src/` and the Ada standard library.
* Simulate hardware in `test/stubs/` rather than in the driver itself.
* Name packages `PACE.Drivers.<Device>` (e.g. `PACE.Drivers.UART`).
