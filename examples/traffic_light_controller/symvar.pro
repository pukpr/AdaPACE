%% ------------------------------------
%%  Symbol/Variable declarations
%% ------------------------------------
%%    symvar (ScriptVar, ProcessName, AdaName, Type/EnumList).
%%
symvar("sense",   "tlc_test", "tlc__sense_car", bool).
symvar("short",   "tlc_test", "tlc__short",     int).
symvar("medium",  "tlc_test", "tlc__medium",    int).
symvar("long",    "tlc_test", "tlc__long",      int).
symvar("street",  "tlc_test", "tlc__street",    ["red","yellow","green"]=char).
symvar("highway", "tlc_test", "tlc__highway",   ["red","yellow","green"]=char).

bin_id (N) :- run(N, BIN, _, _, _), prin(["bin_id(", N, ") = ", BIN]), nl.
