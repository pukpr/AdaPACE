# Tetris Falling Pieces — Gazebo 3D

This example visualises all seven classic Tetris tetrominoes falling inside
Gazebo Sim, controlled in real time by an Ada agent.

## Pieces

| Link       | Colour | Shape          |
|------------|--------|----------------|
| `i_piece`  | Cyan   | `[ ][ ][ ][ ]` |
| `o_piece`  | Yellow | 2 × 2 square   |
| `t_piece`  | Purple | T-shape        |
| `s_piece`  | Green  | S-shape        |
| `z_piece`  | Red    | Z-shape        |
| `j_piece`  | Blue   | J-shape        |
| `l_piece`  | Orange | L-shape        |

Each piece is a single link inside the `Tetris` model.  The individual
coloured blocks are multiple `<visual>` elements within that link, arranged
on a 0.5 m grid with 0.45 m block faces (leaving a small visible gap).

## Architecture

| File               | Purpose                                                  |
|--------------------|----------------------------------------------------------|
| `tetris.sdf`       | Gazebo world: 7 tetromino links + dark background        |
| `tetris.ads`       | Ada package — `Pieces` enum + `Hal.Gazebo_Commands` instance |
| `tetris_main.adb`  | Control agent — simulates falling, rotation, recycle     |
| `tetris.gpr`       | GNAT project file                                        |
| `session.pro`      | P4 launcher: starts Gazebo and the Ada agent together    |

### Gravity

Gravity is set to `0 0 0` in the SDF.  The Ada agent drives all motion
programmatically via `Gz.Set_Pose`, which gives the future Tetris game
(from `pukpr/degas`) full deterministic control over piece position and
orientation without fighting the physics solver.

### HAL interface

```ada
package Gz is new Hal.Gazebo_Commands (Key => 123456, Entities => Pieces);
```

`Gz.Set_Pose (Name => P, X => …, Z => …, Yaw => …)` — absolute position +
orientation.  `Gz.Set_Rot` is also available for continuous spin.

The shared-memory key `123456` must match the `SHM_KEY` compiled into
`libTablePlugin.so` (see `plugins/gazebo/`).

## Building and Running

### Build
```bash
sh BUILD
```

This runs `gprbuild -aP../.. tetris.gpr` and places the binary in `obj/`.

### Run
```bash
sh RUN
```

This launches the P4 driver, which concurrently starts:
1. `obj/tetris_main` — the Ada falling-pieces controller
2. `gz sim -r tetris.sdf` — the Gazebo visualisation

Type `-999` in the P4 console to shut down both processes.

## Future Integration

The control loop in `tetris_main.adb` is intentionally simple (all seven
pieces fall and recycle).  The Ada Tetris game in the
[pukpr/degas](https://github.com/pukpr/degas) repository will replace this
loop with full game logic — piece selection, player input, collision
detection and line clearing — while reusing the same `Gz.Set_Pose` /
`Gz.Set_Rot` interface to drive the Gazebo visualisation.
