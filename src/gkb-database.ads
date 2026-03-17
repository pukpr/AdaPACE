generic
package Gkb.Database is

   pragma Elaborate_Body;

   -- Arity = 0
   function Get (Query : String) return Boolean;

   No_Match : exception renames Rules.No_Match;

   -- Arity = 1
   function Get (Query : String) return String;
   function Get (Query : String) return Float;
   function Get (Query : String) return Integer;

   -- Arity = 2
   function Get (Query, Value : String) return String;
   function Get (Query, Value : String) return Float;
   function Get (Query, Value : String) return Integer;

   -- Arity = 3
   function Get (Query, V1, V2 : String) return String;
   function Get (Query, V1, V2 : String) return Float;
   function Get (Query, V1, V2 : String) return Integer;

   -- Arity = 4
   function Get (Query, V1, V2, V3 : String) return String;
   function Get (Query, V1, V2, V3 : String) return Float;
   function Get (Query, V1, V2, V3 : String) return Integer;

   -- Arity = 5
   function Get (Query, V1, V2, V3, V4 : String) return String;
   function Get (Query, V1, V2, V3, V4 : String) return Float;
   function Get (Query, V1, V2, V3, V4 : String) return Integer;

end Gkb.Database;
