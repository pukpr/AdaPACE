package Pace.Command_Line is

   ---------------------------------------------------
   --  COMMAND_LINE
   ---------------------------------------------------
   pragma Elaborate_Body;

   -- Simplifies access on the command_line parameters 
   --  via key strings (options).

   -- All functions herein are case-sensitive for "key".

   function Argument (Key : in String; Default : in String := "") return String;

   -- Returns the argument on the command-line preceded by key if key is found,
   -- the empty string "" or Default otherwise.
   --
   -- Example: If the main is called like
   --
   -- main -file filename -number 10
   --
   -- then argument("-file") = "filename", argument(key => "-number") = "10",
   -- argument("-fil") = "".

   function Argument (Key : in String; Default : in Float'Base)
                     return Float'Base;

   function Argument (Key : in String; Default : in Integer) return Integer;

   -- If has_argument(key) then return the float'value / integer'value of the
   -- corresponding argument. If not has_argument(key) then return the default.                  

   function Has_Argument (Key : in String) return Boolean;

   -- Returns true if key is an argument an the command_line, false otherwise.

   function Command_Name (Full_Path : in Boolean := True) return String;

   -- Returns ada.command_line.command_name is full_path.
   -- Returns ada.command_line.command_name without path when not full_path.
   -- ada.command_line.command_name is the full name of the Main-unit.

   function Total_Command_Line (Full_Path : in Boolean := True) return String;
   function Total_Args return String;

   -- Returns the total command_line including command_name and all arguments
   -- separated by blanks. 

   function Path return String;
   
   -- Returns the path preceding the executable name, including '/'

-- $id: pace-command_line.ads,v 1.2 02/03/2003 17:17:46 pukitepa Exp $
end Pace.Command_Line;
