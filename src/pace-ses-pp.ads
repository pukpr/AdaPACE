------------------------------------------------------------------------
-- PDT/COMPANY:       Performance Management / Global Industrial Solutions
-- SYSTEM/Subsystem:  $view: /prog/shared/modsim/ctd/sim.ss/work/int.wrk $
-- FILE NAME:         $id: ses-pp.ads,v 1.3 12/08/2003 14:42:56 pukitepa Exp $
-- HISTORY:           $History: Common $
-- STATISTICS:  $Source_lines: 0 $  $Comment_Lines: 0 $   $Total_lines: 0 $
-- PURPOSE:           Peak/Poke engine for White-Box SW Integration/Testing.
-- LIMITATIONS:       See body for range of types allowed
-- TASKS:             none
-- EXCEPTIONS RAISED: Text_IO.End_Error
------------------------------------------------------------------------
package Pace.Ses.Pp is
   pragma Elaborate_Body;

   --
   -- Parser: Character string input from stdin, string output to stdout
   --
   type Serial_Proc is access procedure (Text : in String; Quit : out Boolean);
   procedure Default (Text : in String; Quit : out Boolean);

   procedure Parser (Serial : Serial_Proc := Default'Access);
   -- Never returns if Default, raises Text_Io.End_Error if Ascii.EOT found
   --
   -- 16#<Addr># <Type>:<Val>    -- Means assign <Val> to <Addr> contents
   -- 16#<Addr># <Type>          -- Means get value from <Addr> contents
   -- (blank)                    -- Returns program executable name & time

   procedure Default_Task;

private

   function Raw_Parse (Addr, Cmd : in String) return String;

end Pace.Ses.Pp;
