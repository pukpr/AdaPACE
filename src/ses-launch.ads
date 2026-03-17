with Ses.Lib;
with Ada.Strings.Unbounded;

package Ses.Launch is

   pragma Elaborate_Body;

   Max_Number_Of_Processes : constant Integer :=
     Integer'Value (Ses.Lib.Getenv ("P4MAX", "100"));

   procedure Load (Session_Config_File : in String;
                   Debug : in Boolean := False);

   procedure Remote_Exec (P : out Ses.Lib.Processes;
                          N : out Natural;
                          Common_Command_Args : in String := "";
                          Dummy_Launch : Boolean := False);

   function Table_Name (Pid : in Integer) return String;

   function Get_String return Ada.Strings.Unbounded.Unbounded_String;
   -- Returns Null_Unbounded_String if nothing available
   -- "" will return as " "

   procedure Console (Text : in String; Pid : in Integer := 0);

   procedure Set_Colors (Process : in Integer);
   
   -- When all is ready
   type Startup_Callback is access procedure;
   procedure Register_Startup_Callback (CB : in Startup_Callback);

   -- Inject on top of STDOUT
   procedure Post (Str : in String);

   -- $Id: ses-launch.ads,v 1.3 2006/04/03 14:56:02 pukitepa Exp $
end Ses.Launch;
