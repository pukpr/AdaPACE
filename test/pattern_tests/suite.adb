with Dispatch_Pattern_Test;
with Wmi_Pattern_Test;
with Data_Structures_Test;
with Utilities_Test;
with System_Io_Test;
with Memory_Xml_Test;
with AUnit.Test_Suites; use AUnit.Test_Suites;

package body Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Add_Test (Ret, new Dispatch_Pattern_Test.Test_Case);
      Add_Test (Ret, new Wmi_Pattern_Test.Test_Case);
      Add_Test (Ret, new Data_Structures_Test.Test_Case);
      Add_Test (Ret, new Utilities_Test.Test_Case);
      Add_Test (Ret, new System_Io_Test.Test_Case);
      Add_Test (Ret, new Memory_Xml_Test.Test_Case);
      return Ret;
   end Suite;

end Suite;
