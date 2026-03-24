with Pace.Log;
with Pace.Config;
with Pace.Server;
with Pace.Server.Dispatch;
with Pace.Server.Kbase_Utilities;
with Pace.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ual.Utilities;

package body Gkb is

   function Id is new Pace.Log.Unit_Id;

   use Pace.Strings;

   package Asu renames Ada.Strings.Unbounded;

   -- the garbage collection agent
   task Gc_Agent is
      entry Start;
   end Gc_Agent;
   task body Gc_Agent is
      use Rules;
      V : Variables (1 .. 0);
   begin
      Pace.Log.Agent_Id (Id);

      accept Start;

      loop
         Pace.Log.Wait (Garbage_Collect_Time);
         Agent.Query ("gc", V);
      end loop;

   exception
      when E : No_Match =>
         Pace.Log.Put_Line ("garbage collection stopped");
      when E: others =>
         Pace.Log.Ex (E);
   end Gc_Agent;

   function Find_All (Rule : String;
                      Vars : Rules.Variables;
                      Start_Index : Integer := 1)
                      return Variables_Vector.Vector is
      use Rules;
      Done : Boolean := False;
      I : Integer := Start_Index;
      Result : Variables_Vector.Vector;
   begin
      while not Done loop
         declare
            V : Variables := Vars;
         begin
            V (1) := Asu.To_Unbounded_String (Pace.Strings.Trim (I));
            Agent.Query (Rule, V);
            Variables_Vector.Append (Result, V);
            I := I + 1;
         exception
            when E : Rules.No_Match =>
               Done := True;
         end;
      end loop;
      return Result;
   end Find_All;

   procedure Start_Collector is
   begin
      Gc_Agent.Start;
   end Start_Collector;

   procedure Load (File : in String) is
      use Rules;
   begin
      Agent.Assert (F ("kbase_path", Q (Pace.Config.Find_File ("/kbase/"))));
      Agent.Load (File);
   exception
      when No_Match =>
         Pace.Log.Put_Line ("GKB File Not Loaded " & File);
   end Load;

   procedure Inout (Obj : in out Query) is
   begin
      Pace.Server.Kbase_Utilities.Query_Kbase (Agent, Obj.Set);
   end Inout;

   procedure Inout (Obj : in out Assert_Xml) is
   begin
      Pace.Server.Kbase_Utilities.Xml_To_Kbase
        (Agent, Obj.Set, Pace.Server.Keys.Value ("functor", "xml"));
   end Inout;

   use Pace.Server.Dispatch;

   procedure Inout (Obj : in out Consult_File) is
      Rel_File : String := Ual.Utilities.Search_Xml (U2s (Obj.Set), "file");
      Kb_File : String := Pace.Config.Find_File (Rel_File);
      Query : Asu.Unbounded_String;
   begin
      if Kb_File /= "" then
         Query := Asu.To_Unbounded_String ("consult(" & '"' & Kb_File & '"' & ")");
         Pace.Server.Kbase_Utilities.Query_Kbase (Agent, Query);
      else
         Pace.Log.Put_Line ("File " & Rel_File & " not found!  Consult failed.");
      end if;
   end Inout;

   procedure Find_And_Load (File_Relative_To_Pace : String) is
      Path_To_File : String := Pace.Config.Find_File (File_Relative_To_Pace);
   begin
      if Path_To_File /= "" then
         Load (Path_To_File);
      else
         Pace.Log.Put_Line ("GKB: Could not find " & File_Relative_To_Pace & " in PACE");
      end if;
   end Find_And_Load;

   procedure Load_Kbase_Files is
      File : String := Pace.Config.Find_File (Prolog_File);
   begin
      -- Initial File Load
      if File = "" then
         Pace.Log.Put_Line ("!!!!!!!!!!!!!!! Couldn't find the vkb file " & Prolog_File);
         Pace.Log.Os_Exit (0);
      else
         Load (File);
      end if;
      declare
         use Variables_Vector;
         V : Rules.Variables (1 .. 2);
         Vec : Vector := Find_All ("load_file", V);
         Iter : Cursor := Variables_Vector.First(Vec);
      begin
         while Has_Element (Iter) loop
            V := Element (Iter);
            Find_And_Load ("/kbase/" & (U2s (V (2))));
            Next (Iter);
         end loop;
      end;
   end Load_Kbase_Files;

begin
   Agent.Init (Ini_File => "",
               Console => False,
               Screen => Pace.Getenv ("GKB_DEBUG", 0) = 1,
               Ini => Allocation_Data);
   Load_Kbase_Files;

   Save_Action (Query'(Pace.Msg with S2u ("listing")));
   Save_Action (Assert_Xml'(Pace.Msg with S2u ("<x><a>1</a></x>")));
   Save_Action (Consult_File'(Pace.Msg with S2u ("xml")));

exception
   when E : others =>
      Pace.Log.Ex (E);
end Gkb;
