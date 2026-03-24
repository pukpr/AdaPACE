generic
   type Data is private;
   N : in Integer := 4;
   -- Byte ordering package, automatically adjusts for OS-endian
function Pace.Ordering (From : in Data) return Data;
