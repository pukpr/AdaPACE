with Gnat.Expect;
with Text_Io;

package Pace.Ses.Lib is

   pragma Elaborate_Body;

   package Exp renames Gnat.Expect;

   type Run_Id is new Exp.Process_Descriptor with private;
   function Get_Index (Pid : in Run_Id) return Integer;
   function Get_Name (Pid : in Run_Id) return String;

   subtype Pd is Exp.Multiprocess_Regexp;
   subtype Re is Exp.Pattern_Matcher_Access;
   subtype Processes is Exp.Multiprocess_Regexp_Array;

   function Localhost return String;
   function Default_Shell return String;

   function Run (Index : Integer;
                 Target, Dir, Exec, Match : in String;
                 Display : in String := Localhost;
                 Shell : in String := Default_Shell) return Pd;
   function Re_Pattern (Text : String) return Re;

   procedure Quit (Pid : in Pd);
   procedure Shutdown (P : in Processes);

   function Drawers_Ready
              return Integer; -- Negative number if all Pid's up, else Pid of last

   procedure Echo (Text : in String; New_Line : Boolean := True);

   -- Returns the indexed process that generated the expect output
   function Last_Process_Matched return Integer;
   procedure Reset_Last_Process_Matched (Value : Integer := 0);

private

   type String_Access is access String;

   type Run_Id is new Exp.Process_Descriptor with
      record
         Index : Integer;
         Name : String_Access;
      end record;

end Pace.Ses.Lib;
