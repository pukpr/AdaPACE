generic
   type Data is private;
   N : in Integer := 4;
   -- Byte ordering package, automatically adjusts for OS
   -- $id: hal-ordering.ads,v 1.1 06/26/2003 22:11:15 pukitepa Exp $
function Hal.Ordering (From : in Data) return Data;
