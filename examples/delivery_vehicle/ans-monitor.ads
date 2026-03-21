package ANS.Monitor is

   -- A polling monitor for accessing the ANS system
   pragma Elaborate_Body;

   procedure Start;

   procedure Debug;

   procedure Position (Easting, Northing, Heading : out Float);

   -- $Id: ans-monitor.ads,v 1.4 2004/12/09 13:18:10 ludwiglj Exp $
end;
