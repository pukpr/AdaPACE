default_el (30.0).
default_az (0.0).


%% use list_item to create a list of items with default parameters, except you can specify
%% the elevation
one_item (Num, El, Easting, Northing, Item) :-
   concat([Num], Str_Num),
   Item = item(n=Str_Num,
              location(easting=Easting, northing=Northing, zone_num="11", hemisphere="North"),
              el(El), az(0.0), on_customer(0.0),
              box("ABCD"), timer(type="abs", setting="edt")).

list_items(0, _, Easting, Northing, List, List) :- !.
list_items(Num, El, Easting, Northing, List, Result) :- 
   one_item(Num, El, Easting, Northing, H),
   M is Num - 1,
   list_items(M, El, Easting, Northing, [H|List], Result).


job(id ("1"),
   "Evaluation 1",
   data(
    customer("#100"),
    job_type("Delivery"),
    control(type="When Ready", start_time="0"),
    phase("Ready"),
    items(N),
    item_list(List)
)) :- N=5, default_el(El), Easting=535000, Northing=3935000, list_items (N, El, Easting, Northing, [], List).


job(id ("2"),
   "Evaluation 2",
   data(
    customer("#200"),
    job_type("Delivery"),
    control(type="When Ready", start_time="0"),
    phase("Ready"),
    items(8),
    item_list(
        item(n="1",
          location(easting="535000", northing="3927000", zone_num="11", hemisphere="North"),
          el(75.0), az(0.0), on_customer(0.0),
          box("A1"), timer(type="abs", setting="edt")),
        item(n="2",
          location(easting="535000", northing="3927010", zone_num="11", hemisphere="North"),
          el(65.0), az(0.0), on_customer(0.0),
          box("A2"), timer(type="abs", setting="edt")),
        item(n="3",
          location(easting="535000", northing="3927020", zone_num="11", hemisphere="North"),
          el(55.0), az(0.0), on_customer(0.0),
          box("A3"), timer(type="abs", setting="edt")),
        item(n="4",
          location(easting="535000", northing="3927300", zone_num="11", hemisphere="North"),
          el(45.0), az(0.0), on_customer(0.0),
          box("A4"), timer(type="abs", setting="edt")),
        item(n="5",
          location(easting="535000", northing="3927040", zone_num="11", hemisphere="North"),
          el(35.0), az(0.0), on_customer(0.0),
          box("A5"), timer(type="abs", setting="edt")),
        item(n="6",
          location(easting="535000", northing="3927050", zone_num="11", hemisphere="North"),
          el(25.0), az(0.0), on_customer(0.0),
          box("A6"), timer(type="abs", setting="edt")),
        item(n="7",
          location(easting="535000", northing="3927060", zone_num="11", hemisphere="North"),
          el(15.0), az(0.0), on_customer(0.0),
          box("A7"), timer(type="abs", setting="edt")),
        item(n="8",
          location(easting="535000", northing="3927070", zone_num="11", hemisphere="North"),
          el(0.0), az(0.0), on_customer(0.0),
          box("A8"), timer(type="abs", setting="edt"))
    )    
)).


% dummy properties
%
zone_to_prop (1, "half").
zone_to_prop (2, "half").
zone_to_prop (3, "full").
zone_to_prop (4, "full").

