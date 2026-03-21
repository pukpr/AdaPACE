with Pace;
with Hal;
with Ada.Strings.Unbounded;

package Aho.Stacker is
   pragma Elaborate_Body;

   type Place_Box is new Pace.Msg with null record;
   procedure Input (Obj : in Place_Box);

   type Place_Bottle is new Pace.Msg with null record;
   procedure Input (Obj : in Place_Bottle);

   type Retract_Stacker is new Pace.Msg with
      record
         Unloaded : Boolean :=
           False;  -- true if stacker has neither bottle or box in it
      end record;
   procedure Input (Obj : in Retract_Stacker);

   type Retract_Bottle_Retainer is new Pace.Msg with null record;
   procedure Input (Obj : in Retract_Bottle_Retainer);

   procedure Reset_Bottle;
   procedure Reset_Box;

private
   pragma Inline (Input);

-- $id: aho-stacker.ads,v 1.4 12/22/2003 14:17:43 ludwiglj Exp $
end Aho.Stacker;
