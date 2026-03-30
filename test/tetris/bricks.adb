

--::::::::::
--bricks.adb
--::::::::::
with Text_IO;
with Screen;
with Pace;
with Pace.Log;
package body Bricks is 
   function Id is new Pace.Log.Unit_Id;

   Finished_Flag : Boolean := False;

   task Move is            -- User moves bricks according to key pressed
      pragma Priority(5); 
      entry Start    (Obj : in     Move_Start);
      entry Put      (Obj : in out Move_Put);
      entry Right    (Obj : in     Move_Right);
      entry Left     (Obj : in     Move_Left);
      entry Rotation (Obj : in     Move_Rotation);
      entry Drop     (Obj : in out Move_Drop);
      entry Stop     (Obj : in     Move_Stop);
   end Move; 

   task body Move is 
      X, NX            : Wall.Width; 
      Y, NY            : Wall.Height; 
      New_Brick, Brick : Wall.Brick_Type; 
      Exit_Flag        : Boolean := False; 

      procedure Rotate (Brick     : in     Wall.Brick_Type; 
                        New_Brick :    out Wall.Brick_Type) is 
         X, Y : Integer; 
         B    : Wall.Brick_Type; 
      begin
         for I in Brick'range loop
            X := Brick(I).Y + 1; 
            Y :=  -(Brick(I).X - 1); 
            B(I).X := X; 
            B(I).Y := Y; 
         end loop; 
         New_Brick := B; 
      end Rotate; 

   begin
      Pace.Log.Agent_Id (Id);
      Outer : loop
         Text_IO.Put_Line("Move");
         accept Start (Obj : in Move_Start) do
            Pace.Log.Trace (Obj);
         end Start;
         Finished_Flag := False; 
         Middle : loop
            Exit_Flag := False; 
            accept Put (Obj : in out Move_Put) do
               if Wall.Examine(Obj.Brick, Obj.X, Obj.Y) then 
                  Obj.Done := False; 
               else 
                  Obj.Done := True; 
                  Finished_Flag := True; 
                  Screen.MoveCursor((Column => 10, Row => 12));
                  Text_IO.Put_Line ("Try Again [Y/N] ?");
               end if; 
               X     := Obj.X; 
               Y     := Obj.Y; 
               Brick := Obj.Brick; 
               Pace.Log.Trace (Obj);
            end Put; 
            Wall.Put(Brick, X, Y); 
            Inner : loop
               select
                  accept Right (Obj : in Move_Right) do
                     if X < Wall.Width'Last then 
                        NX := X + 1; 
                        if Wall.Examine(Brick, NX, Y) then 
                           Wall.Erase(Brick, X, Y); 
                           X := NX; 
                           Wall.Put(Brick, X, Y); 
                        end if; 
                     end if; 
                     Pace.Log.Trace (Obj);
                  end Right; 
               or 
                  accept Left (Obj : in Move_Left) do
                     if Wall.Width'First < X then 
                        NX := X - 1; 
                        if Wall.Examine(Brick, NX, Y) then 
                           Wall.Erase(Brick, X, Y); 
                           X := NX; 
                           Wall.Put(Brick, X, Y); 
                        end if; 
                     end if; 
                     Pace.Log.Trace (Obj);
                  end Left; 
               or 
                  accept Rotation (Obj : in Move_Rotation) do
                     Rotate(Brick, New_Brick); 
                     if Wall.Examine(New_Brick, X, Y) then 
                        Wall.Erase(Brick, X, Y); 
                        Brick := New_Brick; 
                        Wall.Put(Brick, X, Y); 
                     end if; 
                     Pace.Log.Trace (Obj);
                  end Rotation; 
               or 
                  accept Drop (Obj : in out Move_Drop) do
                     NY := Y + 1; 
                     if Wall.Examine(Brick, X, NY) then 
                        Wall.Erase(Brick, X, Y); 
                        Y := NY; 
                        Wall.Put(Brick, X, Y); 
                        Obj.Ok := True; 
                     else 
                        Wall.Place(Brick, X, Y); 
                        Obj.Ok := False; 
                        Exit_Flag := True; 
                     end if; 
                     Pace.Log.Trace (Obj);
                  end Drop; 
               or 
                  accept Stop (Obj : in Move_Stop) do
                     Pace.Log.Trace (Obj);
                  end Stop;
                  exit Middle; 
               end select; 
               if Exit_Flag then
                  select
                     accept Drop (Obj : in out Move_Drop) do
                        Obj.Ok := False;
                        Pace.Log.Trace (Obj);
                     end Drop;
                  or
                     delay 1.0;
                  end select;
                  exit Inner; 
               end if; 
            end loop Inner; 
         end loop Middle; 
      end loop Outer; 
   exception 
      when others => Text_IO.Put_Line("Move error");
   end Move; 

   procedure Output (Obj : out Move_Finished) is
   begin
      Obj.Result := Finished_Flag;
      Pace.Log.Trace (Obj);
   end Output;

   procedure Input (Obj : in Move_Start) is
   begin
      Move.Start (Obj);
   end Input;

   procedure Inout (Obj : in out Move_Put) is
   begin
      Move.Put (Obj);
   end Inout;

   procedure Input (Obj : in Move_Right) is
   begin
      select
         Move.Right (Obj);
      else
         null;
      end select;
   end Input;

   procedure Input (Obj : in Move_Left) is
   begin
      select
         Move.Left (Obj);
      else
         null;
      end select;
   end Input;

   procedure Input (Obj : in Move_Rotation) is
   begin
      select
         Move.Rotation (Obj);
      else
         null;
      end select;
   end Input;

   procedure Inout (Obj : in out Move_Drop) is
   begin
      select
         Move.Drop (Obj);
      else
         Obj.Ok := True;   -- task busy; caller retries
      end select;
   end Inout;

   procedure Input (Obj : in Move_Stop) is
   begin
      Move.Stop (Obj);
   end Input;

end Bricks; 
