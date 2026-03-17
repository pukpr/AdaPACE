with Pace.Rule_Process;

package Ses.Kb is
   pragma Elaborate_Body;

   --
   -- P4 Knowledgebase
   --

   package Rules renames Pace.Rule_Process;

   Agent : Rules.Agent_Type (500_000);

-- $ID: ses-kb.ads,v 1.1 12/11/2002 23:06:02 pukitepa Exp $
end Ses.Kb;

