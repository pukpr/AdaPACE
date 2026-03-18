with Pace.Log;
with Ses.Pp;

package body Consumer_Pkg is

   task Consumer;
   task body Consumer is
      function ID is new Pace.Log.Unit_ID;
   begin
      Pace.Log.Agent_Id (ID);
      
      -- Terminal agent can wait for shutdown
      Ses.Pp.Parser;
   exception
      when others =>
         null;
   end Consumer;

end Consumer_Pkg;
