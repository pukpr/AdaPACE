launch ("../../drivers/bg.sh").

proc (1, "obj/tetris_main", Dir, env("PACE_NODE=1"), arg("")) :- pwd (Dir).
proc (2, L, Dir,
      env("DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 PATH=/usr/bin/ GZ_SIM_SYSTEM_PLUGIN_PATH=../../plugins/gazebo/"),
      arg("gz sim -r tetris.sdf")) :-
  launch (L),
  pwd (Dir).

run (1, "localhost", "P4 is ready", "localhost", trace(true)).
run (2, "localhost", "P4 is ready", "localhost", trace(true)).

group (1, from(1), to(2), wait(0.0)).
