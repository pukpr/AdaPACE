
package Plant.Drone is

   pragma Elaborate_Body;

   ------------------------
   --- Drone Data
   ------------------------

   procedure Set_Drone_Elevation (Value : in Float); -- radians
   function Get_Drone_Elevation return Float; -- radians

   procedure Set_Drone_Azimuth (Value : in Float);  -- radians
   function Get_Drone_Azimuth return Float;  -- radians

   ------------------------
   --- Launchpad Velocity
   ------------------------

   -- is called each time a item is delivered.. Launchpad velocity and
   -- time item was delivered are set
   procedure Set_Launchpad_Velocity (Item : in Integer; Value : in Float);
   function Get_Launchpad_Velocity (Item : in Integer) return Float;

   function Get_Time_Item_Was_Delivered (Item : in Integer) return Duration;

   ------------------------
   --- Drone Temperature
   ------------------------

   function Get_Drone_Temperature return Float;

private
   pragma Inline (Get_Drone_Azimuth);

end Plant.Drone;
