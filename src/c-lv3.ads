with C;
with System;
-- with time;

package C.Lv3 is
   Flybox : constant := 1;                        -- lv3.h:32
   Beebox : constant := 2;                        -- lv3.h:33
   Cerealbox : constant := 3;                        -- lv3.h:34
   Cab : constant := 4;                        -- lv3.h:35
   Drivebox : constant := 5;                        -- lv3.h:36
   Fb_Noblock : constant := 1;                        -- lv3.h:38
   Fb_Block : constant := 2;                        -- lv3.h:39
   Aic1 : constant := 16#0001#;                 -- lv3.h:41
   Aic2 : constant := 16#0002#;                 -- lv3.h:42
   Aic3 : constant := 16#0004#;                 -- lv3.h:43
   Aic4 : constant := 16#0008#;                 -- lv3.h:44
   Aic5 : constant := 16#0010#;                 -- lv3.h:45
   Aic6 : constant := 16#0020#;                 -- lv3.h:46
   Aic7 : constant := 16#0040#;                 -- lv3.h:47
   Aic8 : constant := 16#0080#;                 -- lv3.h:48
   Aoc1 : constant := 16#0001#;                 -- lv3.h:50
   Aoc2 : constant := 16#0002#;                 -- lv3.h:51
   Aoc3 : constant := 16#0004#;                 -- lv3.h:52
   Dic1 : constant := 16#0010#;                 -- lv3.h:54
   Dic2 : constant := 16#0020#;                 -- lv3.h:55
   Dic3 : constant := 16#0040#;                 -- lv3.h:56
   Doc1 : constant := 16#0010#;                 -- lv3.h:58
   Doc2 : constant := 16#0020#;                 -- lv3.h:59
   Doc3 : constant := 16#0040#;                 -- lv3.h:60
   Baud576 : constant := 16#0070#;                 -- lv3.h:62
   Baud384 : constant := 16#0060#;                 -- lv3.h:63
   Baud192 : constant := 16#0050#;                 -- lv3.h:64
   Baud96 : constant := 16#0040#;                 -- lv3.h:65
   Baud48 : constant := 16#0030#;                 -- lv3.h:66
   Baud24 : constant := 16#0020#;                 -- lv3.h:67
   Baud12 : constant := 16#0010#;                 -- lv3.h:68
   Offset : constant := 16#0021#;                 -- lv3.h:70
   Burst : constant := 66;                       -- lv3.h:76
   Burst_Set : constant := 98;                       -- lv3.h:77
   Cont : constant := 99;                       -- lv3.h:78
   Default : constant := 100;                      -- lv3.h:79
   Packet : constant := 112;                      -- lv3.h:80
   Once : constant := 111;                      -- lv3.h:81
   Once_Cs : constant := 79;                       -- lv3.h:82
   Reset_Fb : constant := 114;                      -- lv3.h:83
   Reset_Fb_O : constant := 82;                       -- lv3.h:84
   Stop : constant := 83;                       -- lv3.h:85
   Setup : constant := 115;                      -- lv3.h:86
   Test1 : constant := 84;                       -- lv3.h:87
   Test2 : constant := 116;                      -- lv3.h:88
