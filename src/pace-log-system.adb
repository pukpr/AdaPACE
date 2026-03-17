with Ada.Strings.Unbounded;
with Pace.Server;
with Pace.Server.Html;
with Pace.Server.Xml;
with Pace.Server.Dispatch;
with Str;
with Pace.Surrogates;
with Ada.Command_Line;
with GNAT.Directory_Operations;
with GNAT.Expect;
with GNAT.Os_Lib;
pragma Warnings (Off);
with System.Tasking.Debug;
pragma Warnings (On);
with Unchecked_Conversion;
with Ada.Task_Identification;
with Text_IO;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with GNAT.Compiler_Version;
with Pace.Strings;
with Pace.XML;

package body Pace.Log.System is

   use Pace.Strings;
   use Pace.Server.Xml;

   type Change_Time_Scale is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Change_Time_Scale);
   procedure Inout (Obj : in out Change_Time_Scale) is
   begin
      Pace.Log.Set_Time_Scale
        (Duration (Pace.Server.Keys.Value ("set", 1.0)));
      if Pace.Server.Dispatch.Dispatch_To_Action ("HAL.SMS.DVS") then
         -- Removed with on HAL.SMS so won't get linked unless desired
         null;
      end if;
      Pace.Log.Trace (Obj);
   end Inout;

   use Ada.Strings.Unbounded, Pace.Server.Html;

   type Environment is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Environment);
   for Environment'External_Tag use "ENVIRONMENT";

   package CVer is new GNAT.Compiler_Version;

   procedure Inout (Obj : in out Environment) is
      ID : constant String := Pace.Server.Keys.Value("id", "");
      Sorted_Actions : Str.Ustr_List.List;
      use Str.Ustr_List;

      Result :  Str.Us := S2U("");

      procedure Add (Name, Value : in String) is
      begin
         Append
              (Sorted_Actions,
               To_Unbounded_String (Row & Cell (Name) & Cell (Value)));
         -- non-sorted use this
         -- Pace.Server.Put_Data (Row & Cell (Key) & Cell (Val));
      end Add;

      procedure Find (Name, Value : in String) is
      begin
         if Name = ID then
            Result := S2U (Value);
         end if;
      end Find;

   begin
      if ID /= "" then
         Ada.Environment_Variables.Iterate (Find'Access);
         Pace.Server.Put_Data (Pace.Server.Xml.Item(ID, U2S(Result)));
      else
         Pace.Server.Put_Data (Header ("Environment Variables") & Paragraph);
         Pace.Server.Put_Data (CVer.Version & Paragraph);

         Pace.Server.Put_Data (Table (Border => True));
         Ada.Environment_Variables.Iterate (Add'Access);
         -- sort the list
         Str.Ustr_Sort.Sort (Sorted_Actions);
         declare
            I : Cursor := First (Sorted_Actions);
         begin
            while I /= No_Element loop
               Pace.Server.Put_Data (To_String (Element (I)));
               Next (I);
            end loop;
         end;
         Pace.Server.Put_Data (End_Table);
      end if;
   exception
      when E : others =>
         Pace.Error (Pace.X_Info (E));
   end Inout;

   type Arguments is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Arguments);
   for Arguments'External_Tag use "ARGUMENTS";

   procedure Inout (Obj : in out Arguments) is
   begin
      Pace.Server.Put_Data
        (Header ("Command Line Arguments") &
         Paragraph &
         GNAT.Directory_Operations.Get_Current_Dir &
         " .\" &
         Ada.Command_Line.Command_Name &
         Paragraph);
      Pace.Server.Put_Data (Table (Border => True));
      for I in  1 .. Ada.Command_Line.Argument_Count loop
         Pace.Server.Put_Data
           (Row &
            Cell (Integer'Image (I)) &
            Cell (Ada.Command_Line.Argument (I)));
      end loop;
      Pace.Server.Put_Data (End_Table);
   exception
      when E : others =>
         Pace.Error (Pace.X_Info (E));
   end Inout;

   type Quit_Program is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Quit_Program);
   for Quit_Program'External_Tag use "QUIT";

   type Quitter is new Pace.Msg with null record;
   procedure Input (Obj : in Quitter);

   Ready_To_Quit : Boolean := False;

   procedure Input (Obj : in Quitter) is
   begin
      Pace.Display ("Quitting program via action request...");
      Pace.Log.Os_Exit (0);
   end Input;

   procedure Inout (Obj : in out Quit_Program) is
      Msg : Quitter;
   begin
      -- A 2-Stage quitting process. This prevents accidental shutdowns
      -- and enables orderly shutdowns if required.
      if not Ready_To_Quit then
         Pace.Display ("Ready to quit...");
         Ready_To_Quit := True;
      else
         Pace.Server.Put_Data ("program has quit");
         -- Make this asynchronous so can return value to the browser
         Pace.Surrogates.Input (Msg);
      end if;
   end Inout;

   type Back_Trace is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Back_Trace);


   function Make_List (Opts : String;
                       List : GNAT.Os_Lib.String_List := (1..0 => null))
                       return GNAT.Os_Lib.String_List is
      I : Integer := Ada.Strings.Fixed.Index (Opts, " ");
      use GNAT.Os_Lib;
   begin
      --  This parses out all the spece-separated options into an array
      if Opts = "" or I = 0 then  --  reaches end
         return List & new String'(Opts);
      else --  recurse
         return Make_List (Opts (I + 1 .. Opts'Last),
                           List & new String' (Opts (Opts'First..I)));
      end if;
   end;

   Status : aliased Integer;

   procedure Inout (Obj : in out Back_Trace) is
      Exec      : constant String :=
         GNAT.Directory_Operations.Get_Current_Dir &
         "/" &
         Ada.Command_Line.Command_Name;
      Addr2Line : constant String :=
         Pace.Getenv ("ADDR2LINE", "/usr/bin/addr2line");

