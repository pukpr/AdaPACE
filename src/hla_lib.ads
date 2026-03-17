with Hla;
with Interfaces.C.Strings;

package Hla_Lib is

   package C renames Interfaces.C;
   subtype C_Array is C.Char_Array (0 .. 99_999); -- matches C for buffer size

   type CB_Type is access procedure 
     (Name, Parameter : in Interfaces.C.Strings.Chars_Ptr;
      Data : in Interfaces.C.Char_Array;
      Length : in Interfaces.C.Size_T;
      Counter : in Long_Integer);
   pragma Convention (C, CB_Type);

   procedure Receive_Message (Handle : in Hla.Gateway;
                              CB : in CB_Type);
   pragma Export (C, Receive_Message, "Receive_Message");


   type Get_Tuple_CB is access procedure (Param, Data : out C_Array; 
                                          Length : out C.Size_T);
   pragma Convention (C, Get_Tuple_CB);

   procedure Send_Message (Name : in Interfaces.C.Strings.Chars_ptr;
                           Length : in Integer; 
                           Handle : Hla.Gateway;
                           Get_Tuple : in Get_Tuple_CB);
   pragma Export (C, Send_Message, "Send_Message");

   procedure Update_Attributes (Name : in Interfaces.C.Strings.Chars_ptr; 
                                Length : in Integer; 
                                Handle : in Hla.Gateway;
                                Get_Tuple : in Get_Tuple_CB);
   pragma Export (C, Update_Attributes, "Update_Attributes");
   
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
                             ) return Hla.Gateway;
   pragma Export (C, Startup_Gateway, "Startup_Gateway");

   function Federate_Handle (Handle : Hla.Gateway) return Integer;
   pragma Export (C, Federate_Handle, "Get_Federate_Handle");

   function Get_Phase return Interfaces.C.Strings.Chars_Ptr;
   pragma Export (C, Get_Phase, "Get_Phase");

   function Get_Phase_Time return Interfaces.C.Strings.Chars_Ptr;
   pragma Export (C, Get_Phase_Time, "Get_Phase_Time");
   
   procedure ExitGateway (Handle : Hla.Gateway;
                          Group : Integer);
   pragma Export (C, ExitGateway, "Exit_Gateway");


end Hla_Lib;
