

--::::::::::
--arrival.adb
--::::::::::
with Bricks, Wall, Calendar;
with Pace;
with Pace.Log;
with Text_IO;

package body Arrival is 

   function Id is new Pace.Log.Unit_Id;

   task Manager is         -- Starts the dropping bricks 
      pragma Priority(8); 
      entry Tick; 
      entry Start; 
      entry Stop; 
   end Manager; 

   task Timer is           -- Timing between events
      pragma Priority(6); 
      entry Start; 
      entry Stop; 
   end Timer; 

   task Speeder is         -- Picks up the pace after certain time
      pragma Priority(7);  
      entry Start; 
      entry Stop; 
   end Speeder; 

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


   task body Manager is 
      Style : Wall.Styles; 
      Done  : Boolean;  
   begin
      Pace.Log.Agent_Id (Id);
      Outer : loop
         Text_IO.Put_Line("Manager");
         accept Start;
         Middle : loop
            Style := Wall.Styles(Cheap_Random mod Wall.Styles'LAST + 1); 
            select
               accept Tick; 
            or 
               accept Stop; 
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
               accept Stop; 
               exit Middle; 
            end if; 
            for Y in Wall.Height'First + 1 .. Wall.Height'Last loop
               declare
                  D : Bricks.Move_Drop;
               begin
                  select
                     accept Tick;
                  or
                     accept Stop;
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
   end Manager; 

   task body Timer is 
   begin
      Pace.Log.Agent_Id (Id);
      Outer : loop
         Delay_Time := Initial_Delay;
         Text_IO.Put_Line("Timer");
         accept Start;
         Main : loop
            select
               accept Stop; 
               exit Main;
            or 
               delay Delay_Time; 
            end select; 
            select
               Manager.Tick; 
            else
               null;
            end select;
         end loop Main;
      end loop Outer; 
   exception 
      when others => Text_IO.Put_Line("Timer error");
   end Timer; 


   task body Speeder is 
   begin
      Pace.Log.Agent_Id (Id);
      Delay_Time := Initial_Delay;
      Outer : loop
         Text_IO.Put_Line("Speeder");
         accept Start;
         Middle : loop
            for I in 1 .. 100 loop
               select
                  accept Stop; 
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
   end Speeder; 

   pragma Warnings (Off, "formal parameter ""Obj"" is not referenced");

   procedure Input (Obj : in Manager_Start) is
   begin
      Manager.Start;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Manager_Tick) is
   begin
      select
         Manager.Tick;
      else
         null;
      end select;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Manager_Stop) is
   begin
      Manager.Stop;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Timer_Start) is
   begin
      Timer.Start;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Timer_Stop) is
   begin
      Timer.Stop;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Speeder_Start) is
   begin
      Speeder.Start;
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Speeder_Stop) is
   begin
      Speeder.Stop;
      Pace.Log.Trace (Obj);
   end Input;

   pragma Warnings (On, "formal parameter ""Obj"" is not referenced");

end Arrival;
