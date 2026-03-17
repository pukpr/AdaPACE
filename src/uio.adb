
package body Uio is

   function Success_Result (Result : Boolean) return Asu.Unbounded_String is
   begin
      if Result then
         return Success_String;
      else
         return Fail_String;
      end if;
   end Success_Result;

end Uio;
