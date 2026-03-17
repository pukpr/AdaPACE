with Pace;
with Pace.Log;
with Hal.Audio.Mixer;
with Gkb.Database;

package body Gis.Obstacle_Reporter is

   function Id is new Pace.Log.Unit_Id;

   package Db is new Kb.Database;

   Monitor_Location_Time : constant Duration := 5.0;

   -- this is the amount to divide the Easting and Northing values by
   -- which are represented in meters, therefore a value of 1000 gives
   -- the grid a scale of kilometers.
   Grid_Scale : constant Integer := 100; -- per 100 meters

   type Xy_Coordinate is
      record
         X : Integer;
         Y : Integer;
      end record;

   task Obstacle_Agent;

   task body Obstacle_Agent is
      Current_Location : Xy_Coordinate;

      -- returns true if Current_Location has changed
      function Update_Current_Location return Boolean is
         Result : Boolean := False;
         Msg : Loc.Get_Data;
      begin
         Pace.Dispatching.Output (Msg);
         if Integer (Msg.Coordinate.Easting) / Grid_Scale /= Current_Location.X then
            Current_Location.X := Integer (Msg.Coordinate.Easting) / Grid_Scale;
            Result := True;
         end if;
         if Integer (Msg.Coordinate.Northing) / Grid_Scale /= Current_Location.Y then
            Current_Location.Y := Integer (Msg.Coordinate.Northing) / Grid_Scale;
            Result := True;
         end if;
         return Result;
      end Update_Current_Location;

      procedure Find_And_Report_Obstacles is
      begin
         declare
            Result : String := Db.Get
                                 ("obstacle_point", Integer'Image
                                                      (Current_Location.X),
                                  Integer'Image (Current_Location.Y));
         begin
            Hal.Audio.Mixer.Say ("Approaching obstacle " & Result);
         end;
      exception
         when Event: Kb.Rules.No_Match =>
            -- then do nothing!
            null;
      end Find_And_Report_Obstacles;

   begin
      Pace.Log.Agent_Id (Id);
      loop -- forever
         Pace.Log.Wait (Monitor_Location_Time);
         -- true when current location has changed
         if Update_Current_Location then
            Find_And_Report_Obstacles;
         end if;
      end loop;
   exception
      when Event: others =>
         Pace.Log.Ex (Event);
   end Obstacle_Agent;

end Gis.Obstacle_Reporter;
