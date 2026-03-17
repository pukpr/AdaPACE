package Pace.Ses.P4 is

   pragma Elaborate_Body;

   -- This package is a singleton because only one session can
   -- run per executable
   procedure Start_Session;
   procedure End_Session;

end Pace.Ses.P4;

