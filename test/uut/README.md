# UUT Test Suite

The Uut (Unit Under Test) suite provides comprehensive integration and functional tests for core PACE components, including XML parsing, job scheduling, and notification mechanisms.

## Suite Overview

The suite covers:
- **PACE XML**: Validates XML generation and parsing.
- **PACE Jobs**: Tests the job scheduler (normal operation, cancellation, overlapping).
- **Notifications**: Verifies synchronous and asynchronous message passing.
- **Utilities**: Probability distributions and time precision tests.

## Running the tests

To run the suite in Discrete Event Simulation (DES) mode:

```bash
cd test/uut
gprbuild -P common_suite.gpr
env PACE_SIM=1 PACE_NODE=0 PACE=.. ./test_harness
```

### Simulation Mode (`PACE_SIM`)

- **`PACE_SIM=1`**: Enables Discrete Event Simulation mode. This speeds up the tests significantly by using a virtual simulation clock instead of real-time delays.
- **`PACE_SIM=0`**: Uses real-time execution. Tests will take much longer as they will wait for actual wall-clock durations.

The `PACE` environment variable should point to the root directory containing the `config.pro` and other configuration files.
