package body Hal.Memory is

   protected body Shared is
      function Get return Data is
      begin
         return X;
      end;
      procedure Set (V : in Data) is
      begin
         X := V;
      end;
   end;

end;
