with Ses.Lib;
package body Ses.Kb is
begin
   Agent.Init (Ini_File => "",
               Console => False,
               Screen => Ses.Lib.Getenv ("SES_KB_DEBUG", "true") = "true",
               Ini => (Clause => 10000,
                       Hash => 17047,
                       In_Toks => 1500,
                       Out_Toks => 1500,
                       Frames => 14000,
                       Goals => 16000,
                       Subgoals => 1300,
                       Trail => 15000,
                       Control => 1800));

-- $ID: ses-kb.adb,v 1.1 12/11/2002 23:06:01 pukitepa Exp $   
end Ses.Kb;