--    NSEC_PER_SEC        : constant := time.NSEC_PER_SEC;        -- /usr/include/time.h:99
--    CLOCKS_PER_SEC      : constant := time.CLOCKS_PER_SEC;      -- /usr/include/time.h:104


   -- imported subtypes from time
   type Time_T is new C.Signed_Int;                            -- /usr/include/time.h:64

   type Vector_Of_C_Unsigned_Char_T is                         -- lv3.h:28
     array (Integer range <>) of C.Unsigned_Char;

   type Vector_Of_C_Float_T is                                 -- lv3.h:122
     array (Integer range <>) of C.Float;
   pragma Convention (C, Vector_Of_C_Float_T); --APEX

   type Vector_Of_C_Signed_Int_T is                            -- lv3.h:123
     array (Integer range <>) of C.Signed_Int;
   pragma Convention (C, Vector_Of_C_Signed_Int_T); --APEX

   type Struct_Rs_Struct;                                      -- lv3.h:90
   type Struct_Revision;                                       -- lv3.h:100
   type Struct_Bglv_Struct;                                    -- lv3.h:112

   type Struct_Rs_Struct is                                    -- lv3.h:90
      record
         Wrt : C.Signed_Int;                               -- lv3.h:92
         Rd : C.Signed_Int;                               -- lv3.h:93
         Len : C.Signed_Int;                               -- lv3.h:94
         Nl : C.Signed_Int;                               -- lv3.h:95
         Cycles : C.Signed_Int;                               -- lv3.h:96
         Thou : C.Signed_Int;                               -- lv3.h:97
      end record;

   pragma Convention (C, Struct_Rs_Struct);                    -- lv3.h:90

   subtype Rs_Err is Struct_Rs_Struct;                         -- lv3.h:98

   type Struct_Revision is                                     -- lv3.h:100
      record
         Major : C.Signed_Int;                                -- lv3.h:102
         Minor : C.Signed_Int;                                -- lv3.h:103
         Bug : C.Signed_Int;                                -- lv3.h:104
         Alpha : C.Unsigned_Char;                             -- lv3.h:105
         Year : C.Signed_Int;                                -- lv3.h:106
      end record;

   pragma Convention (C, Struct_Revision);                     -- lv3.h:100

   subtype Revision is Struct_Revision;                        -- lv3.h:107

   type Struct_Bglv_Struct is                                  -- lv3.h:112
      record
         N_Analog_In : C.Signed_Int;                         -- lv3.h:114
         Analog_In : C.Signed_Int;                         -- lv3.h:115
         N_Dig_In : C.Signed_Int;                         -- lv3.h:116
         Dig_In : C.Signed_Int;                         -- lv3.h:117
         N_Analog_Out : C.Signed_Int;                         -- lv3.h:118
         Analog_Out : C.Signed_Int;                         -- lv3.h:119
         N_Dig_Out : C.Signed_Int;                         -- lv3.h:120
         Dig_Out : C.Signed_Int;                         -- lv3.h:121
         Ain : Vector_Of_C_Float_T (0 .. 7);            -- lv3.h:122
         Aout : Vector_Of_C_Signed_Int_T (0 .. 2);       -- lv3.h:123
         Din : Vector_Of_C_Signed_Int_T (0 .. 2);       -- lv3.h:124
         Dout : Vector_Of_C_Signed_Int_T (0 .. 2);       -- lv3.h:125
         Count : C.Signed_Int;                         -- lv3.h:126
         Str_Len : C.Signed_Int;                         -- lv3.h:127
         Baud : C.Signed_Int;                         -- lv3.h:128
         Mode : C.Ustring (0 .. 1);                      -- lv3.h:129
         Tag : Time_T;                          -- lv3.h:130
         Port : C.Signed_Int;                         -- lv3.h:131
         Box_Type : C.Signed_Int;                         -- lv3.h:132
         Sp_Fd : C.Signed_Int;                         -- lv3.h:133
         Rev : Revision;                             -- lv3.h:134
      end record;

   pragma Convention (C, Struct_Bglv_Struct);                  -- lv3.h:112

   subtype Bglv is Struct_Bglv_Struct;                         -- lv3.h:135


   procedure Setup_Lv;
   pragma Import (C, Setup_Lv, "setup_lv");

   procedure Get_Lv_Buffer (Buffer : out Bglv);
   pragma Import (C, Get_Lv_Buffer, "get_lv_buffer");

------------------------------------------------------------------------------
-- $version: 3 $
-- $history: Common $
-- $view: /prog/shared/modsim/ctd/ssom/ssom.ss/integ.wrk $
------------------------------------------------------------------------------

end C.Lv3;
