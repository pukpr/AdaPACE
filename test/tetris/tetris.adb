

--::::::::::
--tetris.adb
--::::::::::
with Screen, Bricks, Wall, Arrival, Text_IO; 
with Pace;
with Pace.Log;
procedure Tetris is 

   pragma Priority(4); 

   Ch        : Character; 
   Available : Boolean;
   Finished  : Bricks.Move_Finished;
   Drop      : Bricks.Move_Drop; 

begin
   Pace.Log.Agent_Id;
   loop
      Screen.ClearScreen; 

      Wall.Initialize; 
      Screen.MoveCursor((Column => 10, Row => 3)); 
      Text_IO.Put_Line( " TETRIS Ada " );
      Screen.MoveCursor((Column => 1, Row => 5)); 
      Text_IO.Put_Line( "2=drop 4=left 5=spin 6=right");

      Pace.Dispatching.Input (Bricks.Move_Start'(Pace.Msg with null record));
      Pace.Dispatching.Input (Arrival.Manager.Start'(Pace.Msg with null record));
      Pace.Dispatching.Input (Arrival.Timer.Start'(Pace.Msg with null record));
      Pace.Dispatching.Input (Arrival.Speeder.Start'(Pace.Msg with null record));

      Outer : loop
         loop
            Get_Immediate(Ch, Available);
            exit when Available;
            delay 0.01;
         end loop;
         Pace.Dispatching.Output (Finished);
         exit Outer when Finished.Result;
         case Ch is
            when '2' => -- Down arrow
               loop
                  Pace.Dispatching.Inout (Drop);
                  exit when not Drop.Ok;
               end loop;
               delay 1.0;
            when '4' => -- Left arrow
               Pace.Dispatching.Input (Bricks.Move_Left'(Pace.Msg with null record));
            when '5' => -- spin
               Pace.Dispatching.Input (Bricks.Move_Rotation'(Pace.Msg with null record));
            when '6' => -- Right arrow
               Pace.Dispatching.Input (Bricks.Move_Right'(Pace.Msg with null record));
            when others =>
               null;
         end case;
      end loop Outer; 

      Pace.Dispatching.Input (Arrival.Speeder.Stop'(Pace.Msg with null record));
      Pace.Dispatching.Input (Arrival.Timer.Stop'(Pace.Msg with null record));
      Pace.Dispatching.Input (Bricks.Move_Stop'(Pace.Msg with null record));
      Pace.Dispatching.Input (Arrival.Manager.Stop'(Pace.Msg with null record));

      exit when Ch /= 'Y' and Ch /= 'y';

   end loop; 

   -- Screen.ClearScreen;
   Text_IO.New_Line(20);

end Tetris; 
