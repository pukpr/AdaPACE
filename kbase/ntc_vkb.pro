% Load all kbases

%% the starting point of the vehicle
northing (3925000).
easting (535000).

kbase_path ("./").

kbase (File) :-
	kbase_path (Path),
	concat ([Path, File], File_Path),
	consult (File_Path),
	assert (kbase_loaded(File_Path)).

kbase_loaded (kbase_pro).

% specific to location
kbase ("ntc_map.pro")?
kbase ("ntc_delivery_job.pro")?
kbase ("ntc_move_plan.pro")?

% not specific to location
kbase ("lib.pro")?
kbase ("job_lib.pro")?
kbase ("moving.pro")?
kbase ("terrain.pro")?
kbase ("plant.pro")?
kbase ("audio.pro")?
kbase ("items.pro")?
kbase ("move_plan_customer_list.pro")?
kbase ("joystick_mapping.pro")?

%%%%%%%%%%%%%%%%%%% test follows

color (blue).
color (red).

test(
 top(item1(value1),
     item2(value2),
     item3("Value3")
    )
).

test_list(d("A B C", x, y, z, "Q", "hello there")).


