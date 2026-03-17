with Pace;
with Pace.Log;
with Pace.Server.Peek_Factory;
with Ual.Utilities;

separate (Mob.Vehicle)
package body Engine is

   function Id is new Pace.Log.Unit_Id;
   function Name return String renames Pace.Log.Name;

   task Agent is pragma Task_Name (Name);
      entry Engine_Start;
   end Agent;

   Engine_Stopped : Boolean := True;
--   function Peek_Engine_Stopped return String is
--   begin
--      return Engine_Stopped'Img;
--   end Peek_Engine_Stopped;
--   package Engine_Stopped_Img is
--     new Pace.Server.Peek_Factory (Peek_Engine_Stopped);

   Is_Engine_Running : Boolean := False;
   Coolant_Temperature : Float := 0.1; -- percentage of max
   Coolant_Level : Float := 1.0; -- percentage of max
   Oil_Temperature : Float := 0.1; -- percentage of max
   Oil_Level : Float := 1.0; -- percentage of max
   Fresh_Drinking_Water : Float := 0.0;  -- percentage of max

   function Get_Fresh_Drinking_Water return Float is
      Temp : Float := Fresh_Drinking_Water;
   begin
      Fresh_Drinking_Water := 0.0;
      return Temp;
   end Get_Fresh_Drinking_Water;

   task body Agent is

      function Consume return Boolean is

         -- Idle           24.36 liters/hr @ 800 RPM
         -- Tach.Idle      98.46 liters/hr @ 1800 RPM
         -- Cross-Country  180.31 liters/hr
         -- Secondary Rds  162.60 liters/hr

         Fuel_Consumed : Float := Rpms / 10_000_000.0;
      begin
         Fuel_Cells (Current_Fuel_Cell).Fuel_Level := Fuel_Cells (Current_Fuel_Cell).Fuel_Level - Fuel_Consumed;

         -- as fuel is consumed, water is generated at a certain rate
         declare
            -- represents amount of water generated as a percentage of
            -- the max_water_level
            Water_Generated : Float :=
              Fuel_Consumed * Fuel.Max_Fuel_Cell_Capacity *
              Eng.Water_Generation_Rate / Eng.Max_Water_Level;
         begin
            Fresh_Drinking_Water := Fresh_Drinking_Water + Water_Generated;
         end;

         if Fuel_Cells (Current_Fuel_Cell).Fuel_Level < 0.0 then
            Fuel_Cells (Current_Fuel_Cell).Fuel_Level := 0.0;
         end if;
         return not (Current_Fuel_Cell = 3 and Ual.Utilities.Float_Equals (Fuel_Cells (Current_Fuel_Cell).Fuel_Level, 0.0, 0.000001));
      end Consume;


      -- increases coolant and oil temps linearly with amount of time engine
      -- has been running to a certain plateau.  The plateaus do not
      -- represent the maximum temps, but they are the normal operating temps.
      procedure Heat_Fluids is
      begin
         if Coolant_Temperature < Eng.Coolant_Plateau_Temp then
            Coolant_Temperature := Eng.Change_In_Temp_Per_Second +
              Coolant_Temperature;
         end if;
         if Oil_Temperature < Eng.Oil_Plateau_Temp then
            Oil_Temperature := Eng.Change_In_Temp_Per_Second + Oil_Temperature;
         end if;
      end Heat_Fluids;

      Fuel_Remaining : Boolean := True;
   begin
      Pace.Log.Agent_Id (Id);
   Main_Agent:
      loop
         accept Engine_Start do
            Engine_Stopped := False;
         end Engine_Start;
         Is_Engine_Running := True;
         Rpms := 800.0;
      Inner:
         loop
            Pace.Log.Wait (1.0);
            Fuel_Remaining := Consume;
            if not Fuel_Remaining then
               Pace.Log.Put_Line ("ran out of fuel!!!!!!!!!! stopping engine");
               Engine_Stopped := True;
            end if;
            Heat_Fluids;
            if Engine_Stopped then
               Is_Engine_Running := False;
               declare
                  Msg : Stop_Engine;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
               exit Inner;
            end if;
         end loop Inner;
      end loop Main_Agent;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   task Cooling_Agent;

   task body Cooling_Agent is

      -- the fluids cool when the vehicle is no longer running to the
      -- normal non-operating temperatures
      procedure Cool_Fluids is
      begin
         if Coolant_Temperature > Eng.Coolant_Non_Operating_Temp then
            Coolant_Temperature := Coolant_Temperature - Eng.Change_In_Temp_Per_Second * 5.0;
         end if;
         if Oil_Temperature > Eng.Oil_Non_Operating_Temp then
            Oil_Temperature := Oil_Temperature - Eng.Change_In_Temp_Per_Second * 5.0;
         end if;
      end Cool_Fluids;

   begin
      Pace.Log.Agent_Id (Id & "cooling");
      loop
         if not Is_Engine_Running then
            Cool_Fluids;
         end if;
         Pace.Log.Wait (5.0);
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Cooling_Agent;

   procedure Engine_Start is
   begin
      select
         Agent.Engine_Start;
      else
         Pace.Log.Put_Line ("Engine already started!");
      end select;
   end Engine_Start;

   procedure Engine_Stop is
   begin
      Engine_Stopped := True;
   end Engine_Stop;

   procedure Engine_Status (Engine_Coolant_Level : out Float;
                            Engine_Coolant_Temperature : out Float;
                            Engine_Rpm : out Float;
                            Engine_Oil_Level : out Float;
                            Engine_Oil_Temperature : out Float;
                            Engine_Running : out Boolean) is
   begin
      Engine_Coolant_Level := Coolant_Level;
      Engine_Coolant_Temperature := Coolant_Temperature;
      Engine_Rpm := Rpms;
      Engine_Oil_Level := Oil_Level;
      Engine_Oil_Temperature := Oil_Temperature;
      Engine_Running := Is_Engine_Running;
   end Engine_Status;

   procedure Stop_Engine_Fans is
   begin
      Pace.Log.Put_Line ("PULSING ENGINE FANS DOWN, WAIT 5 SEC");
      Pace.Log.Wait (5.0);
   end Stop_Engine_Fans;

   procedure Set_Fuel_Level (Cell : Integer; Level : Float) is
   begin
      Fuel_Cells (Cell).Fuel_Level := Level;
   end Set_Fuel_Level;

end Engine;
