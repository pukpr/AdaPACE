%%
%% weather.pro – NWS weather observation knowledge-base rules
%%
%% The PACE weather agent (examples/weather/weather_main.adb) fetches the
%% NWS current-observation XML for station KDAG and converts it to Prolog
%% via two complementary mechanisms:
%%
%%   1.  Pace.Server.Kbase_Utilities.Xml_To_Kbase
%%       Converts the entire XML document to a nested Prolog functor and
%%       asserts it as:
%%         weather_obs(current_observations(...))
%%
%%   2.  Pace.Rule_Process.Agent_Type.Assert
%%       Extracts individual leaf values with Pace.Xml_Tree.Search_Xml and
%%       asserts them as flat, single-argument facts, e.g.
%%         station_id('KDAG')
%%         obs_condition('Fair')
%%         obs_temp_f('73.0')
%%         obs_temp_c('22.8')
%%         obs_humidity('13')
%%         obs_wind('CALM')
%%         obs_pressure_mb('989.2')
%%         obs_visibility('10.00')
%%         obs_dewpoint_f('30.9')
%%         obs_obs_time('Last Updated on ...')
%%         obs_location('Death Valley, Death Valley National Park Airport, CA')
%%
%% The rules below query the flat facts produced by mechanism 2.
%%

%% weather_report/5
%%   Retrieve the five most-often displayed weather fields in one query.
%%   Bound variables on return:
%%     Station   – ICAO station identifier
%%     Condition – sky/weather description
%%     TempF     – temperature in degrees Fahrenheit
%%     Humidity  – relative humidity percentage
%%     Wind      – wind direction / speed summary
weather_report(Station, Condition, TempF, Humidity, Wind) :-
    station_id(Station),
    obs_condition(Condition),
    obs_temp_f(TempF),
    obs_humidity(Humidity),
    obs_wind(Wind).

%% weather_summary/3
%%   Lightweight summary with station, condition and temperature only.
weather_summary(Station, Condition, TempF) :-
    station_id(Station),
    obs_condition(Condition),
    obs_temp_f(TempF).

%% obs_pressure/1
%%   Convenience alias for the asserted obs_pressure_mb/1 fact.
obs_pressure(P) :- obs_pressure_mb(P).
