with Pace;

package Post.B is
   pragma Elaborate_Body;

   type Start is new Pace.Msg with null record;
   procedure Input (Obj : in Start);

   type First is new Pace.Msg with null record;
   procedure Input (Obj : in First);

   type Second is new Pace.Msg with null record;
   procedure Input (Obj : in Second);

   type Third is new Pace.Msg with null record;
   procedure Input (Obj : in Third);

   type Fourth is new Pace.Msg with null record;
   procedure Input (Obj : in Fourth);

   type Op is new Pace.Msg with null record;
   procedure Input (Obj : in Op);

end Post.B;
