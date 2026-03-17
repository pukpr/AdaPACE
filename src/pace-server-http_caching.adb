with Pace.Log;

package body Pace.Server.Http_Caching is

   function Get_Count (Counter : Cache_Counter) return Long_Integer is
   begin
      return Counter.Count;
   end Get_Count;

   procedure Modified (Counter : in out Cache_Counter) is
   begin
      Pace.Log.Counter.Increment (Counter.Count);
   end Modified;

end Pace.Server.Http_Caching;
