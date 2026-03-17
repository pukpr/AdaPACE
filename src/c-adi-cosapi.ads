--
-- File Name: c.adi.cosapi.1.ada
--

with C;
with System;

package C.Adi.Cosapi is

   Cicmd_Double   : constant := 8#0000#;                  -- cosapi.h:5
   Cicmd_Float    : constant := 1;                        -- cosapi.h:6
   Cicmd_String   : constant := 2;                        -- cosapi.h:7
   Cicmd_Integer  : constant := 3;                        -- cosapi.h:8
   Cicmd_Char     : constant := 4;                        -- cosapi.h:9
   Cicmd_Address  : constant := 5;                        -- cosapi.h:10
   Cosapi_Success : constant := 8#0000#;                  -- cosapi.h:25
   Cosapi_Error   : constant := -1;                       -- cosapi.h:26
   True           : constant := 1;                        -- cosapi.h:41
   False          : constant := 8#0000#;                  -- cosapi.h:44

   type Union_Anonymous0_T;                                    -- cosapi.h:20
   type Struct_Cicmdrtsdatum;                                  -- cosapi.h:13

   type A_Struct_Cicmdrtsdatum_T is access all Struct_Cicmdrtsdatum; -- cosapi.
                                                                     --h:62

   type Union_Anonymous0_T_Kind is (                           -- cosapi.h:20
      Dblval_Kind,
      Fltval_Kind,
      Strval_Kind,
      Intval_Kind);

   type Union_Anonymous0_T (Which : Union_Anonymous0_T_Kind := Dblval_Kind) is
   -- cosapi.h:20
   record
      case Which is
         when Dblval_Kind =>
            Dblval : C.Double;                           -- cosapi.h:16
         when Fltval_Kind =>
            Fltval : C.Float;                            -- cosapi.h:17
         when Strval_Kind =>
            Strval : C.Ucharp;                           -- cosapi.h:18
         when Intval_Kind =>
            Intval : C.Signed_Int;                       -- cosapi.h:19
      end case;
   end record;

   pragma Convention (C, Union_Anonymous0_T);
   pragma Unchecked_Union (Union_Anonymous0_T);

   type Struct_Cicmdrtsdatum is                                -- cosapi.h:13
   record
      Typetag : C.Signed_Int;                              -- cosapi.h:14
      Val     : Union_Anonymous0_T;                        -- cosapi.h:20
      Address : C.Signed_Int;                              -- cosapi.h:21
      Size    : C.Signed_Int;                              -- cosapi.h:22
   end record;

   pragma Convention (C, Struct_Cicmdrtsdatum);                -- cosapi.h:13

   subtype Cicmdrtsdatum is Struct_Cicmdrtsdatum;              -- cosapi.h:23

   type Vector_Of_Struct_Cicmdrtsdatum_T is                    -- cosapi.h:63
     array (Integer range <>) of Struct_Cicmdrtsdatum;

   function Cosapierrormessage return C.Ucharp;                -- cosapi.h:48

   procedure Cosapiinit;                                       -- cosapi.h:49

   procedure Cosapiwrapup;                                     -- cosapi.h:50

   procedure Cosapiexit (Exitstatus : C.Signed_Int);              -- cosapi.h:5
                                                                  --1

   function Cosapiattach (Rtsname : C.Ucharp) return C.Signed_Int;-- cosapi.h:5
                                                                  --3

   function Cosapireattach (Rtsname : C.Ucharp) return C.Signed_Int; -- cosapi.
                                                                     --h:54

   function Cosapidetach (Rtsname : C.Ucharp) return C.Signed_Int;-- cosapi.h:5
                                                                  --5

   function Cosapiprogramload
     (Progname : C.Ucharp;
      Isrejoin : C.Signed_Int)
      return     C.Signed_Int;   -- cosapi.h:56

   function Cosapigo return C.Signed_Int;                      -- cosapi.h:57

   function Cosapihalt (Procname : C.Ucharp) return C.Signed_Int; -- cosapi.h:5
                                                                  --8

   function Cosapicontinue (Procname : C.Ucharp) return C.Signed_Int;-- cosapi.
                                                                     --h:59

   function Cosapiwait
     (Procname : C.Ucharp;
      Duration : C.Signed_Int)
      return     C.Signed_Int;          -- cosapi.h:60

   function Cosapireset return C.Signed_Int;                   -- cosapi.h:61

   function Cosapiget
     (Varstr   : C.Ucharp;
      Varvalue : A_Struct_Cicmdrtsdatum_T)
      return     C.Signed_Int;           -- cosapi.h:62

   --    function COSAPIPUT(varStr   : c.ucharp;
   --                       varValVec:
   --VECTOR_OF_STRUCT_CICMDRTSDATUM_T(0..c.max_bound);
   --                       count    : c.signed_int)
   --                                  return c.signed_int;          --
   --cosapi.h:63

   function Cosapiput
     (Varstr    : C.Ucharp;
      Varvalvec : A_Struct_Cicmdrtsdatum_T;
      Count     : C.Signed_Int := 1)
      return      C.Signed_Int;          -- cosapi.h:63

   function Cosapicapture return C.Signed_Int;                 -- cosapi.h:64

   function Cosapicapture_Add
     (Varstr   : C.Ucharp;
      Aliasstr : C.Ucharp)
      return     C.Signed_Int;   -- cosapi.h:65

   function Cosapicapture_Delete (Varstr : C.Ucharp) return C.Signed_Int;
   -- cosapi.h:66

   function Cosapidevice_Status
     (Rtsname  : C.Ucharp;
      Procname : C.Ucharp;
      Value    : A_Struct_Cicmdrtsdatum_T)
      return     C.Signed_Int; -- cosapi.h:67

