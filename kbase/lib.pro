%%
%% Common library rules
%% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XML style rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tag ([[Tag|[Value]]|_], Tag, Value).
tag ([[Tag|Value]|_], Tag, Value).
tag ([_|R], Tag, Value) :- !, tag (R, Tag, Value).

att ([Att = Value|_], Att, Value).
att ([_|R], Att, Value) :- !, att (R, Att, Value).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Registration process for enumerated facts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
register_count(X) :- 
   assert (register_counter(X(0))), 
   fail.
register_count(X, Q) :- 
   register_counter (X(N)), 
   Q is N + 1, 
   retract(register_counter(X(N))), 
   assert (register_counter(X(Q))).

register_1 (X) :- register_count (X).
register_1 (X) :- X (L1), register_count (X, Q), assert (X(Q,L1)), fail.
register_1 (_).

register_2 (X) :- register_count (X).
register_2 (X) :- X (L1,L2), register_count (X, Q), assert (X(Q,L1,L2)), fail.
register_2 (_).

register_3 (X) :- register_count (X).
register_3 (X) :- X (L1,L2,L3), register_count (X, Q), assert (X(Q,L1,L2,L3)), fail.
register_3 (_).

register_4 (X) :- register_count (X).
register_4 (X) :- X (L1,L2,L3,L4), register_count (X, Q), assert (X(Q,L1,L2,L3,L4)), fail.
register_4 (_).

register_5 (X) :- register_count (X).
register_5 (X) :- X (L1,L2,L3,L4,L5), register_count (X, Q), assert (X(Q,L1,L2,L3,L4,L5)), fail.
register_5 (_).

register_6 (X) :- register_count (X).
register_6 (X) :- X (L1,L2,L3,L4,L5,L6), register_count (X, Q), assert (X(Q,L1,L2,L3,L4,L5,L6)), fail.
register_6 (_).

register_14 (X) :- register_count (X).
register_14 (X) :- X (L1,L2,L3,L4,L5,L6,L7,L8,L9,L10,L11,L12,L13,L14), register_count (X, Q), assert (X(Q,L1,L2,L3,L4,L5,L6,L7,L8,L9,L10,L11,L12,L13,L14)), fail.
register_14 (_).

% Add more registration entries for higher arity here


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% the following embedded in rule processor --
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% retractall(X) :- X, retract(X), fail.
%% retractall(_).
%% member (Part, [Part|List]).
%% member (Part, [Other|List]) :- member (Part, List).
%% argv and getenv are now defined on startup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
