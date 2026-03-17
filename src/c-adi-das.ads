--
-- File Name: c.adi.das.1.ada
--
with C;
with System;
with Interfaces.C.Pointers;
with Interfaces.C.Strings;

package C.Adi.Das is

   generic package P renames Interfaces.C.Pointers;

   subtype Double is Interfaces.C.double;

   Das_Id                  : constant := 271828182;                -- DAS.h:7
   Das_Version             : constant := 1;                        -- DAS.h:8
   Das_Handshake_Greeting  : constant := 16#6071_3D44#;          -- DAS.h:13
   Das_Handshake_Reply     : constant := 16#544B_2FBA#;          -- DAS.h:14
   Das_Handshake_Mode      : constant := 8#0000#;                -- DAS.h:15
   Das_Mode_Single_Conn    : constant := 16#0000#;               -- DAS.h:16
   Das_Mode_Multi_Conn     : constant := 16#0001#;               -- DAS.h:17
   Das_Op_Title            : constant := 1;                      -- DAS.h:22
   Das_Op_Comments         : constant := 2;                      -- DAS.h:23
   Das_Op_Variables        : constant := 3;                      -- DAS.h:24
   Das_Op_Rdate            : constant := 4;                      -- DAS.h:25
   Das_Op_Double_Data      : constant := 5;                      -- DAS.h:26
   Das_Op_Float_Data       : constant := 6;                      -- DAS.h:27
   Das_Op_Data             : constant := 6;                      -- DAS.h:28
   Das_Op_End_Data         : constant := 7;                      -- DAS.h:29
   Das_Op_Bye              : constant := 8;                      -- DAS.h:30
   Das_Op_Rtime            : constant := 9;                      -- DAS.h:31
   Das_Op_Header           : constant := 10;                     -- DAS.h:32
   Das_Op_Displaynames     : constant := 11;                     -- DAS.h:33
   Das_Op_Vartypes         : constant := 12;                     -- DAS.h:34
   Das_Double              : constant := 1;                      -- DAS.h:40
   Das_Float               : constant := 2;                      -- DAS.h:41
   Das_Integer             : constant := 3;                      -- DAS.h:42
   Das_Cache_Size_Bytes    : constant := 20000;                  -- DAS.h:48
   Das_Cache_Size_Words    : constant := 5000;                   -- DAS.h:49
   Agpdas_Cache_Size_Bytes : constant := 40000;                 -- DAS.h:55
   Agpdas_Cache_Size_Words : constant := 10000;                 -- DAS.h:56
   Hdr_Prologue_Size       : constant := 8;                     -- DAS.h:78
   Dui_Success             : constant := 8#0000#;               -- DAS.h:82
   Dui_More                : constant := 1;                     -- DAS.h:83
   Dui_End                 : constant := 2;                     -- DAS.h:84
   Dui_Bye                 : constant := -1;                    -- DAS.h:85
   Dui_Error               : constant := -2;                    -- DAS.h:86

   type Enum_Dastdatatype is (                                 -- DAS.h:71
      Das_Datatype_Default,                                   -- DAS.h:72
      Das_Datatype_Float,                                     -- DAS.h:73
      Das_Datatype_Double                                     -- DAS.h:75
     );
   for Enum_Dastdatatype'Size use 32;                          -- DAS.h:71
   subtype Dastdatatype is Enum_Dastdatatype;                  -- DAS.h:75

   type A_C_Ucharp_T is access all C.Ucharp;                   -- DAS.h:117
   type A_A_C_Ucharp_T is access all A_C_Ucharp_T;             -- DAS.h:117
   type A_C_A_Signed_Int_T is access all C.A_Signed_Int_T;     -- DAS.h:117

   type Union_Dastdataunion;                                   -- DAS.h:62

   type A_Dastdataunion_T is access all Union_Dastdataunion;   -- DAS.h:114
   type A_A_Dastdataunion_T_T is access all A_Dastdataunion_T; -- DAS.h:114

   type Union_Dastdataunion_Kind is (                          -- DAS.h:62
      L_Kind,
      F_Kind,
      D_Kind);

   type Union_Dastdataunion (Which : Union_Dastdataunion_Kind := D_Kind) is
   -- DAS.h:62
   record
      case Which is
         when L_Kind =>
            L : C.Signed_Int;                            -- DAS.h:63
         when F_Kind =>
            F : C.Float;                                 -- DAS.h:64
         when D_Kind =>
            D : Double;                                -- DAS.h:65
      end case;
   end record;

   pragma Convention (C, Union_Dastdataunion);
   pragma Unchecked_Union (Union_Dastdataunion);

   subtype Dastdataunion is Union_Dastdataunion;               -- DAS.h:66

   function Duiinit return C.Signed_Int;                       -- DAS.h:105

   function Duiconnectdasbyport
     (Hostname  : C.Ucharp;
      Dasname   : C.Ucharp;
      Port      : C.Signed_Int;
      Ismulti   : C.Signed_Int;
      Streamid  : C.Signed_Int;
      FrameRate : C.Signed_Int)
      return      C.Signed_Int; -- DAS.h:106

   function Duiopensendsocket
     (Hostname : C.Ucharp;
      Port     : C.Signed_Int)
      return     C.Signed_Int;   -- DAS.h:107

   function Duiconnectdas
     (Hostname  : C.Ucharp;
      Dasname   : C.Ucharp;
      Port      : C.A_Signed_Int_T;
      Ismulti   : C.Signed_Int;
      Streamid  : C.Signed_Int;
      FrameRate : C.Signed_Int)
      return      C.Signed_Int;       -- DAS.h:108

   function Duidisconnect (Fd : C.Signed_Int) return C.Signed_Int;-- DAS.h:109

   function Duiconnectfile (Filename : C.Ucharp) return C.Signed_Int;-- DAS.h:1
                                                                     --10

   function Duisetframerate
     (Fd        : C.Signed_Int;
      Framerate : C.Signed_Int)
      return      C.Signed_Int;    -- DAS.h:111

   function Duibytesinqueue (Fd : C.Signed_Int) return C.Signed_Int; -- DAS.h:1
                                                                     --12

   function Duicopybuf
     (Fd     : C.Signed_Int;
      Buf    : C.Ucharp;
      Nbytes : C.Signed_Int)
      return   C.Signed_Int;            -- DAS.h:113

   type U_Array is array (Positive range <>) of Dastdataunion;

   function Duigetdata
     (Fd        : C.Signed_Int;
      Buf       : access System.Address; --U_Array(1)'Address
      Precision : Dastdatatype)
      return      C.Signed_Int;         -- DAS.h:114

   function Duidecodedata
     (Fd        : C.Signed_Int;
      Buf       : A_A_Dastdataunion_T_T;
      Precision : Dastdatatype)
      return      C.Signed_Int;      -- DAS.h:115

   function Duiflushdataset (Fd : C.Signed_Int) return C.Signed_Int; -- DAS.h:1
                                                                     --16

   type Int_Array is array (Positive range <>) of aliased C.Signed_Int;
   package Ints is new P (Positive, C.Signed_Int, Int_Array, 0);

   type Str_Array is array (Positive range <>) of aliased C.Ucharp;
   package Strs is new P (
      Positive,
      C.Ucharp,
      Str_Array,
      Interfaces.C.Strings.Null_Ptr);

   --    function
   procedure Duigetheader
     (Fd          : C.Signed_Int;
      Version     : out C.Signed_Int; -- c.a_signed_int_t;
      Title       : out C.Ucharp;     -- a_c_ucharp_t;
      Comnum      : out C.Signed_Int; -- c.a_signed_int_t;
      Comments    : out Strs.Pointer; -- a_c_ucharp_t;
      Rdate       : out C.Ucharp;     -- a_c_ucharp_t;
      Rtime       : out C.Signed_Int; -- c.a_signed_int_t;
      Varnum      : out C.Signed_Int; -- c.a_signed_int_t;
      Vartypes    : out Ints.Pointer; -- a_c_a_signed_int_t;
      Namealiases : out Strs.Pointer; -- a_a_c_ucharp_t;
      Varnames    : out Strs.Pointer); -- a_a_c_ucharp_t)
   --                                       return c.signed_int;     --
   --DAS.h:117

   function Duidecodeheader
     (Fd          : C.Signed_Int;
      Version     : C.A_Signed_Int_T;
      Title       : A_C_Ucharp_T;
      Comnum      : C.A_Signed_Int_T;
      Comments    : A_A_C_Ucharp_T;
      Rdate       : A_C_Ucharp_T;
      Rtime       : C.A_Signed_Int_T;
      Varnum      : C.A_Signed_Int_T;
      Vartypes    : A_C_A_Signed_Int_T;
      Namealiases : A_A_C_Ucharp_T;
      Varnames    : A_A_C_Ucharp_T)
      return        C.Signed_Int;  -- DAS.h:118

   function Duiputheader
     (Fd          : C.Signed_Int;
      Title       : C.Ucharp;
      Numcomments : C.Signed_Int;
      Comments    : Str_Array;
      Rdate       : C.Ucharp;
      Rtime       : C.Signed_Int;
      Count       : C.Signed_Int;
      Vartypes    : Int_Array;
      Aliasnames  : Str_Array;
      Varnames    : Str_Array)
      return        C.Signed_Int;     -- DAS.h:119

   function Duiputdata
     (Fd         : C.Signed_Int;
      Data       : U_Array;
      Framecount : C.Signed_Int)
      return       C.Signed_Int;        -- DAS.h:120

   function Duienddataset (Fd : C.Signed_Int) return C.Signed_Int;-- DAS.h:121

   function Duiopenlogfile (Filename : C.Ucharp) return C.Signed_Int;-- DAS.h:1
                                                                     --22

   --
   -- This is an internal DAS_API call made visible to linker
   --
   Das_Send_Socket : constant := 0;
   Das_Recv_Socket : constant := 1;
   Das_Read_File   : constant := 2;
   Das_Write_File  : constant := 3;

   procedure Initdataset
     (Fd       : C.Signed_Int;
      Port     : Integer;
      Das_Mode : Integer);

   --
   -- Non-blocking file & socket options
   --
   subtype Fd_Mask is Interfaces.C.unsigned_long;

   type Fd_Mask_Vec_32 is array (Interfaces.C.int range 0 .. 31) of Fd_Mask;

   type Fd_Set is record
      Fds_Bits : Fd_Mask_Vec_32 := (others => 0);
   end record;

   type Timeval is record
      Tv_Sec  : Interfaces.C.unsigned_long := 0;  -- seconds
      Tv_Usec : Interfaces.C.unsigned_long := 0; -- and microseconds
   end record;

   function C_Select
     (Fd       : in Interfaces.C.int;
      Read     : access Fd_Set;
      Write    : access Fd_Set;
      Except   : access Fd_Set;
      Time_Val : access Timeval)
      return     C.Signed_Int;

   F_Setfl : constant := 4;
   O_Sync  : constant := 16;

   procedure C_Fcntl
     (Fd  : in Interfaces.C.int;
      Get : in Interfaces.C.int := F_Setfl;
      Set : in Interfaces.C.int := O_Sync);

