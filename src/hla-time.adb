with Interfaces.C;
with Pace.TCP;
with Pace.Ordering;
with Unchecked_Conversion;

function Hla.Time (NTP : Boolean := False) return Seconds is

   Seconds_1900_1970 : constant := 2_208_988_800; -- Official

   procedure Time_T (T : access Interfaces.Unsigned_32);
   pragma Import (C, Time_T, "time");
   
   T : aliased Interfaces.Unsigned_32;
   --use type Seconds; -- Interfaces.Unsigned_64;
   use type Interfaces.Unsigned_32;

   type D is
      record
         Up, Low : Interfaces.Unsigned_32 := 0;
      end record;
   DTime : D;
   
   function To_Seconds is new Unchecked_Conversion(D, Seconds); 
   function Endian is new Pace.Ordering (Interfaces.Unsigned_32); 

begin
   
   if NTP then
      declare
         use Pace.TCP;
         ST : Socket_Type := 
            Establish_Connection(Pace.Getenv("NTP_SERVER","localhost") & ":37");
      begin
         -- Physical_Send (ST, Char'Address, 1); -- not needed
         Physical_Receive (ST, T'Address, 4);
         T := Endian (T);
         Dtime.Low := T;
         -- return Seconds (T);
      end;
   else -- regular UNIX call
      Time_T (T'Unchecked_Access);
      Dtime.Low := T + Seconds_1900_1970;
      -- return Seconds (T) + Seconds_1900_1970;
   end if;
   return To_Seconds (Dtime);

end;
