

--:::::::::::
--arrival.adb
--:::::::::::
with Bricks, Wall, Calendar;
with Pace;
with Pace.Log;
with Text_IO;

package body Arrival is

   Initial_Delay : constant := 0.6;
   Delay_Time    : Duration;

   type Unsigned is range 0..2**16;

   use Calendar;
   Seed : Unsigned := Unsigned(FLOAT(Seconds(Clock))/10.0); -- in range

   function Cheap_Random return Integer is
   begin
      Seed := (Seed * 25173 + 13849) mod 2**16;
      return Integer(Seed mod 2**15);
   end Cheap_Random;

   package body Manager is
      function Id is new Pace.Log.Unit_Id;

      task Agent is
         pragma Priority(8);
         entry Tick  (Obj : in Manager.Tick);
         entry Start (Obj : in Manager.Start);
         entry Stop  (Obj : in Manager.Stop);
      end Agent;

      task body Agent is
         Style : Wall.Styles;
         Done  : Boolean;
      begin
         Pace.Log.Agent_Id (Id);
         Outer : loop
            Text_IO.Put_Line("Manager");
            accept Start (Obj : in Manager.Start) do
               Pace.Log.Trace (Obj);
            end Start;
            Middle : loop
               Style := Wall.Styles(Cheap_Random mod Wall.Styles'LAST + 1);
               select
                  accept Tick (Obj : in Manager.Tick) do
                     Pace.Log.Trace (Obj);
                  end Tick;
               or
                  accept Stop (Obj : in Manager.Stop) do
                     Pace.Log.Trace (Obj);
                  end Stop;
                  exit Middle;
               or
                  delay Delay_Time;
               end select;
               declare
                  Msg : Bricks.Move_Put :=
                     (Pace.Msg with X => 5, Y => 2,
                      Brick => Wall.Pick(Style), Done => False);
               begin
                  Pace.Dispatching.Inout (Msg);
                  Done := Msg.Done;
               end;
               if Done then
                  accept Stop (Obj : in Manager.Stop) do
                     Pace.Log.Trace (Obj);
                  end Stop;
                  exit Middle;
               end if;
               for Y in Wall.Height'First + 1 .. Wall.Height'Last loop
                  declare
                     D : Bricks.Move_Drop;
                  begin
                     select
                        accept Tick (Obj : in Manager.Tick) do
                           Pace.Log.Trace (Obj);
                        end Tick;
                     or
                        accept Stop (Obj : in Manager.Stop) do
                           Pace.Log.Trace (Obj);
                        end Stop;
                        exit Middle;
                     or
                        delay Delay_Time;
                     end select;
                     Pace.Dispatching.Inout (D);
                     exit when not D.Ok;
                  end;
               end loop;
               Wall.Erase_Lines;
            end loop Middle;
         end loop Outer;
      exception
         when others => Text_IO.Put_Line("Manager error");
      end Agent;

      procedure Input (Obj : in Tick) is
      begin
         select
            Agent.Tick (Obj);
         else
            null;
         end select;
      end Input;

      procedure Input (Obj : in Start) is
      begin
         Agent.Start (Obj);
      end Input;

      procedure Input (Obj : in Stop) is
      begin
         Agent.Stop (Obj);
      end Input;

   end Manager;

   package body Timer is
      function Id is new Pace.Log.Unit_Id;

      task Agent is
         pragma Priority(6);
         entry Start (Obj : in Timer.Start);
         entry Stop  (Obj : in Timer.Stop);
      end Agent;

      task body Agent is
      begin
         Pace.Log.Agent_Id (Id);
         Outer : loop
            Delay_Time := Initial_Delay;
            Text_IO.Put_Line("Timer");
            accept Start (Obj : in Timer.Start) do
               Pace.Log.Trace (Obj);
            end Start;
            Main : loop
               select
                  accept Stop (Obj : in Timer.Stop) do
                     Pace.Log.Trace (Obj);
                  end Stop;
                  exit Main;
               or
                  delay Delay_Time;
               end select;
               Manager.Input (Manager.Tick'(Pace.Msg with null record));
            end loop Main;
         end loop Outer;
      exception
         when others => Text_IO.Put_Line("Timer error");
      end Agent;

      procedure Input (Obj : in Start) is
      begin
         Agent.Start (Obj);
      end Input;

      procedure Input (Obj : in Stop) is
      begin
         Agent.Stop (Obj);
      end Input;

   end Timer;

   package body Speeder is
      function Id is new Pace.Log.Unit_Id;

      task Agent is
         pragma Priority(7);
         entry Start (Obj : in Speeder.Start);
         entry Stop  (Obj : in Speeder.Stop);
      end Agent;

      task body Agent is
      begin
         Pace.Log.Agent_Id (Id);
         Delay_Time := Initial_Delay;
         Outer : loop
            Text_IO.Put_Line("Speeder");
            accept Start (Obj : in Speeder.Start) do
               Pace.Log.Trace (Obj);
            end Start;
            Middle : loop
               for I in 1 .. 100 loop
                  select
                     accept Stop (Obj : in Speeder.Stop) do
                        Pace.Log.Trace (Obj);
                     end Stop;
                     exit Middle;
                  or
                     delay Delay_Time;
                  end select;
               end loop;
               Delay_Time := Delay_Time*9/10;
            end loop Middle;
         end loop Outer;
      exception
         when others => Text_IO.Put_Line("Speeder error");
      end Agent;

      procedure Input (Obj : in Start) is
      begin
         Agent.Start (Obj);
      end Input;

      procedure Input (Obj : in Stop) is
      begin
         Agent.Stop (Obj);
      end Input;

   end Speeder;

end Arrival;
