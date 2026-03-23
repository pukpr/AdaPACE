%%%%%%%%%%%%%%%%% LAUNCHING RULES %%%%%%%%%%%%%%%%%%%%%%%%%%%

background(bg, Shell) :- getenv("P4PATH",Path), concat([Path,"/bg.pl"],Shell), !.
background(No, No).

%% Running a Regular EXEC
run (N, Target, Dir, Exe, Up, Display, Trace) :- 
   proc (N, Proc, Dir, env(Env), arg(Arg)),
   background (Proc, P), % Background only if proc exe named 'bg'
   run (N, Target, Up, Display, trace(Trace)),
   concat ([Env, " ", P, " ", Arg], Exe).

%% Running a DUMMY EXEC as a testing proxy
run_dummy (N, localhost, ".", Exec, Ready, localhost, false) :-
   proc (N, Exec_Name, _, _, _), 
   run (N, _, Ready, _, _), 
   concat (["NAME='",Exec_Name,"' UP='",Ready,"' $P4PATH/proxy.tcl"], Exec).

launching_shell(Host,Shell) :- shell(Host,Shell), !.
launching_shell(_, default).

%%%%%%%%%%%%%%%%% CONFIG RULES %%%%%%%%%%%%%%%%%%%%%%%%%%%

stat :- post ("0 ").
table (N, "codetest") :- proc (N, _, _, _, _).  %% Not used any longer
expect_timeout(10000).

groups (N, From, To, Wait) :- group (N, from(From), to(To), wait(Wait)).

%%%%%%%%%%%%%%%%% BIT RULE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
test (N) :-
   nproc(N),
   group (G, from(L), to(H), wait(T)),
   run (N, Bin, Dir, Exec, Up, Display, Trace), N >= L, N =< H,
   proc (N, Proc, _, _, arg(Arg)),
   prin (["Group ", G, " release @ T => ", T, " sec"]), nl,
   prin (["  N=", N, " | ", Bin]), nl,
   prin (["    DIR      => ", Dir]), nl,
   prin (["    ARG      => ", Arg]), nl, 
   prin (["    PROC     => ", Proc]), nl, 
   prin (["    EXEC     => ", Exec]), nl, 
   prin (["    MATCH    => '", Up, "'"]), nl,
   prin (["    DISPLAY  => ", Display]), nl,
   prin (["    TRACING  => ", Trace]), nl,
   M is N+1,!,
   test (M).
%   fail.
test (N) :-
   prin (["None found @ ", N]), nl.

test :-
   test (1).
   

%% 1-line shell commands for launching individually, use arg CMDS or env P4CMDS
commands (N) :- 
   nproc(N),
   group (G, from(L), to(H), wait(T)),
   run (N, Bin, Dir, Exec, Up, Display, Trace), N >= L, N =< H,
   proc (N, Proc, Dir, env(Env), arg(Arg)),
   prin (["## ", Proc]), nl,
   prin (["$P4SHELL ", Bin, " '(cd ", Dir, " && env ", Env,
          " DISPLAY=",Display," ./", Proc, " ", Arg, " )'"]), nl,
   M is N+1,!,
   commands (M).
%   fail.
commands (N) :-
   prin (["None found @ ", N]), nl.

commands :-
   commands (1).

command_line_main :- %% replace a main exec if needed
   main(P),
   argv("main", P, M),
   retract (main(P)),
   asserta (main(M)).

generate_procs(N) :- 
   argv("max_procs", 100, Max), !,
   assert(nproc(N)), 
   M is N + 1, 
   M =< Max, 
   generate_procs(M).


path (Relative_Path, Dir) :-
   pwd (PWD),
   concat ([PWD, Relative_Path], Dir).
path (Relative_Path, Dir, default) :-
   pwd (PWD),
   concat ([PWD, Relative_Path], Dir),
   !.
path (Relative_Path, Relative_Path, _).

proc (1, Main, Home, env ("PACE_NODE=1"), arg(Arg)) :- pwd(Home), local_main (Main,Arg).
run (1, "localhost", "P4 is ready", "localhost:0.0", trace(true)) :- local_main (_,_).
group (1, from(1), to(1), wait(0.0)) :- local_main (_,_).

% allows one to specify the display with an env var on the command line
% by using INSTANCE_display=DISPLAY ex.  crew1_1_display=wcsn133:0.0
get_display (Instance, Display) :-
   concat([Instance, "_display"], Display_Env),
   getenv(Display_Env, Display), !.

% the default display
get_display(_, ":0.0").

ccat([], Out, Out) :- !.
ccat([F=X|R], String, Z) :- 
   var(X), 
   getenv(F, X), !,
   concat([String, " ", F, "=", X], Out),
   ccat(R, Out, Z).
ccat([F=X|R], String, Z) :- 
   var(X), !,
   concat([String, " "], Out),
   ccat(R, Out, Z).
ccat([F=X|R], String, Z) :- 
   concat([String, " ", F, "=", X], Out),!,
   ccat(R, Out, Z).
ccat([F|R], String, Z) :- 
   concat([String, " ", F], Out),
   ccat(R, Out, Z).

%% String-based
%proc (N, Main, Dir, env (Env), arg(Arg)) :- 
%   logical (Main, N, Instance),
%   app (Host, Env, Rel, Main, Arg, Instance),
%   path (Rel, Dir).
%% List-based   
proc (N, Main, Dir, env (Env), arg(Arg)) :- 
   logical (Main, N, Instance),
   app (E, Rel, Main, A, Instance),
   ccat (E, "", Env),
   ccat (A, "", Arg),
   host (Instance, Host),
   launching_shell(Host, Shell),
   path (Rel, Dir, Shell).
%   path (Rel, Dir).
run (N, Host, "P4 is ready", Display, trace(true)) :- 
   logical (Main, N, Instance),
   host (Instance, Host),
   get_display(Instance, Display),
   app (Env, Rel, Main, Arg, Instance).
group (N, from(N), to(N), wait(0.0)) :- 
   logical (Main, N, Instance),
   app (Env, Rel, Main, Arg, Instance).


command_line_main?
generate_procs(1)?


%% For extracting HOST info from an environment variable (ex. DIVISION=genesis)
host (Service, Host) :- getenv (Service, Host).

%% Creates an environment variable from an environment variable
service (Service, Env) :- getenv (Service, Host), concat ([" ", Service,"=",Host], Env), !.
service (Service, "").


%% determines what launches and the ordering of launch
lnum(0).
logicals(Service, Exec) :- 
   getenv(Service, Host), 
   lnum(N), 
   M is N+1, 
   asserta(lnum(M)),
   assert(logical(Exec, M, Service)).
logicals(_,_).

define_launch_apps :-
   version_2,
   apps.

define_launch_apps :-
   nl, display ("*********"), nl,
   display (" this requires a version_2 session marker"), nl,
   display ("*********").

define_launch_apps?
