with GNAT.Source_Info;
with Interfaces.C.Strings;

package Hla.KB is

   -- get_hla_class_name ("INTERACTIONROOT.NETWORKING.COMMUNICATION", N)?
   -- get_hla_class_name ("OBJECTROOT.GROUNDPLATFORM", N)?
   -- get_hla_int_name (1, N)?
   -- get_hla_obj_name (1, N)?
   -- get_hla_obj_atts (1, N)?
   -- get_hla_att_name (1, 1, N)?
   -- get_hla_att_name (1, 2, N)?

   -- Gets the "tag" name from the enclosing package;
   function class_name return String renames GNAT.Source_Info.Enclosing_Entity;
   
   -- Should not have to use this anymore
   -- function class_name (Tag_Name : String) return String;

--    function Int_Name (Group, ID : Integer) return String;
--    function Obj_Name (Group, ID : Integer) return String;
--    function Obj_Atts (Group, ID : Integer) return Integer;
--    function Att_Name (Group, ID, Index : Integer) return String;
--    function Obj_Mode (Group, ID : Integer) return Integer;
--    function Int_mode (Group, ID : Integer) return Integer;

   function get_hla_int_name (Group, ID : Integer) return Interfaces.C.Strings.chars_ptr;
   pragma Convention (C, get_hla_int_name);

   function get_hla_obj_name (Group, ID : Integer) return Interfaces.C.Strings.chars_ptr;
   pragma Convention (C, get_hla_obj_name);

   function get_hla_obj_atts (Group, ID : Integer) return Integer;
   pragma Convention (C, get_hla_obj_atts);

   function get_hla_att_name (Group, ID, Index : Integer) return Interfaces.C.Strings.chars_ptr;
   pragma Convention (C, get_hla_att_name);

   function get_hla_obj_mode (Group, ID : Integer) return Integer;
   pragma Convention (C, get_hla_obj_mode);

   function get_hla_int_mode (Group, ID : Integer) return Integer;
   pragma Convention (C, get_hla_int_mode);

   function Startup_Gateway (RX, TX : Pace.Msg'Class;
                             Group : Integer := 0) return Boolean;

   function Startup_Gateway (Group : Integer) return Gateway;

end Hla.KB;
