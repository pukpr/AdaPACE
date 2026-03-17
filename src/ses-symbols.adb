with Ada.Characters.Handling;
with Ses.Kb;
with Ada.Strings.Unbounded;
with Ses.Lib;
with Ses.Launch;
with Text_Io;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Unbounded.Hash;

package body Ses.Symbols is

   use Ada.Strings.Unbounded;

   type Primitive_Type is (Int, Flt, Bool, Char, Uint, Double, Str);
   subtype Pid_Range is Integer range 1 .. Ses.Launch.Max_Number_Of_Processes;

   type Variable is
      record
         Name : Unbounded_String := Null_Unbounded_String;
         Memory : String (1 .. 12) := "16#00000000#";  -- 32-bit value
         Primitive : Primitive_Type := Uint;
         Pid : Integer := 0;
      end record;
   Empty : Variable;

   package DB is
      procedure Set (K : Unbounded_String; E : Variable);
      function Get (K : Unbounded_String) return Variable;
      package Iterator is
         procedure Reset;
         function Next return Variable;
         function Done return Boolean;
      end;
   end DB;

   package body DB is

      package Maps is new Ada.Containers.Indefinite_Hashed_Maps
           (Unbounded_String, Variable, Ada.Strings.Unbounded.Hash, "=");

      M : Maps.Map;

      procedure Set (K : Unbounded_String; E : Variable) is
      begin
         if Maps.Contains (M, K) then
            Maps.Replace (M, K, E);
         else
            Maps.Insert (M, K, E);
         end if;
      end Set;

      function Get (K : Unbounded_String) return Variable is
      begin
         if Maps.Contains (M, K) then
            return Maps.Element (M, K);
         else
            return Empty;
         end if;
      end Get;

      package body Iterator is
         C : Maps.Cursor;

         procedure Reset is
         begin
            C := Maps.First (M);
         end Reset;

         function Next return Variable is
            E : Variable;
         begin
            C := Maps.Next (C);
            if Done then
               E := Empty;
            else
               E := Maps.Element (C);
            end if;
            return E;
         end Next;

         function Done return Boolean is
         begin
            return not Maps.Has_Element (C);
         end Done;
      end;
   end DB;

   function Init return Integer is
      File : Text_Io.File_Type;
      use Ses.Kb.Rules;
      Exec : Unbounded_String;
   begin
      for Pid in Pid_Range loop
         Ses.Lib.Echo ("Processing " & Integer'Image (Pid));
         declare
            V : Variables (1 .. 5);
         begin
            V (1) := +S (Pid);
            Ses.Kb.Agent.Query ("proc", V);
            Exec := V (2);
            begin
               Text_Io.Open (File, Text_Io.In_File,
                             "." & To_String (Exec) & ".pp.in");
            exception
               when Text_Io.Name_Error =>
                  Text_Io.Open (File, Text_Io.In_File,
                                To_String (Exec) & ".pp.in");
            end;
            loop
               declare
                  Str : constant String := Ses.Lib.Get_Line (File);
                  Prim_String : constant String :=
                    Ses.Lib.Select_Field (Str, 1);
                  Addr_String : constant String :=
                    "16#" & Ses.Lib.Select_Field (Str, 2) & "#";
                  Sym_String : constant String :=
                    "." & Ses.Lib.Select_Field (Str, 3);
                  Var : constant Variable :=
                    (To_Unbounded_String (Sym_String), Addr_String,
                     Primitive_Type'Value (Prim_String), Pid);
               begin
                  Db.Set
                    (To_Unbounded_String (Sym_String & Integer'Image (Pid)),
                     Var);
               exception
                  when Constraint_Error =>
                     Ses.Lib.Echo ("!! ERROR in " &
                                   Text_Io.Name (File) & " @ " & Str);
               end;
            end loop;
         exception
            when Text_Io.End_Error =>
               Ses.Lib.Echo ("Processed " & Text_Io.Name (File));
               Text_Io.Close (File);
            when Text_Io.Name_Error =>
               Text_IO.Put_Line (Text_IO.Current_Error,
                   "Can't find symbol file for " & To_String (Exec));
            when No_Match =>
               return Pid - 1;
         end;
      end loop;
      return 0;
   end Init;


   function Get_Address (Pid : in Integer; Symval : in String) return String is
      Sym : constant String := Ses.Lib.Select_Field (Symval, 1);
      function Value return String is
      begin
         if Ses.Lib.Count_Fields (Symval) = 1 then
            return "";
         else
            return ":" & Ses.Lib.Select_Field (Symval, 2);
         end if;
      end Value;
      Var : Variable;
   begin
      if Symval = ".." or Symval = "." then
         return Symval;
      elsif Symval'Length > 0 then
         if Symval (Symval'First) >= '0' and Symval (Symval'First) <= '9' then
            return Symval;
         end if;
      end if;
      Var := Db.Get (To_Unbounded_String (Sym & Integer'Image (Pid)));
      if Var = Empty then
         return Symval;
      else
         return Var.Memory & " " &
                  Ada.Characters.Handling.To_Lower
                    (Primitive_Type'Image (Var.Primitive)) & Value;
      end if;
   end Get_Address;

   function Get_Symbol (Pid : in Integer; Addr : in String) return String is
      Var : Variable; -- := DB.Get (To_Unbounded_String(Key));
   begin
      Db.Iterator.Reset;
      while not Db.Iterator.Done loop
         Var := Db.Iterator.Next;
         if Addr = Var.Memory and Pid = Var.Pid then
            declare
               Name : constant String := To_String (Var.Name);
            begin
               return Name (Name'First + 1 .. Name'Last);
            end;
         end if;
      end loop;
      return Addr;
   end Get_Symbol;

end Ses.Symbols;

