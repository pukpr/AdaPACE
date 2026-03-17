with Ada.Exceptions;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Strings.Fixed;
with Ada.Strings;
with Ada.Strings.Bounded;
with Pace.Log;
with Hal;

package body Hal.Racetrack_Pin is

   -- the current location
   Available_Slot : Integer := Initial_Available_Slot;

   -- ends of magazine will follow circular path
   Radius : Float := Track_Width / 2.0;

   -- the length of the track with the two half circles at each end
   Straightaway_Length : Float :=
     ((Float (Num_Slots) - 2.0) / 2.0 - 1.0) * Slot_Distance;

   -- The lookup table.  Values are locations where a slot may
   -- be during movement and indexes represent a track spot..
   -- ex. if Available_Slot is slot 1 then slot 1 is at
   -- track spot 1 and slot 2 is at track spot Num_Interval
   -- and slot 3 is at track spot Num_Interval*2
   Track : array (1 .. Num_Slots * Num_Intervals)
             of Hal.Sms_Lib.Racetrack.Slot_Position;

   -- represents where each slot is on the Track.  So indexes
   -- are which slot and values are a Track Spot (corresponding
   -- to indexes of Track above)
   Slots_On_Track : array (1 .. Num_Slots) of Integer;

   Select_Aborted : Boolean := False;

   procedure Abort_Selection is
   begin
      Select_Aborted := True;
   end Abort_Selection;

   function Find_Shortest_Direction (Slot_Num : Integer) return Direction is
      Ccw_Distance : Integer;
      Cw_Distance : Integer;
   begin
      if Slot_Num > Available_Slot then
         Ccw_Distance := Slot_Num - Available_Slot;
         Cw_Distance := Num_Slots - Ccw_Distance;
      else
         Cw_Distance := Available_Slot - Slot_Num;
         Ccw_Distance := Num_Slots - Cw_Distance;
      end if;
      if Cw_Distance < Ccw_Distance then
         return Direction'(Cw);
      else
         return Direction'(Ccw);
      end if;
   end Find_Shortest_Direction;

   -- increments or decrements (depending on direction)
   -- the location of each slot by 1
   function Move_Slots_On_Track (Which_Way : Direction)
                                return Hal.Sms_Lib.Racetrack.Slots_Array is
      Result : Hal.Sms_Lib.Racetrack.Slots_Array (1 .. Num_Slots);
   begin
      if Which_Way = Ccw then
         for I in 1 .. Num_Slots loop
            if Slots_On_Track (I) = Num_Intervals * Num_Slots then
               Slots_On_Track (I) := 1;
            else
               Slots_On_Track (I) := Slots_On_Track (I) + 1;
            end if;
            Result (I) := Track (Slots_On_Track (I));
         end loop;
      else -- Direction = CW
         for I in 1 .. Num_Slots loop
            if Slots_On_Track (I) = 1 then
               Slots_On_Track (I) := Num_Intervals * Num_Slots;
            else
               Slots_On_Track (I) := (Slots_On_Track (I) - 1);
            end if;
            Result (I) := Track (Slots_On_Track (I));
         end loop;
      end if;
      return Result;
   end Move_Slots_On_Track;

   -- returns a Slots_Array corresponding to the current location
   function Create_Slots return Hal.Sms_Lib.Racetrack.Slots_Array is
      Result : Hal.Sms_Lib.Racetrack.Slots_Array (1 .. Num_Slots);
   begin
      for I in 1 .. Num_Slots loop
         Result (I) := Track (Slots_On_Track (I));
      end loop;
      return Result;
   end Create_Slots;

   -- used for debugging purposes only
   procedure Print_Slots is
      use Ada.Strings;
      Slots : Hal.Sms_Lib.Racetrack.Slots_Array := Create_Slots;
   begin
      for I in Slots'Range loop
         Pace.Log.Put_Line (To_String (Assembly_Prefix) &
                            Ada.Strings.Fixed.Trim (Integer'Image (I), Left) &
                            ":: X -> " & Float'Image (Slots (I).X) &
                            " : Z -> " & Float'Image (Slots (I).Z) &
                            " : Phi -> " & Float'Image (Slots (I).Phi));
      end loop;
   end Print_Slots;

   -- used for debugging purposes only
   procedure Print_Track is
   begin
      for I in Track'Range loop
         Pace.Log.Put_Line (Integer'Image (I) & " :: X -> " &
                            Float'Image (Track (I).X) & " : Z -> " &
                            Float'Image (Track (I).Z) & " : Phi -> " &
                            Float'Image (Track (I).Phi));
      end loop;
   end Print_Track;

   -- assign initial slots there places on the Track
   -- assumes slot 1 should begin at the available slot
   procedure Initial_Slot_Placement is
   begin

      for I in 1 .. Num_Slots loop
         Slots_On_Track (I) := Num_Intervals * (I - 1) + 1;
      end loop;

   end Initial_Slot_Placement;


   -- defines the Track array, which holds the lookup table for how
   -- the slots move around the track.  Sin and Cosine are used to
   -- simulate the path of a circle.
   procedure Configure_Track is
      use Hal.Sms_Lib.Racetrack;
      use Ada.Numerics;
      use Ada.Numerics.Elementary_Functions;
      Current_Z : Float;
      Current_Phi : Float;
      Arc_Length : Float;
      Half_Circle_Arc_Length : Float := Radius * Pi;
      Delta_Arc : Float := Half_Circle_Arc_Length / 2.0 / Float (Num_Intervals);
      I : Integer := 1;
      Alpha : Float;
      Current_X : Float;
   begin

      Pace.Log.Put_Line ("straightaway length is " & Float'Image (Straightaway_Length), 8);

      -- the long z-axis where X is the width of the track
      -- Z decreases from 0
      Current_Z := 0.0;
      Current_Phi := Pi / 2.0;
      Current_X := Track_Width;
      while Current_Z > -1.0 * Straightaway_Length loop
         Track (I) := Slot_Position'
                        (Phi => Current_Phi, X => Current_X, Z => Current_Z);
         Current_Z := Current_Z - Slot_Distance / Float (Num_Intervals);
         I := I + 1;
      end loop;
      -- reset to Straightaway_Length
      Arc_Length := 0.0;
      Current_Z := -1.0 * Straightaway_Length;

      -- 1/2 circle ranging in Phi from Pi/2 to 3*Pi/2
      -- Arc_Length ranges from its starting point above to
      -- Half_Circle_Arc_Length
      while Arc_Length < Half_Circle_Arc_Length loop
         Current_Phi := Arc_Length / Radius + Pi / 2.0;
         Pace.Log.Put_Line ("---------------", 8);
         Pace.Log.Put_Line ("Current_Phi is " & Float'Image (Hal.Degs (Current_Phi)), 8);
         Pace.Log.Put_Line ("Arc_Length is " & Float'Image (Arc_Length), 8);
         Track (I) :=
           Slot_Position'
             (Phi => Current_Phi,
              X => Track_Width -
                     Track_Width * (1.0 - Cos (Current_Phi - Pi / 2.0)) / 2.0,
              Z => Current_Z - Radius * Sin (Current_Phi - Pi / 2.0));
         Arc_Length := Arc_Length + Delta_Arc;
         I := I + 1;
      end loop;

      Current_Z := -1.0 * Straightaway_Length;
      Current_Phi := -1.0 * Pi / 2.0;
      Current_X := 0.0;

      -- the long z-axis where X is 0 and Z increases to 0
      while Current_Z < 0.0 loop
         Track (I) := Slot_Position'
                        (Phi => Current_Phi, X => Current_X, Z => Current_Z);
         Current_Z := Current_Z + Slot_Distance / Float (Num_Intervals);
         I := I + 1;
      end loop;

      Arc_Length := 0.0;
      Current_Z := 0.0;

      -- 1/2 circle ranging in Phi from -Pi / 2 to Pi / 2
      while I <= Track'Length loop
         Current_Phi := Arc_Length / Radius - Pi / 2.0;
         Alpha := (Current_Phi + Pi / 2.0) / 2.0;
         Pace.Log.Put_Line ("---------------", 8);
         Pace.Log.Put_Line ("Current_Phi is " & Float'Image (Hal.Degs (Current_Phi)), 8);
         Pace.Log.Put_Line ("Arc_Length is " & Float'Image (Arc_Length), 8);
         Pace.Log.Put_Line ("Alpha is " & Float'Image (Hal.Degs (Alpha)), 8);
         Track (I) := Slot_Position'
                        (Phi => Current_Phi,
                         X => Track_Width *
                                (1.0 - Cos (Current_Phi + Pi / 2.0)) / 2.0,
                         Z => -1.0 * Radius * Cos (Current_Phi + Pi));
         Arc_Length := Arc_Length + Delta_Arc;
         I := I + 1;
      end loop;

      Initial_Slot_Placement;

      pragma Debug (Print_Track);

   end Configure_Track;


   -- moves the slots over 1 in Num_Intervals different intervals in
   -- the direction specified by Which_Way
   procedure Inc_Slot (Which_Way : Direction) is
   begin
      for I in 1 .. Num_Intervals loop
         Hal.Sms_Lib.Racetrack.Set (Prefix => Assembly_Prefix,
                                Slots => Move_Slots_On_Track (Which_Way));
         Pace.Log.Wait (Slot_To_Slot_Time / Num_Intervals);
      end loop;
      -- increment or decrement Available_Slot
      if Which_Way = Ccw then
         if Available_Slot = Num_Slots then
            Available_Slot := 1;
         else
            Available_Slot := Available_Slot + 1;
         end if;
      else -- direction is CW
         if Available_Slot = 1 then
            Available_Slot := Num_Slots;
         else
            Available_Slot := Available_Slot - 1;
         end if;
      end if;
   end Inc_Slot;

   -- moves the slots such that Slot_Num becomes the Available_Slot
   function Select_Slot (Slot_Num : Integer) return Integer is
      Which_Way : Direction;
      use Ada.Exceptions;
      -- this is raised in the event that a Slot is
      -- asked for that is out of range.
      Slot_Out_Of_Bounds_Error : exception;
   begin
      if Slot_Num > Num_Slots or Slot_Num <= 0 then
         Raise_Exception (Slot_Out_Of_Bounds_Error'Identity,
                          "Slot" & Integer'Image (Slot_Num) &
                            " is not in the range: 1 .." &
                            Integer'Image (Num_Slots));
      else
         Which_Way := Find_Shortest_Direction (Slot_Num);
         while Available_Slot /= Slot_Num loop
            exit when Select_Aborted = True;
            Inc_Slot (Which_Way);
            Pace.Log.Put_Line ("Available Slot is " &
                               Integer'Image (Available_Slot));
         end loop;
         Select_Aborted := False;
      end if;
      return Available_Slot;
   end Select_Slot;

end Hal.Racetrack_Pin;
