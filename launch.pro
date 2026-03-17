%%%%%%%%%%%%%%%%% LAUNCHING RULES %%%%%%%%%%%%%%%%%%%%%%%%%%%
% -- List of P4 externally accessible "stored procedure" --
% run (note: arity 7 only)
% run_dummy
% proc
% groups
% table
% colors
% test
% poll_period
% expect_timeout
% scope_vars
% get_var

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

%%%%%%%%%%%%%%%%% CONFIG RULES %%%%%%%%%%%%%%%%%%%%%%%%%%%

stat :- post ("0 ").
ct :- post ("0").
scope(P,L,H) :- concat([P," .codetest__scope 16#",L,H,"#"],S), post(S).
pipe(P,Bool) :- concat([P," .codetest__verbose_pipe ", Bool],S), post(S).
scope :- post("0 .codetest__scope").
pipe :- post("0 .codetest__verbose_pipe").

table (N, "(none)") :- hfi (N,_,_), !.
table (N, "(none)") :- bg (N,_,_), !.
table (N, "codetest") :- proc (N, _, _, _, _).  %% All execs use the same codetest table
   
expect_timeout(10000).

poll_period (0.0) :- system ("CODETEST_PIPE"), !.
poll_period (1.0).

scope_variables (_, first(1), last(32767)).
scope_vars (N, First, Last) :- scope_variables (N, first(First), last(Last)).

groups (N, From, To, Wait) :- group (N, from(From), to(To), wait(Wait)).

%%%%%%%%%%%%%%%%% BIT RULE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
test :-
   nproc(N),
   group (G, from(L), to(H), wait(T)),
   run (N, Bin, Dir, Exec, Up, Display, Trace), N >= L, N =< H,
   proc (N, Proc, _, _, arg(Arg)),
   prin (["Group ", G, " release @ T => ", T, " sec"]), nl,
   table (N, CT),
   prin (["  N=", N, " | ", Bin]), nl,
   prin (["    DIR      => ", Dir]), nl,
   prin (["    ARG      => ", Arg]), nl, 
   prin (["    PROC     => ", Proc]), nl, 
   prin (["    EXEC     => ", Exec]), nl, 
   prin (["    MATCH    => '", Up, "'"]), nl,
   prin (["    DISPLAY  => ", Display]), nl,
   prin (["    TRACING  => ", Trace]), nl,
   prin (["    CODETEST => ", CT, ".idb"]), nl,
   fail.
test.

%% 1-line shell commands for launching individually, use arg CMDS or env P4CMDS
commands :- 
   nproc(N),
   group (G, from(L), to(H), wait(T)),
   run (N, Bin, Dir, Exec, Up, Display, Trace), N >= L, N =< H,
   proc (N, Proc, Dir, env(Env), arg(Arg)),
   prin (["## ", Proc]), nl,
   prin (["$P4SHELL ", Bin, " '(cd ", Dir, "; env ", Env,
          " DISPLAY=",Display," ./", Proc, " ", Arg, " )'"]), nl,
   fail.
commands.

%%%%%%%%%%%%%%%%% SYMBOL TABLE RULES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

enum([], _, _, _).
enum([F|R], R, Val, Next) :- 
   prin ([F, "=", Val, ";"]),
   Next is Val + 1,
   !,enum(R, _, Next, _).

print_values (Val) :- 
   integer(Val), !,   %% Integers declare a string length
   prin (["str ", Val, "=0;"]).
print_values (Val) :- 
   atom(Val), !,
   prin (Val).
print_values (List = Type) :- 
   prin ([Type, " "]), !,    %% list of enums
   enum (List, _, 0, _).
print_values (Val) :- 
   prin ("char "),    %% list of enums (assumed char)
   enum (Val, _, 0, _).

symvar (Var, Proc, SW, Values, []) :- symvar (Var, Proc, SW, Values).

get_var :-
   nproc(N),
   symvar (Var, Proc, SW, Values, Offset),
   run (N, _Host, _Up, _Display, _Trace),
   proc (N, Proc, Dir, _Env, _Arg),
   prin ([N, " ", Dir, "/ ", Proc, " ", SW, " ", Var, " "]), 
   print_values (Values), 
   prin ([" ", Offset]), 
   nl, fail.
get_var.

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

