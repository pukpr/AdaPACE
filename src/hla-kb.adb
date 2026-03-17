with Gkb;
with Pace.Log;
with Interfaces.C.Strings;

package body Hla.KB is

   package K is new Gkb (
      Task_Stack_Size => 100_000,
      Prolog_File => Pace.Getenv ("FED_PRO", "/kbase/fed.pro"),
      Allocation_Data =>
     (Clause   => 10000,
      Hash     => 507,
      In_Toks  => 3000,
      Out_Toks => 1500,
      Frames   => 14000,
      Goals    => 16000,
      Subgoals => 1300,
      Trail    => 15000,
      Control  => 1700));

   function class_name (Tag_Name : String) return String is
      use K.Rules;
      V : Variables (1 .. 2);
   begin
      Pace.Log.Put_Line ("!!!!!!!!!!!!!!!!!!!!!!!! Don't call this function, use the no parameter version instead!");
      V (1) := +Q (Tag_Name);
      K.Agent.Query ("get_hla_class_name", V);
      return +V (2);
   exception
      when No_Match =>
         Pace.Log.Put_Line ("No match : " & Tag_Name);
         return "";
   end class_name;

   function int_name (Group, ID : Integer) return String is
      use K.Rules;
      V : Variables (1 .. 3);
   begin
      V (1) := +S (Group);
      V (2) := +S (ID);
      K.Agent.Query ("get_hla_int_name", V);
      return +V (3);
   exception
      when No_Match =>
         Pace.Log.Put_Line ("No match : " & Integer'Image (ID));
         return "";
   end int_name;

   function Obj_name (Group, ID : Integer) return String is
      use K.Rules;
      V : Variables (1 .. 3);
   begin
      V (1) := +S (Group);
      V (2) := +S (ID);
      K.Agent.Query ("get_hla_obj_name", V);
      return +V (3);
   exception
      when No_Match =>
         Pace.Log.Put_Line ("No match : " & Integer'Image (ID));
         return "";
   end Obj_name;

   function Obj_atts (Group, ID : Integer) return Integer is
      use K.Rules;
      V : Variables (1 .. 3);
   begin
      V (1) := +S (Group);
      V (2) := +S (ID);
      K.Agent.Query ("get_hla_obj_atts", V);
      return Integer'Value (+V (3));
   exception
      when No_Match =>
         Pace.Log.Put_Line ("No match : " & Integer'Image (ID));
         return 0;
   end Obj_atts;

   function att_name (Group, ID, Index : Integer) return String is
      use K.Rules;
      V : Variables (1 .. 4);
   begin
      V (1) := +S (Group);
      V (2) := +S (ID);
      V (3) := +S (Index);
      K.Agent.Query ("get_hla_att_name", V);
      return +V (4);
   exception
      when No_Match =>
         Pace.Log.Put_Line
           ("No match : " & Integer'Image (ID) & Integer'Image (Index));
         return "";
   end att_name;


   function Obj_mode (Group, ID : Integer) return Integer is
      use K.Rules;
      V : Variables (1 .. 3);
   begin
      V (1) := +S (Group);
      V (2) := +S (ID);
      K.Agent.Query ("get_hla_obj_mode", V);
      return Integer'Value (+V (3));
   exception
      when No_Match =>
         Pace.Log.Put_Line ("No match : " & Integer'Image (ID));
         return 0;
   end Obj_mode;

   function Int_mode (Group, ID : Integer) return Integer is
      use K.Rules;
      V : Variables (1 .. 3);
   begin
      V (1) := +S (Group);
      V (2) := +S (ID);
      K.Agent.Query ("get_hla_int_mode", V);
      return Integer'Value (+V (3));
   exception
      when No_Match =>
         Pace.Log.Put_Line ("No match : " & Integer'Image (ID));
         return 0;
   end Int_mode;

   use Interfaces.C.Strings;

--   function get_hla_int_name (Group, ID : Integer) return chars_ptr;
--   pragma Export (C, get_hla_int_name, "get_hla_int_name");
   function get_hla_int_name (Group, ID : Integer) return chars_ptr is
   begin
      return New_String (int_name (Group, ID));
   end get_hla_int_name;

--   function get_hla_obj_name (Group, ID : Integer) return chars_ptr;
--   pragma Export (C, get_hla_obj_name, "get_hla_obj_name");
   function get_hla_obj_name (Group, ID : Integer) return chars_ptr is
   begin
      return New_String (Obj_name (Group, ID));
   end get_hla_obj_name;

--   function get_hla_obj_atts (Group, ID : Integer) return Integer;
--   pragma Export (C, get_hla_obj_atts, "get_hla_obj_atts");
   function get_hla_obj_atts (Group, ID : Integer) return Integer is
   begin
      return Obj_atts (Group, ID);
   end get_hla_obj_atts;

--   function get_hla_att_name (Group, ID, Index : Integer) return chars_ptr;
--   pragma Export (C, get_hla_att_name, "get_hla_att_name");
   function get_hla_att_name (Group, ID, Index : Integer) return chars_ptr is
   begin
      return New_String (att_name (Group, ID, Index));
   end get_hla_att_name;

--   function get_hla_obj_mode (Group, ID : Integer) return Integer;
--   pragma Export (C, get_hla_obj_mode, "get_hla_obj_mode");
   function get_hla_obj_mode (Group, ID : Integer) return Integer is
   begin
      return Obj_mode (Group, ID);
   end get_hla_obj_mode;

--   function get_hla_int_mode (Group, ID : Integer) return Integer;
--   pragma Export (C, get_hla_int_mode, "get_hla_int_mode");
   function get_hla_int_mode (Group, ID : Integer) return Integer is
   begin
      return Int_mode (Group, ID);
   end get_hla_int_mode;


   function Startup_Gateway (Group : Integer) return Gateway is
      GW : Hla.Gateway;
   begin
      GW := Hla.Startup_Gateway (New_String (Pace.Getenv ("FED_PATH", "")),
                                 New_String (Pace.Getenv ("FEDERATE_NAME", "")),
                                 New_String (Pace.Getenv ("FEDERATION_NAME", "")),
                                 Group,
                                 Get_HLA_int_name'Access,
                                 Get_HLA_Obj_name'Access, 
                                 Get_HLA_Obj_atts'Access, 
                                 Get_HLA_att_name'Access, 
                                 Get_HLA_Int_mode'Access,
                                 Get_HLA_Obj_mode'Access 
                                 );

      return GW;
   end;

   function Startup_Gateway (RX, TX : Pace.Msg'Class;
                             Group : Integer := 0) return Boolean is
      GW : Hla.Gateway;
      RX_Obj : Pace.Msg'Class := RX;
      TX_Obj : Pace.Msg'Class := TX;
   begin
      GW := Startup_Gateway (Group);
      if GW = Hla.Null_Gateway then
         Pace.Log.Put_Line ("HLA gateway" & Group'Img & " NEVER started!!! Disabling HLA for execution.");
         return False;
      else
         Pace.Log.Put_Line ("done starting up gateway");
      end if;
      Pace.Log.Put_Line ("RX Task started!");
      Pace.Dispatching.Inout (Rx_Obj);
      Pace.Log.Put_Line ("TX Initialized !");
      Pace.Dispatching.Inout (Tx_Obj);
      return True;
   end;

end Hla.KB;
