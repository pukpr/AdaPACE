generic
   type Data is private;
package Hal.Memory is
   --pragma Pure;
   --pragma(Shared_Passive);

   protected Shared is
      function Get return Data;
      procedure Set (V : in Data);
   private
      X : Data;
   end;

   -- $Id: hal-memory.ads,v 1.1 2005/09/23 18:21:18 pukitepa Exp $
end;
