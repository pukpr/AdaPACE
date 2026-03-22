%% Example Terrain Area - Mojave Desert (Trona-East)
%% Trona-East 1:250000
%% Northwest corner 36.0000�N, -117.0000�W
%% Northeast corner 36.0000�N, -116.0000�W
%% Southwest corner 35.0000�N, -117.0000�W
%% Southeast corner 35.0000�N, -116.0000�W

zone (11).
hemisphere ("North").
southwest_easting (500000).
southwest_northing (3873000).

ctdb_data_file ("/geography/ctdb/data/ntc-0101.c7l").

map_name_dem ("/maps/dem/trona-e.filtered.dem").
map_name_dted ("/maps/dted/w116/n35.dt1").

utm_conversion (center, lat(35.5), long(-116.5), n(3928356), e(545447)).
utm_conversion (se, lat(35.0), long(-116.0), n(3873302), e(591255)).
utm_conversion (ne, lat(36.0), long(-116.0), n(3984210), e(590131)).
utm_conversion (nw, lat(36.0), long(-117.0), n(3984210), e(500000)).
utm_conversion (sw, lat(35.0), long(-117.0), n(3873302), e(500000)).
utm_raw (Point, Lat, Long, N, E) :- utm_conversion (Point, lat(Lat), long(Long), n(N), e(E)).

