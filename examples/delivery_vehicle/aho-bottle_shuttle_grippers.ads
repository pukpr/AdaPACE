with Pace;

package Aho.Bottle_Shuttle_Grippers is

   pragma Elaborate_Body;

   type Open_Bottle_Shuttle_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Open_Bottle_Shuttle_Grippers);

   type Close_Bottle_Shuttle_Grippers is new Pace.Msg with null record;
   procedure Input (Obj : in Close_Bottle_Shuttle_Grippers);

-- $id: aho-bottle_shuttle_grippers.ads,v 1.2 12/22/2003 14:17:54 ludwiglj Exp $
end Aho.Bottle_Shuttle_Grippers;
