


with Pace.Log;
with Pace;

separate (Mob.Vehicle)
package body Fuel_Sensors is

   function Id is new Pace.Log.Unit_Id;
   function Name return String renames Pace.Log.Name;

   task Agent is pragma Task_Name (Name);
      entry Initialize;
   end Agent;

   Initialized : Boolean := False;

   task body Agent is
      procedure Monitor_Fuel is

         procedure Switch_Tanks is
            Switched : Boolean;
         begin
            Switched := False;

            for I in 1 .. Fuel.Num_Cells loop
               if Fuel_Cells (I).Fuel_Level > 0.0 then
                  Current_Fuel_Cell := I;
                  Switched := True;
                  Pace.Log.Put_Line ("Switching to cell " & Integer'Image (I));
                  exit;
               end if;
            end loop;
            if not Switched then
               Pace.Log.Put_Line ("Ran out of fuel, so stopping engine!");
               declare
                  Msg : Stop_Engine;
               begin
                  Pace.Dispatching.Input (Msg);
               end;
            end if;
         end Switch_Tanks;

      begin
         if Fuel_Cells (Current_Fuel_Cell).Fuel_Level <= 0.0 then
            Switch_Tanks;
         end if;
      end Monitor_Fuel;

   begin
      Pace.Log.Agent_Id (Id);
      accept Initialize;
      Initialized := True;
      loop
         Pace.Log.Wait (5.0);
         declare
            Msg : Get_Engine_Status;
         begin
            Pace.Dispatching.Output (Msg);
            if Msg.Engine_Running then
               Monitor_Fuel;
            end if;
         end;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Initialize is
   begin
      if Initialized then
         Pace.Log.Put_Line ("Fuel sensors already initialized");
      else
         Agent.Initialize;
      end if;
   end Initialize;

end Fuel_Sensors;
