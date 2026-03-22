package ANS.Monitor is

   -- A polling monitor for accessing the ANS system
   pragma Elaborate_Body;

   procedure Start;

   procedure Debug;

   procedure Position (Easting, Northing, Heading : out Float);

end;
