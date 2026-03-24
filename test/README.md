# PACE Test Suites

This directory contains various test suites for the AdaPACE library, ranging from low-level pattern validation to distributed IPC tests.

## Available Suites

### 1. Pattern Tests (`test/pattern_tests`)
Validates fundamental PACE design patterns (Dispatch, WMI, Data Structures, Shared Memory).
- **Run**: `gprbuild -P test/pattern_tests/test.gpr && ./test/pattern_tests/obj/test_runner`

### 2. UUT Integration Tests (`test/uut`)
Functional tests for library components like the Job Scheduler and XML engine.
- **Run**: `cd test/uut && gprbuild -P common_suite.gpr && env PACE_SIM=1 PACE_NODE=0 PACE=.. ./test_harness`

### 3. IPC & Synchronization Tests (`test/ipc_tests`)
Tests multi-process communication and synchronization using the P4 launcher.
- **Run**: `cd test/ipc_tests && source BUILD && source RUN`

## Discrete Event Simulation (DES)

Most PACE tests support a simulation mode that allows them to run significantly faster than real-time by using a virtual clock.

- **`PACE_SIM=1`**: Enables DES mode. Delays (`Pace.Log.Wait`) occur instantly in simulation time.
- **`PACE_SIM=0`**: (Default) Real-time mode. Delays wait for actual wall-clock time.

## Conventions

* Test packages are named `<Tested_Package>_Test` or `Uut.<Package_Name>`.
* Most tests use the **AUnit** framework for result reporting.
* Shared memory tests in `pattern_tests` are currently Linux-specific.
