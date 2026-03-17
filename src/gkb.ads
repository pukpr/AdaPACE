with Pace.Rule_Process;
with Pace.Server.Dispatch;
with Ada.Containers.Indefinite_Vectors;

generic
   Prolog_File : String;
   Task_Stack_Size : Integer;
   Allocation_Data : Pace.Rule_Process.Allocation;
   Garbage_Collect_Time : Duration := 1000.0;  -- seconds interval between garbage collection
package Gkb is
   pragma Elaborate_Body;

   --
   -- Generic Knowledgebase
   --

   package Rules renames Pace.Rule_Process;

   Agent : Rules.Agent_Type (Task_Stack_Size);

   package Variables_Vector is new
     Ada.Containers.Indefinite_Vectors (Positive, Rules.Variables, Rules."=");

   -- you can pass in bound variables within Vars.
   -- if you don't need to pass in bound variables, just make sure
   -- that Vars is of the correct length, which is 1 greater than the
   -- length of the rule due to the generator adding an index!
   function Find_All (Rule : String;
                      Vars : Rules.Variables;
                      Start_Index : Integer := 1)
                      return Variables_Vector.Vector;

   type Query is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Query);

   type Assert_Xml is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Assert_Xml);

   type Consult_File is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Consult_File);

   -- starts garbage collection... if never called then garbage collection isn't done
   procedure Start_Collector;

   -- $Id: gkb.ads,v 1.4 2006/04/14 23:14:11 pukitepa Exp $

end Gkb;
