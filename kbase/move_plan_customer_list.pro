mp_tl (id ("test_move_2"),
       action ("Execute"),
       schedule (year(2005), month(1), day(1), seconds(1)),
       num_waypoints (2),
       waypoint_list (
         waypoint (n="1", box (p1 (easting(535000), northing(3926000), zone(11)),
                               p2 (easting(535001), northing(3926001), zone(11))),
                        time_on_customer(true),
                        schedule(year(2005), month(1), day(1), seconds(1))),
         waypoint (n="2", box (p1 (easting(535010), northing(3926010), zone(11)),
                               p2 (easting(535011), northing(3926011), zone(11))),
                        time_on_customer(true),
                        schedule(year(2005), month(1), day(1), seconds(1)))
       )
).
                        
get_mp_tl_static (MP, Action, Year, Month, Day, Seconds, Num_Waypoints) :-
   mp_tl (id(MP), action (Action),
          schedule(year(Year), month(Month), day(Day), seconds(Seconds)),
          num_waypoints(Num_Waypoints), _).

%get_mp_waypoint (MP, Waypoint_Num, P1E,P1N,P1Z, P2E,P2N,P2Z, TOT, Y,M,D,S) :-
%   mp_tl (id(MP), _, _, _, [waypoint_list|Wlist]),
%   tag (Wlist, waypoint, WP),
%   att (WP, n, Waypoint_Num),
%   tag (WP, box, [p1(easting(P1E),northing(P1N),zone(P1Z)),
%                  p2(easting(P2E),northing(P2N),zone(P2Z))]),
%   tag (WP, time_on_customer, TOT),
%   tag (WP, schedule, [year(Y),month(M),day(D),seconds(S)]).


% trace?   % toggle trace on and off
get_mp_tl_static ("test_move_2", Action, Year, Month, Day, Seconds, Num_Waypoints)?
% trace?


% get_mp_waypoint ("test_move_2", "1", P1E,P1N,P1Z, P2E,P2N,P2Z, TOT, Y,M,D,S)?

