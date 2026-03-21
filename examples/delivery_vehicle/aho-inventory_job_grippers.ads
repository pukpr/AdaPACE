with Pace;

package Aho.Inventory_Job_Grippers is

   pragma Elaborate_Body;

   type Open_Box_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Open_Box_Grippers);

   type Close_Box_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Close_Box_Grippers);

   type Open_Bottle_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Open_Bottle_Grippers);

   type Close_Bottle_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Close_Bottle_Grippers);

end Aho.Inventory_Job_Grippers;
