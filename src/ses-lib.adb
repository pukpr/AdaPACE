with Gnat.Os_Lib;
with Text_IO;
with Gnat.Regpat;
with Ada.Command_Line;
with System;

package body Ses.Lib is
   use Gnat.Expect, Gnat.Os_Lib;

   Num_Execs : Integer := 0;
   Up        : Integer := 0;

   function Getenv (Name : in String; Default : in String) return String is
      Str : constant String := Gnat.Os_Lib.Getenv (Name).all;
   begin
      if Str = "" then
         return Default;
      else
         return Str;
      end if;
   end Getenv;

   Max_Number_Of_Processes : constant Integer :=
     Integer'Value (Getenv ("P4MAX", "100"));

   Rsh    : constant String := Ses.Lib.Getenv ("P4SHELL", "ssh");
   No_Env : constant String := Ses.Lib.Getenv ("P4NOENV", ""); -- set to -i

   function Re_Pattern (Text : String) return Re is
      use Gnat.Regpat;
   begin
      return new Pattern_Matcher'(Compile (Text));
   end Re_Pattern;

   function Get_Index (Pid : in Run_Id) return Integer is
   begin
      return Pid.Index;
   end Get_Index;

   function Get_Name (Pid : in Run_Id) return String is
   begin
      return Pid.Name.all;
   end Get_Name;

   Map_Process_ID : array (Integer range 1 .. Max_Number_Of_Processes) 
      of Exp.Process_ID := (others => 0);

   The_Last_Process_Matched : Integer;
   
   procedure Output_Filter 
      (Descriptor : Process_Descriptor'Class;
       Str        : String;
       User_Data  : System.Address) is
      Pid : Exp.Process_ID := Get_Pid (Descriptor);
   begin
      for I in Map_Process_ID'Range loop
         if Map_Process_ID (I) = Pid then
            The_Last_Process_Matched := I;
            exit;
         end if;
      end loop;
      -- This should never happen as one of the processes has to match.
      -- If a process dies, we will no longer receive output
   end;

   function Run
     (Index                    : Integer;
      Target, Dir, Exec, Match : in String;
      Display                  : in String := Localhost)
      return                     Pd
   is
      Params : Argument_List (1 .. 2);
      Pid    : Pd := (new Run_Id,Re_Pattern (Match));

      Sh : constant String :=
         "env " & No_Env & " DISPLAY=" & Display & " PATH=. ";
      Cd : constant String := "cd '" & Dir & "';";
   begin
      Run_Id (Pid.Descriptor.all).Index := Index;
      Run_Id (Pid.Descriptor.all).Name  := new String'(Exec);
      Up                                := 0;
      Params (1)                        := new String'(Target);
      Params (2)                        :=
        new String'("(" & Cd & Sh & Exec & ")");

      Non_Blocking_Spawn
        (Pid.Descriptor.all,
         Rsh,
         Params,
         Err_To_Out  => True,
         Buffer_Size => 50_000);
      Num_Execs := Num_Execs + 1;

      -- We must determine which indexed process gets printed out as
      -- the output is tracked. The only way to do this is via a 
      -- filter called-back whenever expect is ready to dump output
      Map_Process_ID (Index) := Get_Pid (Pid.Descriptor.all);
      Add_Filter (Pid.Descriptor.all, Output_Filter'Access, Output);
      return Pid;
   end Run;

   function Peek
     (Pid     : Pd;
      Symbol  : String;
      Timeout : Integer := -1)
      return    String
   is
      Match  : Gnat.Regpat.Match_Array (0 .. 1);
      Result : Expect_Match;
   begin

      Send (Pid.Descriptor.all, Symbol);
      Expect
        (Pid.Descriptor.all,
         Result,
         Select_Field (Symbol, 1) & " = ([ -z]+)",
         Match,
         Timeout);
      if Result = Expect_Timeout then
         return "error: Peek/Timeout => " & Symbol;
      else
         declare
            Value : constant String :=
               Expect_Out (Pid.Descriptor.all) (
               Match (1).First .. Match (1).Last);
         begin
            Expect
              (Pid.Descriptor.all,
               Result,
               Ses.Output_Marker,
               Match,
               Timeout);
            return Value;
         end;
      end if;
   end Peek;

   procedure Poke
     (Pid     : in Pd;
      Symbol  : in String;
      Value   : in String;
      Timeout : Integer := -1)
   is
      Match  : Gnat.Regpat.Match_Array (0 .. 1);
      Result : Expect_Match;
   begin
      Send (Pid.Descriptor.all, Symbol & ":" & Value);
      Expect (Pid.Descriptor.all, Result, Ses.Output_Marker, Match, Timeout);
      if Result = Expect_Timeout then
         Echo ("error: Poke/Expect_Timeout");
      end if;
   end Poke;

   procedure Quit (Pid : in Pd) is
      Clean_Exit : constant Boolean := Getenv ("_EXIT", "0") = "1";
   begin
      Send (Pid.Descriptor.all, ASCII.EOT & "");
      loop
         exit when not Clean_Exit;
         declare
            Result : Expect_Match;
            Match  : Gnat.Regpat.Match_Array (0 .. 1);
         begin
            Expect (Pid.Descriptor.all, Result, " ", Match, 1);
         exception
            when others =>
               Text_IO.Put_Line (Text_IO.Standard_Error, "Terminated");
               return;
         end;
      end loop;
   exception
      when others =>
         Close (Pid.Descriptor.all);
         Text_IO.Put_Line
           (Text_IO.Standard_Error,
            "Trying to quit process which is already dead?");
   end Quit;

   function Drawers_Ready return Boolean is
   begin
      Up := Up + 1;
      return Up = Num_Execs;
   end Drawers_Ready;

   function Drawers_Ready return Integer is
   begin
      Up := Up + 1;
      if Up = Num_Execs then
         Num_Execs := 0;
         return -Last_Process_Matched;
      else
         return Last_Process_Matched;
      end if;
   end Drawers_Ready;

   procedure Shutdown (P : in Processes) is
   begin
      for I in  P'Range loop
         Quit (P (I));
      end loop;
      --      for I in P'Range loop
      --         Text_Io.Put_Line ("Closing");
      --         Close (P(I).Descriptor.all);
      --         Text_Io.Put_Line ("Closed");
      --      end loop;
   end Shutdown;

   procedure Echo (Text : in String; New_Line : Boolean := True) is
   begin
      if New_Line then
         Text_IO.Put_Line (Text);
      else
         Text_IO.Put (Text);
         Text_IO.Flush;
      end if;
   exception
      when Text_IO.Device_Error =>
         if New_Line then
            Text_IO.Put_Line (Text_IO.Standard_Error, Text);
         else
            Text_IO.Put (Text_IO.Standard_Error, Text);
            Text_IO.Flush (Text_IO.Standard_Error);
         end if;
   end Echo;

   Nargs : constant Natural := Ada.Command_Line.Argument_Count;

   function Argument (Name : in String; Default : in String) return String is
   begin
      for I in  1 .. Nargs loop
         if Name = Ada.Command_Line.Argument (I) and then I < Nargs then
            return Ada.Command_Line.Argument (I + 1);
         end if;
      end loop;
      return Default;
   end Argument;

   function Argument (Name : in String) return Boolean is
   begin
      for I in  1 .. Nargs loop
         if Name = Ada.Command_Line.Argument (I) then
            return True;
         end if;
      end loop;
      return False;
   end Argument;

   Host : constant String := Getenv ("HOST", "localhost");
   function Localhost return String is
   begin
      return Host;
   end Localhost;

   function Get_Line (File : Text_IO.File_Type) return String 
      renames Text_IO.Get_Line; -- Ada 2005

   --------------------------------------------------------

   function Count_Fields (Item : String) return Natural is
      Count : Positive;
   begin
      if Item'Length = 0 then
         return 0;
      else
         Count := 1;
         for I in  Item'Range loop
            if Item (I) = ' ' then
               Count := Count + 1;
            end if;
         end loop;
      end if;
      return Count;
   end Count_Fields;

   function Select_Field (Item : String; Field_No : Integer) return String is
      First : constant Integer := Item'First;
      Last  : constant Integer := Item'Last;

      Start  : Natural;
      Finish : Natural;

      procedure Search_Forwards
        (Start    : in out Natural;
         Finish   : in out Natural;
         Field_No : in Positive)
      is

         Field : Natural := 0;
         procedure Skip_Space (Ptr : in out Positive) is
         begin
            while Ptr <= Last and then Item (Ptr) = ' ' loop
               Ptr := Ptr + 1;
            end loop;
         end Skip_Space;

         procedure Skip_Non_Space (Ptr : in out Positive) is
         begin
            while Ptr <= Last and then Item (Ptr) /= ' ' loop
               Ptr := Ptr + 1;
            end loop;
         end Skip_Non_Space;

      begin
         loop
            Skip_Space (Start);
            Field := Field + 1;
            exit when Start > Last or else Field = Field_No;
            Skip_Non_Space (Start);
         end loop;

         Finish := Start;
         Skip_Non_Space (Finish);
         -- Finish will point one beyond the end, or at the end of
         -- the list. (how can we tell!)
         Finish := Finish - 1;

      end Search_Forwards;

   begin

      if Field_No > 0 then
         Start  := First;
         Finish := First;
         Search_Forwards (Start, Finish, Field_No);
      else
         raise Constraint_Error;
      end if;

      --  Make a subtype conversion to a string with diff.
      --  bounds. Forces the 'first to be 1, which makes life
      --  simipler for the caller

      declare
         subtype Slide is String (1 .. Finish - Start + 1);
      begin
         return Slide (Item (Start .. Finish));
      end;

   end Select_Field;

   function Last_Process_Matched return Integer is
   begin
      return The_Last_Process_Matched;
   end;

   procedure Reset_Last_Process_Matched (Value : Integer := 0) is
   begin
      The_Last_Process_Matched := Value;
   end;

end Ses.Lib;
