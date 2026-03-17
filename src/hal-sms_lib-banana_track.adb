with Hal.Sms_Lib.Belt;
with Pace.Log;
package body Hal.Sms_Lib.Banana_Track is

   Slot_Pick : constant Integer := Pace.Getenv ("HAL_BANANA_PICK", 0);
   Num_Intervals : constant Integer := 6;
   procedure Carrier_Callback (Track_Spot : Integer) is
   begin
      null;
   end Carrier_Callback;
   package Track is
     new Hal.Sms_Lib.Belt (Prefix => "carrier_mover",
                           Initial_Six_Dof => (
                                               (Pos => (0.5272, 0.0,    0.0047), Ori => (0.0, rads(359.573),0.0)),
                                               (Pos => (0.492,  0.0,    0.185),  Ori => (0.0, rads(338.53),     0.0)),
                                               (Pos => (0.3944, 0.0,    0.3406), Ori => (0.0, rads(317.486),0.0)),
                                               (Pos => (0.2474, 0.0,    0.4507),        Ori => (0.0, rads(296.443),0.0)),
                                               (Pos => (0.0707, 0.0,  0.5007), Ori => (0.0, rads(275.399),0.0)),
                                               (Pos => (-0.1122,        0.0,    0.484),  Ori => (0.0, rads(254.355),0.0)),
                                               (Pos => (-0.2774,        0.0,    0.4023), Ori => (0.0, rads(235.32),     0.0)),
                                               (Pos => (-0.4691,        0.0,    0.3799), Ori => (0.0, rads(332.934),0.0)),
                                               (Pos => (-0.449, 0.0,    0.5649), Ori => (0.0, rads(57.575), 0.0)),
                                               (Pos => (-0.2822,        0.0,    0.6518), Ori => (0.0, rads(73.04),  0.0)),
                                               (Pos => (-0.0948,        0.0,    0.7072), Ori => (0.0, rads(88.5059),0.0)),
                                               (Pos => (0.0993, 0.0,    0.7147),        Ori => (0.0, rads(103.971),0.0)),
                                               (Pos => (0.2863, 0.0,    0.6624), Ori => (0.0, rads(119.437),0.0)),
                                               (Pos => (0.4526, 0.0,    0.562),  Ori => (0.0, rads(134.902),0.0)),
                                               (Pos => (0.5861, 0.0,    0.421), Ori => (0.0, rads(150.368),0.0)),
                                               (Pos => (0.6771, 0.0,  0.2495), Ori => (0.0, rads(165.833),0.0)),
                                               (Pos => (0.7191, 0.0,    0.0599), Ori => (0.0, rads(181.299),0.0)),
                                               (Pos => (0.6495, 0.0,    -0.1234),Ori => (0.0, rads(276.318),0.0))
                                               ),
                           Intervals => Num_Intervals,
                           Time_Delta => 0.645,
                           Track_Callback => Carrier_Callback,
                           Slot_Pick => Slot_Pick,
                           Distance_Between_Slots => 0.1);  --ADDED to complete compile


   procedure Step (Rotate : in Rotation_Direction; Number : in Integer := 1) is
   begin
      if Rotate = Cw then
         Track.Step (Track.Increasing, Number);
      else
         Track.Step (Track.Decreasing, Number);
      end if;
   end Step;

   function Get_Current_Slot return Integer is
      Success : Boolean;
      Major : Integer;
   begin
      Track.Minor_To_Major (Track.Get_Current_Minor_Slot, Success, Major);
      if not Success then
         Pace.Log.Put_Line ("FAILED TO GET CURRENT MINOR SLOT!");
      end if;
      return Major;
   end Get_Current_Slot;

   procedure Initialize_Slots renames Track.Initialize_Slots;

   procedure Increment_Slot (Rotate : in Rotation_Direction) is
   begin
      Step (Rotate, Num_Intervals);
   end Increment_Slot;

end Hal.Sms_Lib.Banana_Track;

