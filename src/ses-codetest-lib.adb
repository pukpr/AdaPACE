with Ses.Codetest.Symbols;
with Interfaces;
with Gnat.Regpat;
with Text_Io;
with Ada.Exceptions;
with Ses.Symbols;

package body Ses.Codetest.Lib is

   Match_Pattern : Ses.Lib.Re := Ses.Lib.Re_Pattern ("CT ([0-9]+) ([ -z]+)");

   function Peek_Image (Pid : in Ses.Lib.Pd;
                        Table : in Ses.Codetest.Idb.Index_Lookup;
                        Pipe_Mode : in Boolean := False) return String is
      Index : Integer;
      Seconds : Float;
      Result : Ses.Lib.Exp.Expect_Match;
      Match : Gnat.Regpat.Match_Array (0 .. 2);
   begin
      if Pipe_Mode then
         Ses.Lib.Exp.Expect
           (Pid.Descriptor.all, Result, Match_Pattern.all, Match,
            Timeout => -1);
         declare
            Text : constant String :=
              Ses.Lib.Exp.Expect_Out_Match (Pid.Descriptor.all);
            Int : constant String := Text (Match (1).First .. Match (1).Last);
            Name : constant String := Ses.Codetest.Idb.Get
                                        (Table, Integer'Value (Int));
         begin
            return Text (Match (2).First .. Match (2).Last) & " " & Name;
         end;
      else
         declare
            Timing : constant String :=
              Ses.Lib.Peek (Pid => Pid,
                            Symbol => Ses.Symbols.Get_Address
                                        (Pid => Ses.Lib.Get_Index
                                                  (Ses.Lib.Run_Id
                                                     (Pid.Descriptor.all)),
                                         Symval => "." & Ses.Codetest.
                                                           Symbols.Timing),
                            Timeout => 1000);
            Synchpoint : constant String :=
              Ses.Lib.Peek
                (Pid => Pid,
                 Symbol => Ses.Symbols.Get_Address
                             (Pid => Ses.Lib.Get_Index
                                       (Ses.Lib.Run_Id (Pid.Descriptor.all)),
                              Symval => "." & Ses.Codetest.Symbols.Synchpoint),
                 Timeout => 1000);
         begin
--           ses.lib.Echo ("timing=" & Timing & " synchpoint=" & Synchpoint);
            Ses.Codetest.Idb.Translate
              (Timing => Timing, Code_Index => Index, Seconds => Seconds);
            return Synchpoint & Float'Image (Seconds) & " ms " &
                     Ses.Codetest.Idb.Get (Table, Index);
         exception
            when others =>
               Ses.Lib.Echo (Timing);
               raise;
         end;
      end if;
   exception
      when Ses.Lib.Exp.Process_Died =>
         raise;
      when E: others =>
         return Ada.Exceptions.Exception_Information (E);
   end Peek_Image;

   function Peek_Image (P : in Ses.Lib.Processes;
                        T : in Tables;
                        Pipe_Mode : in Boolean := False) return String is
      Pc : Ses.Lib.Processes := P;
      Result : Ses.Lib.Exp.Expect_Match := 0;
      Match : Gnat.Regpat.Match_Array (0 .. 2);
      Pid : Integer := Integer'Last;
      function Recurse
                 (Text : in String; Pid, Max : in Integer) return String is
      begin
         if Pid = Max then
            return Text & Peek_Image (P (Pid), T (Pid).all, Pipe_Mode) &
                     Integer'Image (Pid);
         else
            return Text & Peek_Image (P (Pid), T (Pid).all, Pipe_Mode) &
                     Integer'Image (Pid) & Ascii.Lf &
                     Recurse (Text, Pid + 1, Max);
         end if;
      end Recurse;
      use type Ses.Lib.Exp.Expect_Match;
   begin
      if Pipe_Mode then
         for I in P'Range loop
            Pc (I).Regexp := Match_Pattern;
         end loop;
         Ses.Lib.Reset_Last_Process_Matched (0); 
         Ses.Lib.Exp.Expect (Result, Pc, Match, Timeout => -1);
         Pid := Ses.Lib.Last_Process_Matched;
         if Result < 0 then -- Ses.Lib.Exp.Expect_Full_Buffer
            return "No match Expect Error #" &
                     Ses.Lib.Exp.Expect_Match'Image (Result);
         elsif Pid < 0 then
            return "Invalid Pid";
         end if;
         if Pid = 0 then -- Callback not called, data left in buffer
            Pid := Integer (Result);
         end if;
         declare
            Text : constant String := Ses.Lib.Exp.Expect_Out_Match
                                        (Pc (Pid).Descriptor.all);
            Int : constant String := Text (Match (1).First .. Match (1).Last);
            Name : constant String := Ses.Codetest.Idb.Get
                                        (T (Pid).all, Integer'Value (Int));
         begin
            return Text (Match (2).First .. Match (2).Last) &
                     " " & Name & Integer'Image (Pid);
         end;
      else
         return Recurse ("", 1, P'Last);
      end if;
   exception
      when Ses.Lib.Exp.Process_Died =>
         raise;
      when E: others =>
         return Ada.Exceptions.Exception_Information (E) & " PID =" &
                  Integer'Image (Pid) & Ses.Lib.Exp.Expect_Match'Image (Result);
   end Peek_Image;

   procedure Poke_Scope (Pid : in Ses.Lib.Pd; Low, High : in Integer) is
   begin
      Ses.Lib.Poke (Pid, Ses.Symbols.Get_Address
                           (Pid => Ses.Lib.Get_Index
                                     (Ses.Lib.Run_Id (Pid.Descriptor.all)),
                            Symval => "." & Ses.Codetest.Symbols.Scope),
                    Ses.Codetest.Idb.Translate (Interfaces.Unsigned_16 (Low),
                                                Interfaces.Unsigned_16 (High)));
   end Poke_Scope;

end Ses.Codetest.Lib;
