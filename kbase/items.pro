
% mapping boxes to number of charges to launchpad velocities

box_bottle_velocity ("ABCD", 4, 711).
box_bottle_velocity ("ABCD", _, 544).

% the default matches M107
box_bottle_velocity (_, Charges, Velocity) :- box_bottle_velocity ("ABCD", Charges, Velocity).


