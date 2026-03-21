with Pace;
with Hal;
with Ada.Strings.Unbounded;

package Aho.Actuator is
   pragma Elaborate_Body;

   type Place_Box is new Pace.Msg with null record;
   procedure Input (Obj : in Place_Box);

   type Place_Bottle is new Pace.Msg with null record;
   procedure Input (Obj : in Place_Bottle);

   type Retract_Actuator is new Pace.Msg with
      record
         Unloaded : Boolean :=
           False;  -- true if actuator has neither bottle or box in it
      end record;
   procedure Input (Obj : in Retract_Actuator);

   type Retract_Bottle_Retainer is new Pace.Msg with null record;
   procedure Input (Obj : in Retract_Bottle_Retainer);

   procedure Reset_Bottle;
   procedure Reset_Box;

private
   pragma Inline (Input);

-- $id: aho-actuator.ads,v 1.4 12/22/2003 14:17:43 ludwiglj Exp $
end Aho.Actuator;
