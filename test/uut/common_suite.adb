with Aunit.Test_Suites;
use Aunit.Test_Suites;

--  List of tests and suites to compose:
with Uut.Pace_Xml;
with Uut.Gnu_Xml_Tree;
with Uut.Ual_Probability;
with Uut.Pace_Jobs;
with Uut.Hal_Velocity_Plots;
with Uut.Hal_Rotations;
with Uut.Pace_Notify_Release;
with Uut.Pbm_Parabolic_Motion;
with Uut.Hal_Generic_Sms;
with Uut.Pubs;
with Des_Suite;

function Common_Suite return Access_Test_Suite is
   Result : Access_Test_Suite := new Test_Suite;
begin
   --  You may add multiple tests or suites here:
   Add_Test (Result, new Uut.Pace_Xml.Test_Case);
   Add_Test (Result, new Uut.Pace_Notify_Release.Test_Case);
   Add_Test (Result, new Uut.Hal_Rotations.Test_Case);
   Add_Test (Result, new Uut.Hal_Velocity_Plots.Test_Case);
   Add_Test (Result, new Uut.Pace_Jobs.Test_Case);
   Add_Test (Result, new Uut.Gnu_Xml_Tree.Test_Case);
   Add_Test (Result, new Uut.Ual_Probability.Test_Case);
   Add_Test (Result, new Uut.Pbm_Parabolic_Motion.Test_Case);
   Add_Test (Result, new Uut.Hal_Generic_Sms.Test_Case);
   Add_Test (Result, Des_Suite);
   Add_Test (Result, new Uut.Pubs.Test_Case);
   return Result;
end Common_Suite;


