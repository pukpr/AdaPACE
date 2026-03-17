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

   -- $Id: hal-memory.adb,v 1.1 2005/09/23 18:21:18 pukitepa Exp $
end;
