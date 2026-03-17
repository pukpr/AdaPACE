%%%% This is a 'nodes.pro' file.
%%%% The '%' character works as a comment delimiter.

connection (gyrator, move, 2).
connection (gyrator, get_status, 2).
connection (gyrator, halt, 2).

host_node (1, "localhost").
host_node (2, "localhost").  %% 'gyrator' messages sent to this node
