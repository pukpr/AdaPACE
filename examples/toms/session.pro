%%
%% This is a 'session.pro' template.  Case and quoting is critical. Comment tokens are %
%%
%% $id: session.pro,v 1.2 05/15/2003 13:46:39 pukitepa Exp $

%% ------------------------------------
%% Process Identification 
%% ------------------------------------
%%   proc (N, Process, Directory, env(EnvironmentVariables), arg(CommandLineArguments)).
%%
proc (1, "start_publisher_1", Dir, env("PACE_NODE=1"), arg("")) :-
    pwd(Dir).
proc (N, "start_subscriber_1", Dir, env(Env), arg("")) :-
    pwd(Dir),
    nproc(N),
    N > 1, N < 6,
    concat(["PACE_NODE=", N], Env).

%% ------------------------------------
%% Process Launching
%% ------------------------------------
%%   run (N, Target, UpString, XDisplay, Debugging).
%%
run (N, "localhost", "P4 is ready", "localhost", trace(true)) :- proc (N, _,_,_,_).

%% ------------------------------------
%%  Release Group declarations
%% ------------------------------------
%%    group (G, FirstN, LastN, RelativeWaitTimeSinceLastGroupUp).
%%
group (N, from(N), to(N), wait(0.0)) :- proc (N, _,_,_,_).

color (1, black, white).

%%%%%%%%%%%%%%%%%%%%%%%%
%% Merge SymVar Database
%%%%%%%%%%%%%%%%%%%%%%%%
% consult ("symvar.pro")?
