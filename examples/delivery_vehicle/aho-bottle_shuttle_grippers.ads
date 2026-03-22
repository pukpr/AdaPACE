with Pace;

package Aho.Bottle_Shuttle_Grippers is

   pragma Elaborate_Body;

   type Open_Bottle_Shuttle_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Open_Bottle_Shuttle_Grippers);

   type Close_Bottle_Shuttle_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Close_Bottle_Shuttle_Grippers);

end Aho.Bottle_Shuttle_Grippers;
