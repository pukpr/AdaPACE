%%
%% This is a 'session.pro' template.  Case and quoting is critical. Comment tokens are %
%%

%% ------------------------------------
%% Process Identification 
%% ------------------------------------
%%   proc (N, Process, Directory, env(EnvironmentVariables), arg(CommandLineArguments)).
%%
proc (1, "client_main", Dir, env("PACE_NODE=1"), arg("")) :- path(".", Dir).
proc (2, "gyrator_main", Dir, env("PACE_NODE=2"), arg("")) :- path(".", Dir).

%% ------------------------------------
%% Process Launching
%% ------------------------------------
%%   run (N, Target, UpString, XDisplay, Debugging).
%%
run (1, "localhost", "P4 is ready", "localhost", trace(true)).
run (2, "localhost", "P4 is ready", "localhost", trace(true)).

%% ------------------------------------
%%  Release Group declarations
%% ------------------------------------
%%    group (G, FirstN, LastN, RelativeWaitTimeSinceLastGroupUp).
%%
group (1, from(1), to(2), wait(0.0)).

%%%%%%%%%%%%%%%
%% Rules below
%%%%%%%%%%%%%%%


