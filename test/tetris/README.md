# Tetris — Ada Tasking with PACE Synchronization

A classic Tetris implementation in Ada using native tasking, used here as a
demonstration of integrating Ada task entries with the PACE message-passing
framework.

## Structure

| File | Description |
|------|-------------|
| `tetris.ads/adb` | Generic game loop; instantiate with a `Get_Immediate` provider |
| `ttetris.ads` | Test instantiation using `Testing_Input.Get_Immediate` |
| `dtetris.ads` | Display instantiation using `Ada.Text_IO.Get_Immediate` |
| `arrival.ads/adb` | PACE message types and private tasks that drive brick arrivals |
| `bricks.ads/adb` | Public task `Move` — handles user input and brick movement |
| `wall.ads/adb` | Game grid state |
| `screen.ads/adb` | ANSI cursor/screen utilities |
| `testing_input.ads/adb` | Deterministic key sequence for automated testing |

## PACE Message Pattern

`Arrival` wraps three private Ada tasks (`Manager`, `Timer`, `Speeder`) behind
PACE `Msg` types.  Each `Input` procedure delegates to the corresponding task
entry, keeping the tasks private to the package body:

```ada
type Manager_Start  is new Pace.Msg with null record;  -- calls Manager.Start
type Manager_Tick   is new Pace.Msg with null record;  -- calls Manager.Tick (non-blocking)
type Manager_Stop   is new Pace.Msg with null record;  -- calls Manager.Stop

type Timer_Start    is new Pace.Msg with null record;
type Timer_Stop     is new Pace.Msg with null record;

type Speeder_Start  is new Pace.Msg with null record;
type Speeder_Stop   is new Pace.Msg with null record;
```

Callers dispatch via `Pace.Dispatching.Input`:

```ada
Pace.Dispatching.Input (Arrival.Manager_Start'(Pace.Msg with null record));
...
Pace.Dispatching.Input (Arrival.Manager_Stop'(Pace.Msg with null record));
```

`Manager_Tick` uses a non-blocking `select`/`else` guard so the `Timer` task
never blocks if `Manager` is busy.

## Building

```sh
gprbuild -P tetris.gpr
```

Produces `obj/ttetris` (automated test runner) and `obj/dtetris` (interactive).

## Running

```sh
# Interactive (requires a terminal with ANSI support):
obj/dtetris

# Automated test run (terminates after a fixed input sequence):
obj/ttetris
```

Controls: `4` left · `6` right · `5` rotate · `2` drop
