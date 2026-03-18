%%%% nodes.pro for robotic_assembly

connection (assembly, load_tray, 2).
connection (assembly, tray_loaded, 1).
connection (assembly, inspect_tray, 6).
connection (assembly, inspection_result, 1).
connection (assembly, prepare_a, 3).
connection (assembly, place_cells, 3).
connection (assembly, placement_done, 1).
connection (assembly, pick_busbar, 4).
connection (assembly, busbar_cleared, 1).
connection (assembly, weld_cells, 5).
connection (assembly, welding_done, 1).

host_node (1, "localhost").
host_node (2, "localhost").
host_node (3, "localhost").
host_node (4, "localhost").
host_node (5, "localhost").
host_node (6, "localhost").
