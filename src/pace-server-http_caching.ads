

package Pace.Server.Http_Caching is

   type Cache_Counter is tagged private;
   type Cache_Counter_Ptr is access all Cache_Counter;
   function Get_Count (Counter : Cache_Counter) return Long_Integer;
   procedure Modified (Counter : in out Cache_Counter);
   Null_Cache_Counter_Ptr : Cache_Counter_Ptr;

private
   type Cache_Counter is tagged
      record
         Count : Long_Integer := 0;
      end record;
end Pace.Server.Http_Caching;
