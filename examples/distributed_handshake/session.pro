%%
%% session.pro for distributed_handshake
%%

proc (1, "obj/initiator_main", Dir, env("PACE_NODE=1"), arg("")) :- pwd (Dir).
proc (2, "obj/responder_main", Dir, env("PACE_NODE=2"), arg("")) :- pwd (Dir).
proc (3, "obj/verifier_main",  Dir, env("PACE_NODE=3"), arg("")) :- pwd (Dir).

run (1, "localhost", "P4 is ready", "localhost", trace(true)).
run (2, "localhost", "P4 is ready", "localhost", trace(true)).
run (3, "localhost", "P4 is ready", "localhost", trace(true)).

group (1, from(1), to(3), wait(0.0)).
