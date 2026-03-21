with Ada.Numerics.Elementary_Functions;
with Ada.Numerics;
with Pace.Log;
with Nav.Location;
with Tsa.Terrain_Following;
with Acu;

package body Abk is

   use Ada.Numerics.Elementary_Functions;

   function Time_In_Air
              (Distance : in Float; Angle : in Float; Velocity : in Float)
              return Float is
   begin
      return Distance / (Cos (Angle) * Velocity);
   end Time_In_Air;

   function Total_Time_In_Air (Angle : in Float;
                               Velocity : in Float;
                               Vertical_Distance : in Float) return Float is
   begin
      Pace.Log.Put_Line
                      ("velocity is " & Float'Image (Velocity) &
                       " and angle is " & Float'Image (Angle) &
                       " and vert_dist is " & Float'Image (Vertical_Distance), 8);
      return ((Velocity * Sin (Angle) +
               Sqrt (Velocity * Velocity * Sin (Angle) * Sin (Angle) -
                     2.0 * Gravity * Vertical_Distance)) / Gravity);
   exception
      when E: Ada.Numerics.Argument_Error =>
         Pace.Log.Put_Line
           ("Argument Error thrown inside Total_Time_In_Air.  Sqrt of a negative number.  The angle of the drone is not high enough to hit the customer.");
         raise Bad_Elevation_Angle;
   end Total_Time_In_Air;

   function Distance_Traveled
              (Angle : in Float; Velocity : in Float; Time : in Float)
              return Float is
   begin
      return Cos (Angle) * Velocity * Time;
   end Distance_Traveled;

   function Initial_Velocity
              (Angle : in Float; Distance : in Float) return Float is
   begin
      return Sqrt ((Gravity * Distance) / Sin (2.0 * Angle));
   end Initial_Velocity;

   function Initial_Velocity (Angle : in Float;
                              Horizontal_Distance : in Float;
                              Vertical_Distance : in Float) return Float is
   begin
      Pace.Log.Put_Line ("inside init velocity... angle is " & Angle'Img & " and hor dist is " & Horizontal_Distance'Img & " and vert dist is " & Vertical_Distance'Img, 8);
      return (Sqrt (Gravity * Horizontal_Distance * Horizontal_Distance /
                    (2.0 * Cos (Angle) * Cos (Angle) *
                     (Horizontal_Distance * Tan (Angle) - Vertical_Distance))));
   exception
      when E: Ada.Numerics.Argument_Error =>
         Pace.Log.Put_Line
           ("Argument Error thrown inside Initial_Velocity.  Sqrt of a negative number.  The angle of the drone is not high enough to hit the customer.");
         raise Bad_Elevation_Angle;
   end Initial_Velocity;

   procedure Elevation_Calculation (Initial_Velocity : in Float;
                                    Horizontal_Distance : in Float;
                                    Vertical_Distance : in Float;
                                    Success : out Boolean;
                                    Elevation : out Float) is
   begin
      Elevation :=  (0.5 * Arcsin ((Gravity * Horizontal_Distance) /
                                   (Initial_Velocity * Initial_Velocity) +
                                   Vertical_Distance / Horizontal_Distance));
      Success := True;
   exception
      when E: Ada.Numerics.Argument_Error =>
         Success := False;
         Elevation := 0.0;
   end Elevation_Calculation;

   function Get_Horizontal_Distance
     (Target_Easting, Target_Northing : Float) return Float is
      Delta_A, Delta_B : Float;
      Msg : Nav.Location.Get_Data;
   begin
      Pace.Dispatching.Output (Msg);
      Pace.Log.Put_Line ("vehicle easting is " & Msg.Coordinate.Easting'Img & " and northing is " & Msg.Coordinate.Northing'Img, 8);
      Pace.Log.Put_Line ("customer easting is " & Target_Easting'Img & " and northing is " & Target_Northing'Img, 8);
      Delta_A := abs (Target_Northing - Msg.Coordinate.Northing);
      Delta_B := abs (Target_Easting - Msg.Coordinate.Easting);
      return (Sqrt (Delta_A * Delta_A + Delta_B * Delta_B));
   end Get_Horizontal_Distance;

   -- returns the difference between the customer's elevation and the vehicle's elevation
   function Get_Vertical_Distance
     (Target_Easting, Target_Northing : Float) return Float is
      Customer_Msg : Tsa.Terrain_Following.Get_Terrain_Elevation;
   begin
      Customer_Msg.Northing := Target_Northing;
      Customer_Msg.Easting := Target_Easting;
      Pace.Dispatching.Inout (Customer_Msg);
      Pace.Log.Put_Line ("customer elevation is " & Float'Image (Customer_Msg.Elevation), 8);
      Pace.Log.Put_Line ("vehicle elevation is " & Float'Image (Acu.Altitude), 8);
      return (Customer_Msg.Elevation - Acu.Altitude);
   end Get_Vertical_Distance;

end Abk;
