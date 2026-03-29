

--::::::::::
--bricks.ads
--::::::::::
with Wall;
with Pace;
package Bricks is 
   pragma Elaborate_Body;

   type Move_Finished is new Pace.Msg with record
      Result : Boolean;
   end record;
   procedure Output (Obj : out Move_Finished);

   type Move_Start is new Pace.Msg with null record;
   procedure Input (Obj : in Move_Start);

   type Move_Put is new Pace.Msg with record
      X     : Wall.Width;
      Y     : Wall.Height;
      Brick : Wall.Brick_Type;
      Done  : Boolean;        -- out: True when brick cannot be placed (game over)
   end record;
   procedure Inout (Obj : in out Move_Put);

   type Move_Right is new Pace.Msg with null record;
   procedure Input (Obj : in Move_Right);

   type Move_Left is new Pace.Msg with null record;
   procedure Input (Obj : in Move_Left);

   type Move_Rotation is new Pace.Msg with null record;
   procedure Input (Obj : in Move_Rotation);

   type Move_Drop is new Pace.Msg with record
      Ok : Boolean;           -- out: True while brick is still falling, False when it lands
   end record;
   procedure Inout (Obj : in out Move_Drop);

   type Move_Stop is new Pace.Msg with null record;
   procedure Input (Obj : in Move_Stop);

end Bricks; 
