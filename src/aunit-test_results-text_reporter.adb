------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--      A U N I T . T E S T _ R E S U L T S . T E X T _ R E P O R T E R     --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                            $Revision: 1.1 $
--                                                                          --
--                Copyright (C) 2000 Ada Core Technologies, Inc.            --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- GNAT is maintained by Ada Core Technologies Inc (http://www.gnat.com).   --
--                                                                          --
------------------------------------------------------------------------------
with Ada.Text_Io;
use Ada.Text_Io;
with Ada.Exceptions;
use Ada.Exceptions;
with Ada.Unchecked_Deallocation;
with Ada.Strings.Fixed;

with Aunit.Options;
use Aunit.Options;

--  Very simple reporter to console
package body Aunit.Test_Results.Text_Reporter is

   procedure Destroy is new Ada.Unchecked_Deallocation (String, String_Access);

   --  Report the contents of an error or failure list
   procedure Dump_Failure_List (L : in out Failure_Lists.List;
                                Is_Assertion : Boolean := True);

   --  List successful tests
   procedure Dump_Success_List (L : in out Success_Lists.List;
                                Is_Assertion : Boolean := True);

   --  Report the contents of an error or failure list
   procedure Dump_Failure_List (L : in out Failure_Lists.List;
                                Is_Assertion : Boolean := True) is
      Err_Rec : Test_Failure;
      use Failure_Lists;
   begin
      Start (L);
      while not Off (L) loop
         Err_Rec := Item (L);
         Put_Line ("======================================================================");
         if Is_Assertion then
            Put_Line ("FAIL: " & Err_Rec.Test_Name.all & "." & Err_Rec.Routine_Name.all);
         else
            Put_Line ("ERROR: " & Err_Rec.Test_Name.all & "." & Err_Rec.Routine_Name.all);
         end if;
         Put_Line ("----------------------------------------------------------------------");

         if not Is_Assertion then
            Put_Line ("      " & "**" &
                      Exception_Name (Err_Rec.E.all) & "** : ");
            Put ("         ");
         end if;

         Put_Line ("      " & Exception_Message (Err_Rec.E.all));
         New_Line;

         Destroy (Err_Rec.Routine_Name);
         Destroy (Err_Rec.Test_Name);
         Remove (L);
      end loop;
   end Dump_Failure_List;

   --  List successful tests
   procedure Dump_Success_List (L : in out Success_Lists.List;
                                Is_Assertion : Boolean := True) is
      Rec : Test_Success;
      use Success_Lists;
   begin
      Start (L);
      while not Off (L) loop
         Rec := Item (L);
         Put_Line ("      " & Rec.Test_Name.all & ": " & Rec.Routine_Name.all);

         Destroy (Rec.Routine_Name);
         Destroy (Rec.Test_Name);
         Remove (L);
      end loop;
   end Dump_Success_List;

   procedure Deallocate_Success_List (L : in out Success_Lists.List) is
      Rec : Test_Success;
      use Success_Lists;
   begin
      Start (L);
      while not Off (L) loop
         Rec := Item (L);
         Destroy (Rec.Routine_Name);
         Destroy (Rec.Test_Name);
         Remove (L);
      end loop;
   end Deallocate_Success_List;

   --  Report on a test run
   procedure Report (R : Result) is
      S : Success_Lists.List := Successes (R);
      F : Failure_Lists.List := Failures (R);
      E : Failure_Lists.List := Errors (R);
      use Ada.Strings.Fixed;
   begin

      if Verbose then
         Dump_Success_List (S);
      else
         Deallocate_Success_List (S);
      end if;

      Dump_Failure_List (F);
      Dump_Failure_List (E, False);
      Put_Line ("----------------------------------------------------------------------");
      Put_Line ("Ran" & Natural'Image (Test_Count (R)) & " tests");
      New_Line;
      if Test_Count (R) = Success_Count (R) then
         Put_Line ("OK");
      else
         Put_Line ("FAILED (failures=" & Trim (Natural'Image (Failure_Count (R)), Ada.Strings.Left) &
                   ", errors=" & Trim (Natural'Image (Error_Count (R)), Ada.Strings.Left) & ")");
      end if;

      if Elapsed (R) > 0.0 then
         New_Line;
         Put_Line ("Time: " & Duration'Image (Elapsed (R)) & " seconds");
      end if;
   end Report;

end Aunit.Test_Results.Text_Reporter;
