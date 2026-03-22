with Pace.Log;
with Pace.Socket; -- To get remote operation
with Nav.Location;
with Hal.Geotrans;
with Gis;

package body ANS.Monitor is

   -- Access to parent package
   procedure Start_Ans is
      Msg : Start_Msg;
   begin

      declare
         Loc_Msg : Nav.Location.Get_Data;
         Long, Lat, Alt : Long_Float;
      begin
         Pace.Dispatching.Output (Loc_Msg);
         Hal.Geotrans.Utm_To_Geo (Long_Float (Loc_Msg.Coordinate.Easting),
                                  Long_Float (Loc_Msg.Coordinate.Northing),
                                  Loc_Msg.Coordinate.Zone_Num,
                                  Gis.Hemi_Code (Loc_Msg.Coordinate.Hemisphere),
                                  Long,
                                  Lat,
                                  Alt);
         Msg.Longitude := Hal.Degs (Float (Long));
         Msg.Latitude := Hal.Degs (Float (Lat));
         Msg.Altitude := Float (Alt);
         Msg.Heading := Hal.Degs (Loc_Msg.Heading);
      end;
      Pace.Socket.Send (Msg);
   end;

   procedure Update (DeltaX, DeltaY, DeltaH : Float) is
      Msg : Update_Msg;
   begin
      Msg.DX := DeltaX;
      Msg.DY := DeltaY;
      Msg.DH := DeltaH;
      Pace.Socket.Send (Msg);
   end;

   procedure Position (Easting, Northing, Heading : out Float) is
      Msg : Position_Msg;
   begin
      Pace.Socket.Send_Out (Msg);
      Easting := Msg.Easting;
      Northing := Msg.Northing;
      Heading := Msg.Heading;
   end;
   ------------------------------

   Relative_Change_Since_Last_Update : constant Boolean := True;

   task Agent is
      entry Start;
   end;

   function ID is new Pace.Log.Unit_ID;

   procedure Read_From_Own_Vehicle_Ground_Truth (X, Y, H : out Float) is
      Msg : Nav.Location.Get_Data;
   begin
      Pace.Dispatching.Output (Msg);
      X := Msg.Coordinate.Easting;
      Y := Msg.Coordinate.Northing;
      H := Msg.Heading;
   end;

   Debug_Toggle : Boolean := False;

   -- where ans says we are at
   Easting, Northing, Heading : Float;

   task body Agent is
      X, Y, H : Float;
      Old_X, Old_Y, Old_H : Float;
      Delta_X, Delta_Y, Delta_H : Float := 0.0;
   begin
      Pace.Log.Agent_ID (ID);
      accept Start;
      Start_Ans;
      Read_From_Own_Vehicle_Ground_Truth (Old_X, Old_Y, Old_H);
      loop
         -- Simulation Artifice here. Must update the ANS with
         -- actual value to reflect own vehicle's data
         Read_From_Own_Vehicle_Ground_Truth (X, Y, H);

         Delta_X := X - Old_X;
         Delta_Y := Y - Old_Y;
         Delta_H := H - Old_H;

         if Relative_Change_Since_Last_Update then
            Old_X := X;
            Old_Y := Y;
            Old_H := H;
         else
            null; -- Assume change from initial measure
         end if;

         Update (Delta_X, Delta_Y, Delta_H);

         -- Actual needed call here
         Position (Easting, Northing, Heading);
         if Debug_Toggle then
            Pace.Log.Put_Line ("ANS:" & Float'Image(Easting) &
                                        Float'Image(Northing) &
                                        Float'Image(Heading));

         end if;

         Pace.Log.Wait (4.0);
      end loop;
   exception
      when E : others =>
         Pace.Log.Ex (E);
   end;

   procedure Start is
   begin
      Agent.Start;
   end;

   procedure Debug is
   begin
      Debug_Toggle := True;
   end;

end;
