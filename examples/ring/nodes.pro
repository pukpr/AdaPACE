neighbor (N) :- dde(1, "SERVER", N). %% command line argument

connection(ring, token, N) :- neighbor (N).

consult ("session.pro")?

host_node(N,Host) :- run (N, Host, _, _, _).

% host_node (1, "localhost").
% host_node (2, "localhost").


