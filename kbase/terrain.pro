%% $id: terrain.pro,v 1.2 06/27/2003 13:10:27 ludwiglj Exp $


dted_default("/maps/dted/w116/n35.dt1",   % NTC
             535000.0, 3925000.0,         % SouthWest Corner: Easting,Northing
             92.6889259, 92.6889259).     % Span: East-West, North-South


%% XY-grid scale is per 100 meters
obstacle_point (5300, 39250, boulder).
obstacle_point (5450, 39251, road).
obstacle_point (5750, 39252, cropland).
obstacle_point (6050, 39253, pond).
obstacle_point (5950, 39255, "corn field").
obstacle_point (5450, 39257, shack).
obstacle_point (5250, 39260, canal).




