
with Pace.Server.Xml;
with Ada.Strings.Unbounded;

package Uio is

   -- Crew Screen Functionality

   pragma Elaborate_Body;

   package Asu renames Ada.Strings.Unbounded;

   Success_String : constant Asu.Unbounded_String := Asu.To_Unbounded_String
     (Pace.Server.Xml.Item ("success", "TRUE"));
   Fail_String : constant Asu.Unbounded_String := Asu.To_Unbounded_String
     (Pace.Server.Xml.Item ("success", "FALSE"));

   function Success_Result (Result : Boolean) return Asu.Unbounded_String;

end Uio;