--       function Make_List (List : GNAT.Os_Lib.String_List;
--                           Opts : String) return GNAT.Os_Lib.String_List is
--          I : Integer := Ada.Strings.Fixed.Index (Opts, " ");
--          use GNAT.Os_Lib;
--       begin
--          --  This parses out all the spece-separated options into an array
--          if Opts = "" or I = 0 then
--             --  reaches end
--             return List;
--          else
--             --  recurse
--             return Make_List (List & new String' (Opts (Opts'First..I)),
--                               Opts (I + 1 .. Opts'Last));
--          end if;
--       end;

      use Pace.Server.Dispatch;
   begin
      -- Enter non-symbolic HEX addresses for back-trace, returns
      --fiLeName:lineNumbers
      Pace.Server.Put_Data (
        GNAT.Expect.Get_Command_Output (Addr2Line,
                                        Make_List (U2s (Obj.Set),
                                                   (new String' ("-e"),
                                                    new String' (exec))
                                                   ),
                                         "", Status'Access, True));
   end Inout;

   type Pause_Program is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Pause_Program);
   procedure Inout (Obj : in out Pause_Program) is
   begin
      Pace.Log.Pause_Resume;
      Pace.Server.Put_Data ("toggled pause of program");
   end Inout;

   type Is_Program_Paused is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Is_Program_Paused);
   procedure Inout (Obj : in out Is_Program_Paused) is
      State : Boolean;
   begin
      State := Pace.Log.Is_Paused;
      Obj.Set := S2u(Pace.Server.Xml.Item ("paused", Boolean'Image (State)));
      Pace.Server.Put_Data (U2s(Obj.Set));
   end Inout;

   type Tasking_Debug is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Tasking_Debug);
   procedure Inout (Obj : in out Tasking_Debug) is
      use Standard.System.Tasking;
      function To_Agent is new Unchecked_Conversion (Task_Id, Pace.Thread);
      function To_ID is new Unchecked_Conversion (Task_Id,
                                                  Ada.Task_Identification.Task_Id);
      Id : Task_Id;
      procedure Show (Name : in String) is
      begin
         Text_IO.Put (Text_IO.Standard_Error, Name);
         Text_IO.Put (Text_IO.Standard_Error, String'(1 .. 40-Name'Length => '.'));
      end;
      Kill : constant Boolean := Pace.Server.Keys.Value ("set", "") = "kill";
      Me : Ada.Task_Identification.Task_Id := Current;
      use type Ada.Task_Identification.Task_Id;
      procedure Output_Results;  -- Used for tracing stack during clean exit
      pragma Import (C, Output_Results, "__gnat_stack_usage_output_results");
   begin
      for I in Debug.Known_Tasks'Range loop
         Id := Debug.Known_Tasks (I);
         exit when Debug.Known_Tasks (I+1) = null; -- Next one is null -- danger!
         if Id /= null then
            begin
               Show (Get_Agent_Id (To_Agent (Id)));
               if Kill then
                  if Get_Agent_Id (To_Agent (Id)) = "main.procedure" or
                     -- Get_Agent_Id (To_Agent (Id)) = "unnamed.task" or
                     To_ID (Id) = Me then
                     null;
                  else
                     Ada.Task_Identification.Abort_Task (To_ID (Id));
                  end if;
               end if;
            exception
               when others =>
                  Show ("[terminated]");
            end;
            if Kill then
               Text_IO.Put_Line (Text_IO.Standard_Error, "killed!");
            else
               Debug.Print_Task_Info (Id);
            end if;
         end if;
      end loop;
      if Kill then
         Text_IO.Put_Line (Text_IO.Standard_Error, "All tasks except for main are dead.");
         Pace.Server.Send_Data ("Tasking Kill completed, Web server out of commision");
         delay 1.0;
         Output_Results;
         Ada.Task_Identification.Abort_Task (Me);
      else
         Pace.Server.Put_Data ("Tasking Debug completed");
      end if;
   exception
      when others =>
         Pace.Log.Put_Line ("No stack analysis, use '-bargs -u1000' if needed");
   end Inout;

   procedure Pause_Resume (Force_Resume : Boolean := False) is
   begin
      Pace.Log.Pause_Resume (Force_Resume);
   end Pause_Resume;

   function Is_Paused return Boolean is
   begin
      return Pace.Log.Is_Paused;
   end Is_Paused;


   use Pace.Server.Dispatch;
begin
   Save_Action (Change_Time_Scale'(Pace.Msg with Set => S2u ("1.0")));
   Save_Action
     (Environment'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action
     (Quit_Program'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action
     (Arguments'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action
     (Back_Trace'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action
     (Pause_Program'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action
     (Tasking_Debug'(Pace.Msg with Set => S2u ("kill")));
   Save_Action
     (Is_Program_Paused'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   -- $Id: pace-log-system.adb,v 1.17 2006/06/30 22:20:07 pukitepa Exp $
end Pace.Log.System;
