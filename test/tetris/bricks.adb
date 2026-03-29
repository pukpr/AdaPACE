

--::::::::::
--bricks.adb
--::::::::::
with Text_IO;
with Screen;
with Pace;
package body Bricks is 
   Finished_Flag : Boolean := False; 

   task Move is            -- User moves bricks according to key pressed
      pragma Priority(5); 
      entry Start; 
      entry Put (X     : in     Wall.Width; 
                 Y     : in     Wall.Height; 
                 Brick : in     Wall.Brick_Type; 
                 Done  :    out Boolean); 
      entry Right; 
      entry Left; 
      entry Rotation; 
      entry Drop (Ok : out Boolean); 
      entry Stop; 
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
      Outer : loop
         Text_IO.Put_Line("Move");
         accept Start; 
         Finished_Flag := False; 
         Middle : loop
            Exit_Flag := False; 
            accept Put (X     : in     Wall.Width; 
                        Y     : in     Wall.Height; 
                        Brick : in     Wall.Brick_Type; 
                        Done  :    out Boolean) do
               if Wall.Examine(Brick, X, Y) then 
                  Done := False; 
               else 
                  Done := True; 
                  Finished_Flag := True; 
                  Screen.MoveCursor((Column => 10, Row => 12));
                  Text_IO.Put_Line ("Try Again [Y/N] ?");
               end if; 
               Move.X := X; 
               Move.Y := Y; 
               Move.Brick := Brick; 
            end Put; 
            Wall.Put(Brick, X, Y); 
            Inner : loop
               select
                  accept Right do
                     if X < Wall.Width'Last then 
                        NX := X + 1; 
                        if Wall.Examine(Brick, NX, Y) then 
                           Wall.Erase(Brick, X, Y); 
                           X := NX; 
                           Wall.Put(Brick, X, Y); 
                        end if; 
                     end if; 
                  end Right; 
               or 
                  accept Left do
                     if Wall.Width'First < X then 
                        NX := X - 1; 
                        if Wall.Examine(Brick, NX, Y) then 
                           Wall.Erase(Brick, X, Y); 
                           X := NX; 
                           Wall.Put(Brick, X, Y); 
                        end if; 
                     end if; 
                  end Left; 
               or 
                  accept Rotation do
                     Rotate(Brick, New_Brick); 
                     if Wall.Examine(New_Brick, X, Y) then 
                        Wall.Erase(Brick, X, Y); 
                        Brick := New_Brick; 
                        Wall.Put(Brick, X, Y); 
                     end if; 
                  end Rotation; 
               or 
                  accept Drop (Ok : out Boolean) do
                     NY := Y + 1; 
                     if Wall.Examine(Brick, X, NY) then 
                        Wall.Erase(Brick, X, Y); 
                        Y := NY; 
                        Wall.Put(Brick, X, Y); 
                        Ok := True; 
                     else 
                        Wall.Place(Brick, X, Y); 
                        Ok := False; 
                        Exit_Flag := True; 
                     end if; 
                  end Drop; 
               or 
                  accept Stop; 
                  exit Middle; 
               end select; 
               if Exit_Flag then
                  select
                     accept Drop (Ok : out Boolean) do
                        Ok := False;
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

   pragma Warnings (Off, "formal parameter ""Obj"" is not referenced");

   procedure Output (Obj : out Move_Finished) is
   begin
      Obj.Result := Finished_Flag;
   end Output;

   procedure Input (Obj : in Move_Start) is
   begin
      Move.Start;
   end Input;

   procedure Inout (Obj : in out Move_Put) is
   begin
      Move.Put (Obj.X, Obj.Y, Obj.Brick, Obj.Done);
   end Inout;

   procedure Input (Obj : in Move_Right) is
   begin
      select
         Move.Right;
      else
         null;
      end select;
   end Input;

   procedure Input (Obj : in Move_Left) is
   begin
      select
         Move.Left;
      else
         null;
      end select;
   end Input;

   procedure Input (Obj : in Move_Rotation) is
   begin
      select
         Move.Rotation;
      else
         null;
      end select;
   end Input;

   procedure Inout (Obj : in out Move_Drop) is
   begin
      select
         Move.Drop (Obj.Ok);
      else
         Obj.Ok := True;   -- task busy; caller retries
      end select;
   end Inout;

   procedure Input (Obj : in Move_Stop) is
   begin
      Move.Stop;
   end Input;

   pragma Warnings (On, "formal parameter ""Obj"" is not referenced");

end Bricks; 
