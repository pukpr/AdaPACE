%% session.pro -- P4 distributed launcher session for the Tugbot simulation
%%
%% Process 1: Ada simulation + PACE web server
%% Process 2: Gazebo 3D visualiser (tugbot SDF world)

launch ("../../drivers/bg.sh").

proc (1, "obj/tugbot_main", Dir, env("PACE_NODE=1 PACE=../.."), arg("")) :- pwd (Dir).
proc (2, L, Dir,
      env("DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 PATH=/usr/bin/ GZ_SIM_RESOURCE_PATH=. GZ_SIM_SYSTEM_PLUGIN_PATH=../../plugins/gazebo/"),
      arg("gz sim -r tugbot.sdf")) :-
  launch (L),
  pwd (Dir).

run (1, "localhost", "P4 is ready", "localhost", trace(true)).
run (2, "localhost", "P4 is ready", "localhost", trace(true)).

group (1, from(1), to(2), wait(0.0)).
