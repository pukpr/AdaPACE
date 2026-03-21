with Pace;
with Pace.Notify;
with Hal;

package Aho.Door is

   pragma Elaborate_Body;

   type Open_Door_Door is new Pace.Msg with null record;
   procedure Input (Obj : in Open_Door_Door);

   type Close_Door_Door is new Pace.Msg with null record;
   procedure Input (Obj : in Close_Door_Door);

   type Rotate_Door is new Pace.Msg with
      record
         Final : Hal.Orientation;
         Speed : Float;
         Axis : Character;
      end record;
   procedure Input (Obj : in Rotate_Door);

   -- communicates to drone that rotate portion of door is done so the chamber can be sprayed
   type Rotate_Done is new Pace.Notify.Subscription with null record;

private
   pragma Inline (Input);

-- $id: aho-door.ads,v 1.4 12/22/2003 14:11:09 ludwiglj Exp $
end Aho.Door;
