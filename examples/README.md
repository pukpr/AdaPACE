# examples

Self-contained example applications that demonstrate AdaPACE patterns.

Each sub-directory is an independent Ada project with its own GNAT project file (`.gpr`).  Examples range from minimal "hello" programs that exercise a single component to more realistic distributed-application skeletons.

## Structure

```
examples/
  ring/             -- minimal IPC command-pattern example
  gyrator_example/  -- real-time loop in simulated
  toms/             -- multi-node application skeleton
```

## Building an example

```
cd examples/gyrator_example
gprbuild -aP../.. gyrator_ex.gpr
./client_main
```

## Running a distributed example

```
cd ../drivers
gprbuild -aP.. p4.gpr
cd ../examples/gyrator_example
env P4PATH="../../launch.pro" ../../drivers/p4
```

This uses ssh to launch the application


## Conventions

* Every example must build cleanly against the library in `src/`.
* Keep examples small and focused; complex scenarios belong in `test/`.


