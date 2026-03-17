------------------------------------------------------------------------
-- PDT/COMPANY:         Performance Management / Global Industrial Solutions
-- SYSTEM/Subsystem:    $view: /civilian_project/modsim/ctd_work/ssom/ssom.ss/integ.wrk $
-- FILE NAME:           $id: ses-codetest.adb,v 1.1 09/16/2002 18:18:59 pukitepa Exp $
-- HISTORY:             $History: Common $
-- STATISTICS:  $Source_lines: 0 $  $Comment_Lines: 0 $  $Total_lines: 0 $
-- DESIGN NOTES:        CodeTEST Ada95 Instrumenter library body. You may have
--                      to customize this to match the target environment
-- IMPLEMENTATION NOTES:Lots of packing to get data to fit into 32-bit writes.
--                      Apex screws up on obtaining Start_Time, need to re-read
-- PORTABILITY ISSUES:  Designed for 32-bit atomic access machine
-- PERFORMANCE:         See below
------------------------------------------------------------------------
with Interfaces;
with Unchecked_Conversion;
with Ada.Command_Line;
with Text_Io;

package body Ses.Codetest is
   ----------------------------------------------------------------------------
   -- For reference to overhead due to Ada.Real_Time.Clock, go to URL:
   --  http://grouse/modsim/performance/guidelines/design/primitive-guide.html
   --    on LynxOS/PPC this was ~5 microsec
   --
   -- Timing is good to 0.4% due to storage of duration into 16-bit float
   --
   -- This is used with "ctai -tag-level=1 -tags-to-function -edit <module>"
   -- Typical use is (1) do a private checkout of <module>
   --                (2) run ctai on <module>, compile-link, run tests
   --                (3) abandon to revert to original <module>
   ----------------------------------------------------------------------------

   function To_Integer is new Unchecked_Conversion (Tag_Overlay, Integer);

   type Split_Data is
      record
         Identifier : Interfaces.Unsigned_16;
         Code_Index : Interfaces.Unsigned_16;
      end record;
   for Split_Data use -- Maps into a 32-bit area
      record
         Identifier at 0 range 0 .. 15;
         Code_Index at 2 range 0 .. 15;
      end record;
      for Split_Data'Size use 32;
      function To_Split_Data is new Unchecked_Conversion (Tag_Id, Split_Data);


      Start_Time : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      Null_Tag : constant Tag := (Start_Time, 0);

      -- functions: performance, SC, DC instrumenting
      -- write entry tag to code port, return exit tag
      function Etag (Entrytag, Exittag : Tag_Id) return Tag is
         Sd : constant Split_Data := To_Split_Data (Entrytag);
         use type Interfaces.Unsigned_16;
      begin
         if Sd.Code_Index >= Scope.Low and Sd.Code_Index <= Scope.High then
            declare
               use Ada.Real_Time;
               Time_Stamp : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
            begin
               return (Start_Time => Time_Stamp, Entry_Tag => Entrytag);
            exception
               when Constraint_Error => -- Apex hiccups on pragma Elaborate_Body?
                  Start_Time := Ada.Real_Time.Clock;
                  return (Start_Time => Time_Stamp, Entry_Tag => Entrytag);
            end;
         else
            return Null_Tag;
         end if;
      end Etag;

      protected Lock is
         procedure Echo (Str : in String);
      end Lock;
      protected body Lock is
         procedure Echo (Str : in String) is
         begin
            Text_Io.Put_Line (Str);
         end Echo;
      end Lock;

      function Thread_Id_Self return Integer;
      pragma Import (C, Thread_Id_Self, "pthread_self");

      -- For use with -tags-to-function.
      -- REPLACE THESE if using some other method to  record tags,
      -- such as SWINCKT or CodeTEST Native. See the example below.
      procedure Ct_Tag (Control_Tag : Tag) is
         Sd : constant Split_Data := To_Split_Data (Control_Tag.Entry_Tag);
         use type Interfaces.Unsigned_16;
      begin
         if Sd.Code_Index >= Scope.Low and Sd.Code_Index <= Scope.High then
            declare
               use Ada.Real_Time;
               Ts : constant Time_Span :=
                 (Clock - Control_Tag.Start_Time) * 1000; -- in milliseconds
               F : constant Float := Float (To_Duration (Ts));
               Data : constant Tag_Overlay :=
                 (Fraction => Interfaces.Unsigned_8 (Scale * Float'Fraction (F)),
                  Exponent => Interfaces.Integer_8 (Float'Exponent (F)),
                  Address => Sd.Code_Index);
            begin
               if Verbose_Pipe then
                  Lock.Echo ("CT" & Interfaces.Unsigned_16'Image (Sd.Code_Index) &
                             Duration'Image (To_Duration (Control_Tag.Start_Time -
                                                          Start_Time)) &
                             Duration'Image (To_Duration (Ts)) &
                             " ms TID#" & Integer'Image (Thread_Id_Self));
               end if;
               Synchpoint := Float (To_Duration
                                    (Control_Tag.Start_Time - Start_Time));
               Timing := To_Integer (Data);
            exception
               when Constraint_Error => -- Apex hiccups on pragma Elaborate_Body?
                  Start_Time := Ada.Real_Time.Clock;
            end;
         else
            null; -- don't compute
         end if;
      end Ct_Tag;

      procedure Ct_Tag (Control_Tag : Tag_Id) is
      begin
         null; -- Not used for anything, calls from exception handlers etc.
      end Ct_Tag;

begin
   Start_Time := Ada.Real_Time.Clock;
   for I in 1 .. Ada.Command_Line.Argument_Count loop
      if Ada.Command_Line.Argument (I) = Pipe_Mode then
         Verbose_Pipe := True;
      end if;
   end loop;
end Ses.Codetest;
