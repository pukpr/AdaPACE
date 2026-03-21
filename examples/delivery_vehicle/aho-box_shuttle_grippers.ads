with Pace;

package Aho.Box_Shuttle_Grippers is

   pragma Elaborate_Body;

   type Open_Box_Shuttle_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Open_Box_Shuttle_Grippers);
   
   type Close_Box_Shuttle_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Close_Box_Shuttle_Grippers);

      
end Aho.Box_Shuttle_Grippers;
