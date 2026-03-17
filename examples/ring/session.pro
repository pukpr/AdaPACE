%%
%% This is a 'session.pro' template.  Case and quoting is critical. Comment tokens are %
%%
%% $id: session.pro,v 1.1 05/15/2003 13:32:41 pukitepa Exp $

%% ------------------------------------
%% Process Identification 
%% ------------------------------------
%%   proc (N, Process, Directory, env(EnvironmentVariables), arg(CommandLineArguments)).
%%
proc (1, "pace-ring_driver", Dir, 
         env("PACE_NODE=1"), 
         arg("SERVER 2")) :- pwd(Dir).
proc (2, "pace-ring_driver", Dir, 
         env("PACE_NODE=2"), 
         arg("SERVER 1")) :- pwd (Dir).

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
