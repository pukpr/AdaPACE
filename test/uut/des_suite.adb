with Aunit.Test_Suites;
use Aunit.Test_Suites;

--  List of tests and suites to compose:
with Uut.Basic_Delay_Ordering;
with Uut.Exception_Handling;
with Uut.Time_Precision;
--with Uut.Select_Terminate;

function Des_Suite return Access_Test_Suite is
   Result : Access_Test_Suite := new Test_Suite;
begin
   --  You may add multiple tests or suites here:
   Add_Test (Result, new Uut.Basic_Delay_Ordering.Test_Case);
   Add_Test (Result, new Uut.Exception_Handling.Test_Case);
   Add_Test (Result, new Uut.Time_Precision.Test_Case);
   --Add_Test (Result, new Uut.Select_Terminate.Test_Case);
   return Result;
end Des_Suite;


