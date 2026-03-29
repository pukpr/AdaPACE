

--::::::::::
--arrival.ads
--::::::::::
with Pace;
package Arrival is         
   pragma Elaborate_Body;

   type Manager_Tick is new Pace.Msg with null record;
   procedure Input (Obj : in Manager_Tick);

   type Manager_Start is new Pace.Msg with null record;
   procedure Input (Obj : in Manager_Start);

   type Manager_Stop is new Pace.Msg with null record;
   procedure Input (Obj : in Manager_Stop);

   type Timer_Start is new Pace.Msg with null record;
   procedure Input (Obj : in Timer_Start);

   type Timer_Stop is new Pace.Msg with null record;
   procedure Input (Obj : in Timer_Stop);

   type Speeder_Start is new Pace.Msg with null record;
   procedure Input (Obj : in Speeder_Start);

   type Speeder_Stop is new Pace.Msg with null record;
   procedure Input (Obj : in Speeder_Stop);

end Arrival; 
