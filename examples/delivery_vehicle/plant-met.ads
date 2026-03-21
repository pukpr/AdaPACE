package Plant.Met is
   --
   -- Various Meteorological Variables
   --
   pragma Elaborate_Body;

   procedure Set_Cloud_Cover (Value : in Float);
   function Get_Cloud_Cover return Float;
   --
   -- 0 to 100%

   procedure Set_Temperature (Value : in Float);
   function Get_Temperature return Float;
   --
   -- Celsius

   procedure Set_Visibility (Value : in Float);
   function Get_Visibility return Float;
   --
   -- 0 to 100%

   procedure Set_Wind_Speed (Value : in Float);
   function Get_Wind_Speed return Float;
   --
   -- KM/Hr

   procedure Set_Wind_Direction (Value : in Float);
   function Get_Wind_Direction return Float;
   --
   -- 0.0 = N, 90.0 = E, 180.0 = S, 270 = W
   --

   procedure Set_Terrain_Conditions (Value : in Integer);
   function Get_Terrain_Conditions return Integer;

   procedure Set_Current_Conditions (Value : in Integer);
   function Get_Current_Conditions return Integer;


   --
   -- Monitor weather conditions via web
   --
   --    procedure Weather_Conditions;

private
   pragma Inline (Get_Current_Conditions);

-- $id: plant-met.ads,v 1.4 04/16/2003 17:51:09 pukitepa Exp $
end Plant.Met;

