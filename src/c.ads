with Interfaces.C;
with Interfaces.C.Strings;
with System;

package C is

   -- Interfaces to C package used with the c2ada binding utility
   subtype Signed_Short is Interfaces.C.Short;         -- Signed Short
   subtype Short is Interfaces.C.Short;         -- Signed Short
   subtype Signed_Int is Interfaces.C.Int;             -- Signed Integer
   subtype Int is Interfaces.C.Int;             -- Signed Integer
   subtype Signed_Long_Long is Interfaces.C.Long;
   subtype Long_Long is Interfaces.C.Long;
   subtype Float is Interfaces.C.C_Float;              -- 32-bit float
   subtype Ucharp is Interfaces.C.Strings.Chars_Ptr;   -- Character pointer
   subtype Ustring is Interfaces.C.Char_Array;         -- Character array
   type A_Signed_Int_T is access all Signed_Int;       -- Integer pointer
   type A_Float_T is access all Float;                 -- Float pointer
   subtype Unsigned_Char is Interfaces.C.Unsigned_Char;
   subtype Signed_Char is Interfaces.C.Signed_Char;
   subtype Char is Interfaces.C.Char;
   subtype Natural_Int is Natural;

   subtype Void is System.Address; -- This is meant to be used as an opaque type


   subtype Unsigned_Int is Interfaces.C.Unsigned;      -- Unsigned Integer
   subtype Unsigned_Long_Long is Interfaces.C.Unsigned_Long;
   subtype Unsigned_Short is Interfaces.C.Unsigned_Short;
   subtype Double is Interfaces.C.Double;              -- 64-bit float

   -- $Id: c.ads,v 1.5 2005/01/13 21:48:09 ludwiglj Exp $

end C;
