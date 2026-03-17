%%
%% This is a 'session.pro' template.  Case and quoting is critical. Comment tokens are %
%%
%% $id: session.pro,v 1.1 05/15/2003 13:20:50 pukitepa Exp $

%% ------------------------------------
%% Process Identification 
%% ------------------------------------
%%   proc (N, Process, Directory, env(EnvironmentVariables), arg(CommandLineArguments)).
%%
proc (1, "suv-driver", Dir, env("PACE_NODE=0"), arg("")) :- path(".", Dir).

%% ------------------------------------
%% Process Launching
%% ------------------------------------
%%   run (N, Target, UpString, XDisplay, Debugging).
%%
run (1, "localhost", "P4 is ready", "localhost:0.0", trace(true)).

%% ------------------------------------
%%  Release Group declarations
%% ------------------------------------
%%    group (G, FirstN, LastN, RelativeWaitTimeSinceLastGroupUp).
%%
group (1, from(1), to(1), wait(0.0)).

%%%%%%%%%%%%%%%
%% Rules below
%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%
%% Merge SymVar Database
%%%%%%%%%%%%%%%%%%%%%%%%
main("suv-driver").

consult ("symvar.dat.pro")?
consult ("symvar.pro")?
