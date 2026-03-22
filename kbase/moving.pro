

%% rules for getting a checkpoint from a move_plan
%% This uses a mixture of positional and named patterned matching

parse_date ([month(M),day(D),year(Y),time(T),zulu(Z)], M, D, Y, T, Z).
parse_date ([], 0, 0, 0, 0, z).

get_cp(Name, N, Type, East, North, Zone_Num, Hemisphere, TT, M, D, Y, T, Z) :- % trace,
   mp(id (Name), data(_,_,_,_,_,[point_list|PL])),
   tag(PL, point, L),
   concat([N,""],Num), %% Attribute is a string
   att(L, n, Num),!,
   tag(L, type, Type),
   tag(L, east, East),
   tag(L, north, North),
   tag(L, zone_num, Zone_Num),
   tag(L, hemisphere, Hemisphere),
   tag(L, time, TT),
   tag(L, date, DTZ),
   parse_date(DTZ, M, D, Y, T, Z).

get_mp_list(Name_List, Plan_List) :-
    findall(Name, mp(id (Name), _), Name_List),
    findall(Plan, mp(_, data (plan (Plan),_,_,_,_,_)), Plan_List).

get_mp (Id, Plan, Start_Time, No_Later_Than, Max_Corridor, Num_Points) :-
    mp(id(Id),
      data(
        plan(Plan),
        start_time(Start_Time),
        no_later_than(No_Later_Than),
        max_corridor(Max_Corridor),
        num_points(Num_Points),
        _)).
        
get_num_points(Name, Num) :-
    mp(id (Name), data (_, _, _, _, num_points(Num), _)).


%%% Alternate version of get_mp_list

mp_item(move_plan(name(Item),dest_type(Plan))) :- 
    mp(id (Item),data (plan(Plan), _, _, _, _, _)).

get_mp_item_list (move_plan_list(MP_Item_List)) :-
    findall(MP, mp_item(MP), MP_Item_List).

% example Query
% vkb.query?set=get_mp_item_list(MP_List)&xml_tree=

% merge_mp ([], [], L, mp_list(L)).
% merge_mp ([F1|R1], [F2|R2], L, R) :-
%     merge_mp (R1, R2, [mp(name(F1),plan(F2))|L], R).
% 
% get_mp_item_list2 (MP_List) :- 
%     findall(Name, mp(Name, _), Name_List),
%     findall(Plan, mp(_, data (plan (Plan), _, _)), Plan_List),
%     merge_mp (Name_List, Plan_List, [], MP_List).
    

