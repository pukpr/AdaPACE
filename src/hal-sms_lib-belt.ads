generic
   -- it is assumed that the geographical position of interest (referred to by
   -- get_current_slot) corresponds to the geographical position that the first
   -- index in the Slots array is initialized to.
   Prefix : in String;
   Initial_Six_Dof : in Hal.Six_Dof_Arr;
   Distance_Between_Slots : Float;
   Intervals : in Integer;  -- num minor slots between major slots
   -- amount of time to move between slots.
   -- defines the velocity!
   Time_Delta : in Duration;
   -- this procedure will be called when the belt is in motion and provides as input the track spot
   -- that is currently at the geographical position of interest
   with procedure Track_Callback (Track_Spot : Integer) is <>;
   Slot_Pick : in Integer := 0; -- Step all slots if 0, particular if /= 0
   Entity : String := "";
package Hal.Sms_Lib.Belt is

   -- slot direction
   type Belt_Direction is (Increasing, Decreasing);

   -- move in direction Number of minor slots
   procedure Step (Direction : Belt_Direction; Number : in Integer := 1);

   -- the current minor slot corresponding to the geographical position of interest
   function Get_Current_Minor_Slot return Integer;
   function Get_Current_Major_Slot return Float;
   function Get_Current_Absolute return Float; -- meters

   procedure Initialize_Slots;

   -- a major slot is composed of Intervals of minor slots
   procedure Select_Major_Slot (Major_Slot : in Integer);

   -- a decimal major_slot
   procedure Select_Major_Slot_Absolute (Major_Slot : in Float);
   -- a decimal relative major_slot
   procedure Select_Major_Slot_Relative (Relative : in Float);

   procedure Select_Minor_Slot (Minor_Slot : in Integer);

   -- units are meters
   procedure Select_Absolute_Meters (Absolute : in Float);
   -- units are meters
   procedure Select_Relative_Meters (Relative : in Float);

   -- return the minor slot corresponding to major_slot
   function Major_To_Minor (Major_Slot : Float) return Integer;

   -- success is true if minor_slot matches a major_slot otherwise false
   procedure Minor_To_Major (Minor_Slot : Integer; Success : out Boolean; Major_Slot : out Integer);

   -- given a destination major slot, returns the shortest direction to go and how many slots
   -- away the destination is
   procedure Shortest_Route (Dest_Minor_Slot : in Integer;
                             Direction : out Belt_Direction;
                             Minor_Slot_Distance : out Integer);

   procedure Set_Major_Slot (Major_Slot : in Float);

end Hal.Sms_Lib.Belt;