private

   pragma Import (C, Duiinit, "DUIinit");                      -- DAS.h:105

   pragma Import (C, Duiconnectdasbyport, "DUIconnectDasByPort");-- DAS.h:106

   pragma Import (C, Duiopensendsocket, "DUIopenSendSocket");  -- DAS.h:107

   pragma Import (C, Duiconnectdas, "DUIconnectDas");          -- DAS.h:108

   pragma Import (C, Duidisconnect, "DUIdisconnect");          -- DAS.h:109

   pragma Import (C, Duiconnectfile, "DUIconnectFile");        -- DAS.h:110

   pragma Import (C, Duisetframerate, "DUIsetFrameRate");      -- DAS.h:111

   pragma Import (C, Duibytesinqueue, "DUIbytesInQueue");      -- DAS.h:112

   pragma Import (C, Duicopybuf, "DUIcopyBuf");                -- DAS.h:113

   pragma Import (C, Duigetdata, "DUIgetData");                -- DAS.h:114

   pragma Import (C, Duidecodedata, "DUIdecodeData");          -- DAS.h:115

   pragma Import (C, Duiflushdataset, "DUIflushDataset");      -- DAS.h:116

   pragma Import (C, Duigetheader, "DUIgetHeader");            -- DAS.h:117

   pragma Import (C, Duidecodeheader, "DUIdecodeHeader");      -- DAS.h:118

   pragma Import (C, Duiputheader, "DUIputHeader");            -- DAS.h:119

   pragma Import (C, Duiputdata, "DUIputData");                -- DAS.h:120

   pragma Import (C, Duienddataset, "DUIendDataSet");          -- DAS.h:121

   pragma Import (C, Duiopenlogfile, "DUIopenLogFile");        -- DAS.h:122

   pragma Import (C, Initdataset, "initDataSet");

   pragma Import (C, C_Select, "select");
   pragma Import (C, C_Fcntl, "fcntl");

   ----------------------------------------------------------------------------
   ----
   -- $version: 1 $
   -- $history: Common $
   -- $view: /prog/shared/modsim/ctd/ssom/ssom.ss/integ.wrk $
   ----------------------------------------------------------------------------
   ----

end C.Adi.Das;
