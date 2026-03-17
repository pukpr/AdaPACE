with Gnat.Os_Lib;
with Text_IO;
with Gnat.Regpat;
with System;

package body Pace.Ses.Lib is
   use Gnat.Expect; 

   Num_Execs : Integer := 0;
   Up        : Integer := 0;

   Max_Number_Of_Processes : constant Integer :=
     Integer'Value (Getenv ("P4MAX", "100"));

   Rsh    : constant String := Getenv ("P4SHELL", "ssh");
   No_Env : constant String := Getenv ("P4NOENV", ""); -- set to -i to remove all env vars at startup

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
      Display                  : in String := Localhost;
      Shell                    : in String := Default_Shell)
      return                     Pd
   is
      Params : Gnat.Os_Lib.Argument_List (1 .. 2);
      Pid    : Pd := (new Run_Id,Re_Pattern (Match));

      Sh : constant String := "env " & No_Env & " DISPLAY=" & Display & " PATH=. ";
      Cd : constant String := "cd " & Dir & " && ";
      function Launching_Shell return String is
      begin
         if Shell = Default_Shell then
            return Rsh;
         else
            return Shell;
         end if;
      end;
   begin
      Run_Id (Pid.Descriptor.all).Index := Index;
      Run_Id (Pid.Descriptor.all).Name  := new String'(Exec);
      Up                                := 0;
      Params (1)                        := new String'(Target);
      Params (2)                        := new String'(Cd & Sh & Exec);

      Non_Blocking_Spawn
        (Pid.Descriptor.all,
         Launching_Shell,   -- This should be set up as the shell per app to enable Linux versus Windows
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


   procedure Quit (Pid : in Pd) is
      Clean_Exit : constant Boolean := Getenv ("_EXIT", "1") = "1";
   begin
      Send (Pid.Descriptor.all, ASCII.EOT & "");
      while Clean_Exit loop
         declare
            Result : Expect_Match;
            Match  : Gnat.Regpat.Match_Array (0 .. 1);
         begin
            Expect (Pid.Descriptor.all, Result, " ", Match, 1);
         exception
            when others =>
               Text_IO.Put_Line (Text_IO.Standard_Error, "Gracefully exited app {_EXIT=1}");
               return;
         end;
      end loop;
      -- Don't wait for app to respond that it has shut down, just close it
      Text_IO.Put_Line (Text_IO.Standard_Error, "Sending SIGTERM {_EXIT=0}");
      Send_Signal (Pid.Descriptor.all, 15);
      -- Hope that it will shut down eventually
   exception
      when others =>
         Close (Pid.Descriptor.all);
         Text_IO.Put_Line
           (Text_IO.Standard_Error,
            "Trying to quit process which is already dead?");
   end Quit;


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


   Host : constant String := Getenv ("HOST", "localhost");
   function Localhost return String is
   begin
      return Host;
   end Localhost;

   function Default_Shell return String is
   begin
      return "default";
   end Default_Shell;

   --------------------------------------------------------

   function Last_Process_Matched return Integer is
   begin
      return The_Last_Process_Matched;
   end;

   procedure Reset_Last_Process_Matched (Value : Integer := 0) is
   begin
      The_Last_Process_Matched := Value;
   end;

end Pace.Ses.Lib;
