------------------------------------------------------------------------
-- PDT/COMPANY:       Performance Management / Global Industrial Solutions
-- SYSTEM/Subsystem:  $view: /civilian_project/modsim/ctd_work/ssom/ssom.ss/integ.wrk $
-- FILE NAME:         $id: ses-codetest.ads,v 1.1 09/16/2002 18:18:59 pukitepa Exp $
-- HISTORY:           $History: Common $
-- STATISTICS:  $Source_lines: 0 $  $Comment_Lines: 0 $   $Total_lines: 0 $
-- PURPOSE:           Modified and renamed CodeTEST Ada95 Instrumenter library
--                    Places time stamps on instrumented code.
--                    Command-line arg Pipe_Mode turns on Stdout pipe
-- LIMITATIONS:       Best to use this with CodeTest generator, see body
-- TASKS:             none
-- EXCEPTIONS RAISED: Not allowed to raise any exceptions
------------------------------------------------------------------------
with Ada.Real_Time;
with Interfaces;

package Ses.Codetest is

   pragma Elaborate_Body; -- Initializes the absolute start time

   subtype Tag_Id is Interfaces.Unsigned_32;

   type Tag is private;

   -- functions: performance, SC, DC instrumenting
   -- write entry tag to control port, return exit tag
   function Etag (Entrytag, Exittag : Tag_Id) return Tag;

   -- functions for use with -tags-to-function
   procedure Ct_Tag (Control_Tag : Tag);
   procedure Ct_Tag (Control_Tag : Tag_Id);

   type Low_High is
      record
         Low : Interfaces.Unsigned_16;
         High : Interfaces.Unsigned_16;
      end record;
   for Low_High use -- Maps into a 32-bit area
      record
         Low at 0 range 0 .. 15;
         High at 2 range 0 .. 15;
      end record;
      for Low_High'Size use 32;

      Pipe_Mode : constant String := "CODETEST_PIPE";

private

   type Tag is
      record
         Start_Time : Ada.Real_Time.Time; -- procedure invocation time
         Entry_Tag : Tag_Id;              -- procedure code index
      end record;

   type Tag_Overlay is
      record
         Fraction : Interfaces.Unsigned_8; -- Time fraction
         Exponent : Interfaces.Integer_8;  -- Time exponent
         Address : Interfaces.Unsigned_16; -- Instrumented Codetest address
      end record;
   for Tag_Overlay use -- Maps into a 32-bit area
      record
         Fraction at 0 range 0 .. 7;
         Exponent at 1 range 0 .. 7;
         Address at 2 range 0 .. 15;
      end record;
   for Tag_Overlay'Size use 32;

   Scale : constant := 250.0; -- Scaling factor for mapping to a 8-bit fraction

   --
   -- SES PP (Peak/Poke) variables
   --
   Synchpoint : Float := 0.0;  -- Absolute time
   pragma Export (C, Synchpoint, "codetest__synchpoint");

   Timing : Integer := 0;      -- Contains procedure time + code index
   pragma Export (C, Timing, "codetest__timing");

   Scope : Low_High := (16#1#, 16#FFFF#); -- Range of indexes to store
   pragma Export (C, Scope, "codetest__scope");

   Verbose_Pipe : Boolean := False; -- Only Peek/Poke
   pragma Export (C, Verbose_Pipe, "codetest__verbose_pipe");

end Ses.Codetest;
