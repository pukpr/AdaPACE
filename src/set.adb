
package body Set is

   function Member (E : Elements; M : Members) return Boolean is
   begin
      for I in M'Range loop
         if E = M (I) then
            return True;
         end if;
      end loop;
      return False;
   end Member;

end Set;

