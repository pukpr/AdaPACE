------------------------------------------------------------------------
-- PDT/COMPANY:       Performance Management / Global Industrial Solutions
-- SYSTEM/Subsystem:  $view: /prog/shared/modsim/ctd/ssom/ssom.ss/integ.wrk $
-- FILE NAME:         $Id: ses.ads,v 1.6 2006/04/14 23:14:15 pukitepa Exp $
-- HISTORY:           $History: Common $
-- STATISTICS:  $Source_lines: 0 $  $Comment_Lines: 0 $   $Total_lines: 0 $
-- PURPOSE:           Simulation/Emulation/Stimulation Hierarchy
--                    Top-level contains class-utilty functions
-- LIMITATIONS:       Get_Line is only required for Apex environment.
--                    Text_IO is used elsewhere.
-- TASKS:             none
-- EXCEPTIONS RAISED: none
------------------------------------------------------------------------

package Ses is
   pragma Elaborate_Body;

   Output_Marker : constant String := "__ p4 __";
   -- String echoed when end of response reached (for Expect)

   procedure Os_Exit (Status : in Integer);  -- Convenience function
   pragma Import (C, Os_Exit, "exit");       -- 0 => OK, 1 => Error

end Ses;
