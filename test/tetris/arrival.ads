

--::::::::::
--arrival.ads
--::::::::::
with Pace;
package Arrival is
   pragma Elaborate_Body;

   package Manager is
      type Tick  is new Pace.Msg with null record;
      procedure Input (Obj : in Tick);

      type Start is new Pace.Msg with null record;
      procedure Input (Obj : in Start);

      type Stop  is new Pace.Msg with null record;
      procedure Input (Obj : in Stop);
   end Manager;

   package Timer is
      type Start is new Pace.Msg with null record;
      procedure Input (Obj : in Start);

      type Stop  is new Pace.Msg with null record;
      procedure Input (Obj : in Stop);
   end Timer;

   package Speeder is
      type Start is new Pace.Msg with null record;
      procedure Input (Obj : in Start);

      type Stop  is new Pace.Msg with null record;
      procedure Input (Obj : in Stop);
   end Speeder;

end Arrival;