proc (1, Main, Home, env ("PACE_NODE=1"), arg(Arg)) :- pwd(Home), local_main (Main,Arg).
run (1, "localhost", "P4 is ready", "localhost:0.0", trace(true)) :- local_main (_,_).
group (1, from(1), to(1), wait(0.0)) :- local_main (_,_).

% allows one to specify the display with an env var on the command line
% by using INSTANCE_display=DISPLAY ex.  crew1_1_display=wcsn133:0.0
get_display (Instance, Display) :-
   concat([Instance, "_display"], Display_Env),
   getenv(Display_Env, Display).

% the default display
get_display(_, ":0.0").

ccat([], Out, Out) :- !.
ccat([F=X|R], String, Z) :- 
   concat([String, " ", F, "=", X], Out),
   ccat(R, Out, Z).
ccat([F|R], String, Z) :- 
   concat([String, " ", F], Out),
   ccat(R, Out, Z).

%% String-based
proc (N, Main, Dir, env (Env), arg(Arg)) :- 
   logical (Main, N, Instance),
   app (Host, Env, Rel, Main, Arg, Instance),
   path (Rel, Dir).
%% List-based   
proc (N, Main, Dir, env (Env), arg(Arg)) :- 
   logical (Main, N, Instance),
   app (Host, E, Rel, Main, A, Instance),
   ccat (E, "", Env),
   ccat (A, "", Args),
   path (Rel, Dir).
run (N, Host, "P4 is ready", Display, trace(true)) :- 
   logical (Main, N, Instance),
   get_display(Instance, Display),
   app (Host, Env, Rel, Main, Arg, Instance).
group (N, from(N), to(N), wait(0.0)) :- 
   logical (Main, N, Instance),
   app (Host, Env, Rel, Main, Arg, Instance).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Symbol/Variable declarations for CodeTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%    symvar (ScriptVar, ProcessName, AdaName, Type/EnumList).
%%
symvar("codetest__timing",       _, "codetest__timing",       int).
symvar("codetest__synchpoint",   _, "codetest__synchpoint",   flt).
symvar("codetest__scope",        _, "codetest__scope",        uint).
symvar("codetest__verbose_pipe", _, "codetest__verbose_pipe", bool).
%% shorter versions
symvar(S,M,S,Type) :- main(M), sv(S,Type). 
symvar(S,M,S,Type,N) :- main(M), sv(S,Type,N).

command_line_main?
generate_procs(1)?


%% For extracting HOST info from an environment variable (ex. DIVISION=genesis)
host (Service, Host) :- getenv (Service, Host).

%% Creates an environment variable from an environment variable
service (Service, Env) :- getenv (Service, Host), concat ([" ", Service,"=",Host], Env), !.
service (Service, "").

write_to_clean_host (Exec, Host) :-
   getenv ("P4SHELL", Shell),
   getenv("PWD", Path), %% "path" not defined now, loaded by P4 in launch.pro!
   % it is necessary to have killgrep put a space in front of the Exec arg 
   % to avoid killing other processes
   concat ([Shell, " ", Host, " ", Path, "/../../Common/ssom/test_tools/killgrep '\ ", Exec, "'"], Output),
   prin (Output),
   nl.

% no space in front
write_to_clean_host_exact (Exact, Host) :-
   getenv ("P4SHELL", Shell),
   getenv("PWD", Path), %% "path" not defined now, loaded by P4 in launch.pro!
   concat ([Shell, " ", Host, " ", Path, "/../../Common/ssom/test_tools/killgrep '", Exact, "'"], Output),
   prin (Output),
   nl.

%% creates the file .clean_demo which is used as an alternative way to kill apps
write_to_clean (Service, Exec) :-
   getenv (Service, Host),
   write_to_clean_host (Exec, Host).

write_to_clean_final :-
   write_to_clean_host_exact("Common/bin/Linux/p4_main", "$HOST"),
   write_to_clean_host("/usr/bin/X11/xmessage", "$HOST"),
   write_to_clean_host_exact("Common/ssom/test_tools/p4.sh", "$HOST"), !.

%% determines what launches and the ordering of launch
lnum(0).
logicals(Service, Exec) :- 
   getenv(Service, Host), 
   lnum(N), 
   M is N+1, 
   asserta(lnum(M)),
   assert(logical(Exec, M, Service)),
   write_to_clean (Service, Exec).
logicals(_,_).

define_launch_apps?
