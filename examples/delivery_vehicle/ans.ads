with Pace;
package ANS is
   -- Autonomous Navigation System
   --
   pragma Elaborate_Body;

   type Start_Msg is new Pace.Msg with
      record
         -- in degrees
         Latitude : Float;
         Longitude : Float;
         Heading : Float;
         Altitude : Float;
      end record;
   procedure Input (Obj : in Start_Msg);

   type Update_Msg is new Pace.Msg with
     record
        DX, DY, DH : Float;
     end record;
   procedure Input (Obj : in Update_Msg);

   type Position_Msg is new Pace.Msg with
     record
        Easting, Northing, Heading : Float;  -- heading in radians
     end record;
   procedure Output (Obj : out Position_Msg);

   -- $Id: ans.ads,v 1.6 2004/12/09 13:18:10 ludwiglj Exp $
end;

