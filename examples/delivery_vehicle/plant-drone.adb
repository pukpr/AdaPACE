with Ada.Numerics.Elementary_Functions;
with Pace.Log;
with Pace;
with Plant.Met;

package body Plant.Drone is

   function Id is new Pace.Log.Unit_Id;

   type Delivered_Data is
      record
         Launchpad_Velocity : Float;
         Time_Item_Was_Delivered : Duration;
      end record;

   Drone_Elevation : Float := 0.0;
   Drone_Azimuth : Float := 0.0;
   Current_Drone_Temperature : Float := 50.0;  -- celsius
   

   
   -- the launchpad velocity of each item shot during a delivery job
   -- and the time that each shot was delivered at is kept until the next
   -- delivery job
   Delivered_Items : array (1 .. 60) of Delivered_Data;

   Time_Last_Delivered : Float;
   -- the drone temperature increases with each shot geometrically
   Geometric_Rate : constant Float := 0.5;

   -- resets Delivered_Items to avoid confusion when multiple delivery jobs
   -- are taking place
   procedure Init_Delivered_Data is
   begin
      for I in Delivered_Items'Range loop
         Delivered_Items (I).Launchpad_Velocity := 0.0;
         Delivered_Items (I).Time_Item_Was_Delivered := 0.0;
      end loop;
   end Init_Delivered_Data;

   procedure Set_Launchpad_Velocity (Item : in Integer; Value : in Float) is
   begin
      if Item = 1 then
         Init_Delivered_Data;
      end if;
      Delivered_Items (Item).Launchpad_Velocity := Value;
      Delivered_Items (Item).Time_Item_Was_Delivered := Pace.Now;

      Time_Last_Delivered := Float (Pace.Now);
      -- Up this value geometrically
      Current_Drone_Temperature :=
        Current_Drone_Temperature +
          (Plant.Max_Drone_Temperature - Current_Drone_Temperature) *
            Geometric_Rate;
   exception
      when others =>
         Pace.Log.Put_Line ("Error setting Launchpad_Velocity in Plant");
   end Set_Launchpad_Velocity;

   function Get_Launchpad_Velocity (Item : in Integer) return Float is
   begin
      if Item = 0 then
         return 0.0;
      else
         return Delivered_Items (Item).Launchpad_Velocity;
      end if;
   exception
      when others =>
         Pace.Log.Put_Line ("Error getting Launchpad_Velocity in Plant");
         return 0.0;
   end Get_Launchpad_Velocity;

   function Get_Time_Item_Was_Delivered (Item : in Integer) return Duration is
   begin
      if Item = 0 then
         return 0.0;
      else
         return Delivered_Items (Item).Time_Item_Was_Delivered;
      end if;
   exception
      when others =>
         Pace.Log.Put_Line ("Error getting Time_Item_Was_Delivered in Plant");
         return 0.0;
   end Get_Time_Item_Was_Delivered;


   -- K is the decay constant... this number reflects an exponential decay
   -- at a rate of 74% cooled after 1 hour (3600 seconds)
   K : constant Float := -1.0 / 3600.0;
   function Get_Drone_Temperature return Float is
      use Ada.Numerics.Elementary_Functions;
   begin
      Pace.Log.Agent_Id (Id);
      -- the drone temperature should not go below the current temperature
      -- outside, so figure in Plant.Met.Get_Temperature like so...
      Current_Drone_Temperature :=
        (Current_Drone_Temperature - Plant.Met.Get_Temperature) *
          Exp (K * (Float (Pace.Now) - Time_Last_Delivered)) +
        Plant.Met.Get_Temperature;
      return Current_Drone_Temperature;
   end Get_Drone_Temperature;

   procedure Set_Drone_Elevation (Value : in Float) is
   begin
      Drone_Elevation := Value;
   end Set_Drone_Elevation;

   function Get_Drone_Elevation return Float is
   begin
      return Drone_Elevation;
   end Get_Drone_Elevation;

   procedure Set_Drone_Azimuth (Value : in Float) is
   begin
      Drone_Azimuth := Value;
   end Set_Drone_Azimuth;

   function Get_Drone_Azimuth return Float is
   begin
      return Drone_Azimuth;
   end Get_Drone_Azimuth;

end Plant.Drone;

