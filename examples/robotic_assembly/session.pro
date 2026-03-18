%%
%% session.pro for robotic_assembly
%%

proc (1, "obj/plc_main",      Dir, env("PACE_NODE=1"), arg("")) :- path(".", Dir).
proc (2, "obj/conveyor_main", Dir, env("PACE_NODE=2"), arg("")) :- path(".", Dir).
proc (3, "obj/robot_a_main",  Dir, env("PACE_NODE=3"), arg("")) :- path(".", Dir).
proc (4, "obj/robot_b_main",  Dir, env("PACE_NODE=4"), arg("")) :- path(".", Dir).
proc (5, "obj/robot_c_main",  Dir, env("PACE_NODE=5"), arg("")) :- path(".", Dir).
proc (6, "obj/vision_main",   Dir, env("PACE_NODE=6"), arg("")) :- path(".", Dir).

run (1, "localhost", "P4 is ready", "localhost", trace(true)).
run (2, "localhost", "P4 is ready", "localhost", trace(true)).
run (3, "localhost", "P4 is ready", "localhost", trace(true)).
run (4, "localhost", "P4 is ready", "localhost", trace(true)).
run (5, "localhost", "P4 is ready", "localhost", trace(true)).
run (6, "localhost", "P4 is ready", "localhost", trace(true)).

group (1, from(1), to(6), wait(0.0)).

color(1,blue,black).
color(2,yellow,black).
color(3,red,black).
color(4,green,black).
color(5,magenta,black).
color(6,cyan,black).
color(_,white,black).

