The program "tlc" is an embedded real-time Traffic Light Controller example.

Basically the example is set up to illustrate traffic flow at an intersection
between a heavily travelled highway and a less frequently trafficed street.
The highway signal stays GREEN until a vehicle is sensed at the street
crosswalk. Then a timer is triggered to allow the traffic signal to 
change for a programmed amount of time.

Three sets of state and condition variables exist to control
the traffic light. These are set in the "symvar.pro" file.

tlc.sense_car  : (true, false)
tlc.short      : integer ticks transition to street GREEN
tlc.medium     : integer ticks street to YELLOW
tlc.long       : integer ticks street stays GREEN (to prevent excess street triggers)
tlc.highway    : (red, yellow, green)
tlc.street     : (red, yellow, green)

The last two are current states of the two traffic lights


During operation can Peek and Poke at values of sense_car

Peek:

*tlc__sense_car BOOL


Poke:

*tlc__sense_car BOOL:TRUE


