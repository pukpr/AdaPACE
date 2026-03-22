
get_job_static(Fm, Customer, Job_Type, Control, Start_Time, Phase, Num_Items) :-
    job(id (Fm), _, [data | List]),
    tag (List, customer, Customer),
    tag (List, job_type, Job_Type),
    tag (List, control, Cont),
    att (Cont, type, Control),
    att (Cont, start_time, Start_Time),
    tag (List, phase, Phase),
    tag (List, items, Num_Items).

%% As paths are calculated during a job, the following will be asserted to kbase
%% zoning ("job id", Item_Num, Zone_Num).

%% default zone num. this is utilized before the flights have occurred
zoning (_, _, 1).

get_item(Fm, Item_Num, Zone, Item_Type, Timer_Type, Property, Elev, Azim, Setting, On_Customer, East, North, Zone_Num, Hemisphere) :- 
    job(id (Fm), _, [data | List]),
    tag (List, item_list, RL),
    tag (RL, item, R),
    concat([Item_Num,""],RN), %% Attribute is a string
    att (R, n, RN), 
    tag (R, location, Loc),
    att (Loc, easting, East),
    att (Loc, northing, North),
    att (Loc, zone_num, Zone_Num),
    att (Loc, hemisphere, Hemisphere),
    tag (R, el, Elev),
    tag (R, az, Azim),
    zoning (Fm, Item_Num, Zone),
    tag (R, box, Item_Type),
    tag (R, timer, Timer),
	att (Timer, type, Timer_Type),
        att (Timer, setting, Setting),
    zone_to_prop (Zone, Property),
    tag (R, on_customer, On_Customer).

find_job_completed (completed_job(id(Id),Data)) :- 
    job_completed(Id),
    job(Id, _, Data).

get_job_record(job_records (Record)) :-
    findall (R, find_job_completed(R), Record).

get_job (job(Id, description (Description), num_items(N))) :-
    job(Id, Description, data (_, _, _, _, items (N), _)).

get_all_jobs(jobs(Jobs)) :-
    findall (R, get_job(R), Jobs).
    
get_job_data (Id, Data) :-
    job (id(Id), _, Data).

