# test

Unit and integration tests for the AdaPACE library.

Tests are written in Ada and use AUnit (the Ada unit-testing framework) unless otherwise noted.  Each test package mirrors the source package it exercises (e.g. `test/pace-comms_test.adb` tests `src/pace-comms.adb`).

## Running the tests

```
gprbuild -P test/test.gpr
./bin/test_runner
```

## Conventions

* Test packages are named `<Tested_Package>_Test`.
* Each test case covers one logical behaviour; test names describe the expected outcome.
* Simulate hardware dependencies with stubs placed in `test/stubs/`.
