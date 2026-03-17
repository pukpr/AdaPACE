with Pace.Semaphore;
with Ada.Strings.Unbounded;
with Interfaces.C.Strings;

package Hla is
   pragma Elaborate_Body;

   type Gateway is private;
   Null_Gateway : constant Gateway;

   procedure Startup_Cplusplus; -- Not needed with integrated gnatmake
   pragma Import (C, Startup_Cplusplus, "_main");


   type Get_Name is access function (Group, ID : Integer) return Interfaces.C.Strings.chars_ptr;
   pragma Convention (C, Get_Name);
   type Get_Number is access function (Group, ID : Integer) return Integer;
   pragma Convention (C, Get_Number);
   type Get_Index_Name is access function (Group, ID, Index : Integer) return Interfaces.C.Strings.chars_ptr;
   pragma Convention (C, Get_Index_Name);

   function Startup_Gateway (Fed_Path : Interfaces.C.Strings.Chars_Ptr;
                             Federate_Name : Interfaces.C.Strings.Chars_Ptr;
                             Federation_Name : Interfaces.C.Strings.Chars_Ptr;
                             Group : Integer;
                             int_name : Get_Name;
                             Obj_name : Get_Name;
                             Obj_atts : Get_Number;
                             Att_name : Get_Index_Name;
                             Obj_mode : Get_Number;
                             Int_mode : Get_Number
                             ) return Gateway;
   pragma Import (C, Startup_Gateway, "Startup_Gateway");

   function Federate_Handle (Handle : Gateway := Null_Gateway) return Integer;
   pragma Import (C, Federate_Handle, "Get_Federate_Handle");

   function Get_Phase return Interfaces.C.Strings.Chars_Ptr;
   pragma Import (C, Get_Phase, "Get_Phase");

   function Get_Phase_Time return Interfaces.C.Strings.Chars_Ptr;
   pragma Import (C, Get_Phase_Time, "Get_Phase_Time");

   procedure Exit_Gateway (Handle : Gateway := Null_Gateway);

   function Name (Str : in String) return Ada.Strings.Unbounded.Unbounded_String
     renames Ada.Strings.Unbounded.To_Unbounded_String;

   type Tuple is
      record
         Param : Ada.Strings.Unbounded.Unbounded_String;
         Data : Ada.Strings.Unbounded.Unbounded_String;
      end record;

   generic
      Parameter_Name : String;
      type Binary (<>) is private;
   package Convert is
      function Value (Str : String) return Binary;
      function Image (Data : Binary) return String;
      function Param (Data : Binary) return Tuple;
      function Check (Unknown_Name : String) return Boolean;
   end Convert;

   -- HLA XDR matching types

   type Bool is new Boolean;
   for Bool'Size use 32;

   type VString (Length : Integer) is
      record
         Value : String (1..Length);
      end record;
   function "+" (Str : in String) return VString;
   function "+" (Str : in VString) return String;

   -- Convenience for typical HLA types
   subtype Long is Integer;
   subtype Longlong is Long_Integer;
   subtype Seconds is Interfaces.Unsigned_64;
   subtype Short is Interfaces.Unsigned_16;
   subtype Double is Long_Float;
   type Enum is new Natural;

private
   type Gateway is new Integer;
   Null_Gateway : constant Gateway := 0;

   Connection : aliased Pace.Semaphore.Mutex;

   -- $Id: hla.ads,v 1.14 2005/01/14 14:45:30 ludwiglj Exp $

end Hla;
