with Pace;

package Aho.Morph_Track is

   pragma Elaborate_Body;

   type Do_Morph is new Pace.Msg with
      record
         Starting_Angle, Ending_Angle : Float;
      end record;
   procedure Input (Obj : in Do_Morph);

end Aho.Morph_Track;
