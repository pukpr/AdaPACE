# plugins

Optional, dynamically-loadable or compile-time-selectable extensions to AdaPACE.

Plugins extend the core library without modifying it.  They follow the same package conventions as `src/` but are versioned and distributed independently.  A plugin sub-directory contains:

* `<plugin_name>.ads` / `<plugin_name>.adb` — the Ada implementation.
* `<plugin_name>.gpr` — a GNAT project file with a dependency on the core library.
* `README.md` — description, dependencies, and configuration options.

## Conventions

* Plugin packages are rooted at `PACE.Plugins.<Name>` (e.g. `PACE.Plugins.Logging`).
* Plugins must declare their minimum required AdaPACE version via a `PACE_Version` constant.
* No circular dependencies between plugins are permitted.