private

   pragma Import (C, Cosapierrormessage, "COSAPIerrorMessage");-- cosapi.h:48

   pragma Import (C, Cosapiinit, "COSAPIinit");                -- cosapi.h:49

   pragma Import (C, Cosapiwrapup, "COSAPIwrapup");            -- cosapi.h:50

   pragma Import (C, Cosapiexit, "COSAPIexit");                -- cosapi.h:51

   pragma Import (C, Cosapiattach, "COSAPIattach");            -- cosapi.h:53

   pragma Import (C, Cosapireattach, "COSAPIreattach");        -- cosapi.h:54

   pragma Import (C, Cosapidetach, "COSAPIdetach");            -- cosapi.h:55

   pragma Import (C, Cosapiprogramload, "COSAPIprogramLoad");  -- cosapi.h:56

   pragma Import (C, Cosapigo, "COSAPIgo");                    -- cosapi.h:57

   pragma Import (C, Cosapihalt, "COSAPIhalt");                -- cosapi.h:58

   pragma Import (C, Cosapicontinue, "COSAPIcontinue");        -- cosapi.h:59

   pragma Import (C, Cosapiwait, "COSAPIwait");                -- cosapi.h:60

   pragma Import (C, Cosapireset, "COSAPIreset");              -- cosapi.h:61

   pragma Import (C, Cosapiget, "COSAPIget");                  -- cosapi.h:62

   pragma Import (C, Cosapiput, "COSAPIput");                  -- cosapi.h:63

   pragma Import (C, Cosapicapture, "COSAPIcapture");          -- cosapi.h:64

   pragma Import (C, Cosapicapture_Add, "COSAPIcapture_add");  -- cosapi.h:65

   pragma Import (C, Cosapicapture_Delete, "COSAPIcapture_delete");  -- cosapi.
                                                                     --h:66

   pragma Import (C, Cosapidevice_Status, "COSAPIdevice_status"); -- cosapi.h:6
                                                                  --7

   ----------------------------------------------------------------------------
   ----
   -- $version: 1 $
   -- $history: Common $
   -- $view: /prog/shared/modsim/ctd/ssom/ssom.ss/integ.wrk $
   ----------------------------------------------------------------------------
   ----

end C.Adi.Cosapi;
