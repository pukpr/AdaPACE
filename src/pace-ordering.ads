generic
   type Data is private;
   N : in Integer := 4;
   -- Byte ordering package, automatically adjusts for OS-endian
   -- $Id: pace-ordering.ads,v 1.1 2006/04/06 15:12:24 pukitepa Exp $
function Pace.Ordering (From : in Data) return Data;
