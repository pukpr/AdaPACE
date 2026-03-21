with Pace;
with Hal;

package Aho.Resupply_Clip is

  type Next_Cell is new Pace.Msg with 
   record
      Cell : Integer;
   end record;
  procedure Input (Obj : in Next_Cell);   
  
  
  type Rotate_Clip is new Pace.Msg with
      record
         Final : Hal.Orientation;
         Speed : Float;
         Axis : Character;
      end record;
   procedure Input (Obj : in Rotate_Clip);


end Aho.Resupply_Clip;
