# examples

Self-contained example applications that demonstrate AdaPACE patterns.

Each sub-directory is an independent Ada project with its own GNAT project file (`.gpr`).  Examples range from minimal "hello" programs that exercise a single component to more realistic distributed-application skeletons.

## Structure

```
examples/
  hello_comms/      -- minimal IPC command-pattern example
  simulated_rt/     -- real-time loop with simulated hardware
  distributed_app/  -- multi-node application skeleton
```

## Building an example

```
cd examples/hello_comms
gprbuild -P hello_comms.gpr
./bin/hello_comms
```

## Conventions

* Every example must build cleanly against the library in `src/`.
* Keep examples small and focused; complex scenarios belong in `test/` or `docs/`.
