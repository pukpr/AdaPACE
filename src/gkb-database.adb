with Pace.Strings;

package body Gkb.Database is

   use Rules;
   use Pace.Strings;

   ---------
   -- Get --
   ---------

   function Get (Query : String) return Boolean is
      V : Variables (1 .. 0);
   begin
      Agent.Query (Query, V);
      return True;
   exception
      when No_Match =>
         return False;
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query : String) return String is
      V : Variables (1 .. 1);
   begin
      Agent.Query (Query, V);
      return U2s (V (1));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query : String) return Float is
   begin
      return Float'Value (Get (Query));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query : String) return Integer is
   begin
      return Integer'Value (Get (Query));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, Value : String) return String is
      V : Variables (1 .. 2);
   begin
      V (1) := +Value;
      Agent.Query (Query, V);
      return +V (2);
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, Value : String) return Float is
   begin
      return Float'Value (Get (Query, Value));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, Value : String) return Integer is
   begin
      return Integer'Value (Get (Query, Value));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, V1, V2 : String) return String is
      V : Variables (1 .. 3);
   begin
      V (1) := +V1;
      V (2) := +V2;
      Agent.Query (Query, V);
      return +V (3);
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, V1, V2 : String) return Float is
   begin
      return Float'Value (Get (Query, V1, V2));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, V1, V2 : String) return Integer is
   begin
      return Integer'Value (Get (Query, V1, V2));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, V1, V2, V3 : String) return String is
      V : Variables (1 .. 4);
   begin
      V (1) := +V1;
      V (2) := +V2;
      V (3) := +V3;
      Agent.Query (Query, V);
      return +V (4);
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, V1, V2, V3 : String) return Float is
   begin
      return Float'Value (Get (Query, V1, V2, V3));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, V1, V2, V3 : String) return Integer is
   begin
      return Integer'Value (Get (Query, V1, V2, V3));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, V1, V2, V3, V4 : String) return String is
      V : Variables (1 .. 5);
   begin
      V (1) := +V1;
      V (2) := +V2;
      V (3) := +V3;
      V (4) := +V4;
      Agent.Query (Query, V);
      return +V (5);
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, V1, V2, V3, V4 : String) return Float is
   begin
      return Float'Value (Get (Query, V1, V2, V3, V4));
   end Get;

   ---------
   -- Get --
   ---------

   function Get (Query, V1, V2, V3, V4 : String) return Integer is
   begin
      return Integer'Value (Get (Query, V1, V2, V3, V4));
   end Get;

end Gkb.Database;

