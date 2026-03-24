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

end;
