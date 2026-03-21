with Pace;

package Aho.Demonstrator_Track is

   pragma Elaborate_Body;

   type Adjust_Track is new Pace.Msg with
      record
         Starting_Angle, Ending_Angle : Float;
      end record;
   procedure Input (Obj : in Adjust_Track);

end Aho.Demonstrator_Track;
