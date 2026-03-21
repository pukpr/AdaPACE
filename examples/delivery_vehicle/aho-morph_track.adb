with Hal;
with Hal.Sms;
with hal.bounded_Assembly;
with Hal.Morph_Track;
with Hal.Sms_Lib.Morph;
with Pace.Log;
with Plant;

package body Aho.Morph_Track is

   function Id is new Pace.Log.Unit_Id;

   task Agent is
      entry Input (Obj : Do_Morph);
   end Agent;

   use hal.bounded_Assembly;

   -- Pin_Positions never changes.. should find a better way .. shouldn't have
   -- to send this across socket each time.. but keeping it on plugin side
   -- loses generality.. solution?
   Pin_Positions : Hal.Sms_Lib.Morph.Pin_Pos_Array :=
     ((0.0, -0.1152, 0.0414), (0.0, 0.0380, 0.0), (0.0, 0.0380, -0.0001),
      (0.0, 0.0381, 0.0001), (0.0, 0.0379, -0.0001), (0.0, 0.0380, 0.0001),
      (0.0, 0.0381, -0.0001), (0.0, 0.0380, 0.0), (0.0, 0.0379, 0.0));

   package Morphing_Track is
     new Hal.Morph_Track (Num_Pins => 10,
                          Intervals_Per_Degree => 1,
                          Lowest_Angle => 0.0,
                          Highest_Angle => 73.0,
                          Assembly_Prefix => To_Bounded_String ("pin"),
                          Time_Between_One_Degree =>
                            Duration (1.0 / Plant.Drone_Elevation_Rate),
                          Pin_Positions => Pin_Positions);

   task body Agent is
      use Morphing_Track;

   begin
      Pace.Log.Agent_Id (Id);

      loop
         declare
            Starting_Angle, Ending_Angle : Float;
         begin
            accept Input (Obj : Do_Morph) do
               Starting_Angle := Obj.Starting_Angle;
               Ending_Angle := Obj.Ending_Angle;
               Pace.Log.Trace (Obj);
            end Input;
            Morphing_Track.Do_Morph (Starting_Angle, Ending_Angle);
         end;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Do_Morph) is
   begin
      Agent.Input (Obj);
      Pace.Log.Trace (Obj);
   end Input;

end Aho.Morph_Track;
