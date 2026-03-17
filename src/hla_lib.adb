with Pace.Log;
package body Hla_Lib is

   procedure Receive_Message (Handle : in Hla.Gateway;
                              CB : in CB_Type) is
   begin
      Pace.Log.Put_Line ("Receive_Message");
   end;


   procedure Send_Message (Name : in Interfaces.C.Strings.Chars_ptr;
                           Length : in Integer; 
                           Handle : Hla.Gateway;
                           Get_Tuple : in Get_Tuple_CB) is
   begin
      Pace.Log.Put_Line ("Send_Message, length =" & Length'Img);
   end;

   procedure Update_Attributes (Name : in Interfaces.C.Strings.Chars_ptr; 
                                Length : in Integer; 
                                Handle : in Hla.Gateway;
                                Get_Tuple : in Get_Tuple_CB) is
   begin
      Pace.Log.Put_Line ("Pub_Message, length =" & Length'Img);
   end;   
   
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
                             ) return Hla.Gateway is
   begin
      Pace.Log.Put_Line ("Fake Startup_Gateway, Group =" & Group'Img);
      return Hla.Null_Gateway;
   end;

   function Federate_Handle (Handle : Hla.Gateway) return Integer is
   begin
      Pace.Log.Put_Line ("Federate_Handle");
      return 0;
   end;

   function Get_Phase return Interfaces.C.Strings.Chars_Ptr is
   begin
      Pace.Log.Put_Line ("Get_Phase");
      return Interfaces.C.Strings.Null_Ptr;
   end;

   function Get_Phase_Time return Interfaces.C.Strings.Chars_Ptr is
   begin
      Pace.Log.Put_Line ("Get_Phase_Time");
      return Interfaces.C.Strings.Null_Ptr;
   end;
   
   procedure ExitGateway (Handle : Hla.Gateway;
                          Group : Integer) is
   begin
      Pace.Log.Put_Line ("Exit_Gateway" & Group'Img);
   end;


end Hla_Lib;
