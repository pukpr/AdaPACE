with Ada.Command_Line;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Directories;

package body Pace.Command_Line is

   Nargs : constant Natural := Ada.Command_Line.Argument_Count;
   -- Dir_Sep : constant String := "\";
--   Backward : constant Boolean := Getenv ("ARCH", "Windows") = "Windows";
   
--    function Dir_Sep return String is
--    begin
--       if Backward then
--          return "\";
--       else
--          return "/";
--       end if;
--    end Dir_Sep;

   ----------------------------------------------------------------------------
   function Argument
              (Key : in String; Default : in String := "") return String is
   begin
      for I in 1 .. Nargs loop
         if Key = Ada.Command_Line.Argument (I) and then I < Nargs then
            return Ada.Command_Line.Argument (I + 1);
         end if;
      end loop;
      return Default;
   end Argument;
   ----------------------------------------------------------------------------
   function Argument (Key : in String; Default : in Float'Base)
                     return Float'Base is

      Arg : constant String := Argument (Key);
   begin
      if Arg /= "" then
         return Float'Value (Arg);
      else
         return Default;
      end if;
   end Argument;
   ----------------------------------------------------------------------------           
   function Argument (Key : in String; Default : in Integer) return Integer is

      Arg : constant String := Argument (Key);
   begin
      if Arg /= "" then
         return Integer'Value (Arg);
      else
         return Default;
      end if;
   end Argument;
   ----------------------------------------------------------------------------           
   function Has_Argument (Key : in String) return Boolean is
   begin
      for I in 1 .. Nargs loop
         if Key = Ada.Command_Line.Argument (I) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Argument;
   ----------------------------------------------------------------------------
   function Command_Name (Full_Path : in Boolean := True) return String is
      Name : constant String := Ada.Command_Line.Command_Name;
   begin
      if Full_Path then
         return Name;
      else
         return Ada.Directories.Simple_Name (Name);
--            Name (Ada.Strings.Fixed.Index (Source => Name,
--                                           Pattern => Dir_Sep,
--                                           Going => Ada.Strings.Backward) + 1 ..
--                    Name'Last);
      end if;
   end Command_Name;
   ----------------------------------------------------------------------------            
   function Total_Command_Line (Full_Path : in Boolean := True) return String is

      Cl : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String (Command_Name (Full_Path));
      use type Ada.Strings.Unbounded.Unbounded_String;
   begin
      for I in 1 .. Nargs loop
         Cl := Cl & " " & Ada.Strings.Unbounded.To_Unbounded_String
                            (Ada.Command_Line.Argument (I));
      end loop;
      return Ada.Strings.Unbounded.To_String (Cl);
   end Total_Command_Line;
   ----------------------------------------------------------------------------
   function Total_Args return String is
      Cl : Ada.Strings.Unbounded.Unbounded_String;
      use type Ada.Strings.Unbounded.Unbounded_String;
   begin
      for I in 1 .. Nargs loop
         Cl := Cl & " " & Ada.Strings.Unbounded.To_Unbounded_String
                            (Ada.Command_Line.Argument (I));
      end loop;
      return Ada.Strings.Unbounded.To_String (Cl);
   end Total_Args;
   ----------------------------------------------------------------------------
   function Path return String is
      S : constant String := Ada.Command_Line.Command_Name;
   begin
      -- Would like to use the following but it does not include the trailing path separator
      -- return Containing_Directory => Ada.Directories.Containing_Directory (S);
      return S(S'First..Ada.Strings.Fixed.Index (S, Ada.Directories.Simple_Name(S), Ada.Strings.Backward)-1);
   end Path;

-- $id: pace-command_line.adb,v 1.2 02/03/2003 17:17:43 pukitepa Exp $
end Pace.Command_Line;
