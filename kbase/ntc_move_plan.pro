
mp(id ("P1"),
   data(
    plan(test),
    start_time(0.0),
    no_later_than (false),
    max_corridor (100),
    num_points(4),
    point_list(    
        point(n="1", type(sp), east(535000), north(3924000), zone_num(11), hemisphere ("North"), time(0), date()),
        point(n="2", type(cp), east(534340), north(3923800), zone_num(11), hemisphere ("North"), time(0), date()),
        point(n="3", type(cp), east(534000), north(3923100), zone_num(11), hemisphere ("North"), time(0), date()),
        point(n="4", type(rp), east(534900), north(3923000), zone_num(11), hemisphere ("North"), time(0), date())
        )
   )).

mp(id ("P2"),
   data(
    plan(test),
    start_time(0.0),
    no_later_than (false),
    max_corridor (100),
    num_points(4),
    point_list(    
        point(n="1", type(sp), east(535000), north(3925000), zone_num(11), hemisphere ("North"), time(0), date()),
        point(n="2", type(cp), east(536000), north(3925000), zone_num(11), hemisphere ("North"), time(0), date()),
        point(n="3", type(cp), east(536000), north(3926000), zone_num(11), hemisphere ("North"), time(0), date()),
        point(n="4", type(rp), east(535000), north(3926000), zone_num(11), hemisphere ("North"), time(0), date())
        )
   )).


